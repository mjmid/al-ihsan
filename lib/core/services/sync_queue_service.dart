/// ---------------------------------------------------------------------------
/// sync_queue_service.dart
/// ---------------------------------------------------------------------------
/// Implements the offline-first sync queue — the heart of the architecture.
///
/// When the device is offline (or when a GAS call fails transiently), write
/// operations are serialised into [SyncOperation] objects and stored in an
/// in-memory queue managed by [SyncQueueNotifier].
///
/// When connectivity returns (or after any successful foreground action),
/// [SyncQueueNotifier.processQueue] drains the queue one operation at a time,
/// with configurable retry logic and inter-request delays to stay within
/// Google Apps Script rate limits.
///
/// Architecture overview:
///   Repositories → enqueue(op) → SyncQueueNotifier (Riverpod StateNotifier)
///                                      ↓  processQueue()
///                                  ApiService  →  GAS Web-App
/// ---------------------------------------------------------------------------

import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../constants/app_constants.dart';
import 'api_service.dart';
import 'supabase_client.dart';

// ─── SYNC OPERATION MODEL ────────────────────────────────────────────────────

/// Represents a single pending write operation that must be replicated to GAS.
///
/// Fields are intentionally kept flat (no nested enums) so that the object
/// can be trivially serialised to JSON if persistence is needed in a future
/// version (e.g. writing the queue to a Hive box for crash-safe queuing).
class SyncOperation {
  /// Universally unique identifier for this operation (UUID v4).
  final String id;

  /// Target Google Sheet tab.
  /// One of: `'Books'` | `'Users'` | `'Transactions'`
  final String sheet;

  /// GAS action to perform.
  /// One of: `'upsert'` | `'delete'`
  final String action;

  /// The record (or partial record) to write.
  /// For `'delete'` operations this typically contains only the primary key.
  final Map<String, dynamic> payload;

  /// Wall-clock time when this operation was created locally.
  final DateTime createdAt;

  /// Number of failed dispatch attempts so far.
  /// Mutable because the queue mutates it in-place on failure.
  int retryCount;

  SyncOperation({
    required this.id,
    required this.sheet,
    required this.action,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
  });

  /// Convenience factory that auto-assigns a UUID and `createdAt` timestamp.
  factory SyncOperation.create({
    required String sheet,
    required String action,
    required Map<String, dynamic> payload,
  }) {
    return SyncOperation(
      id: const Uuid().v4(),
      sheet: sheet,
      action: action,
      payload: payload,
      createdAt: DateTime.now(),
    );
  }

  /// Returns a copy with [retryCount] incremented by 1.
  SyncOperation copyWithIncrementedRetry() => SyncOperation(
        id: id,
        sheet: sheet,
        action: action,
        payload: payload,
        createdAt: createdAt,
        retryCount: retryCount + 1,
      );

  @override
  String toString() => 'SyncOperation(id: $id, sheet: $sheet, action: $action, '
      'retries: $retryCount, payload: $payload)';
}

// ─── STATE NOTIFIER ──────────────────────────────────────────────────────────

/// Riverpod [StateNotifier] that owns and manages the in-memory sync queue.
///
/// The exposed state is `List<SyncOperation>` — a snapshot of the pending
/// operations. UI widgets can watch this to show a "pending sync" badge.
class SyncQueueNotifier extends StateNotifier<List<SyncOperation>> {
  // ---------------------------------------------------------------------------
  // Construction
  // ---------------------------------------------------------------------------

  SyncQueueNotifier() : super(const []);

  // ---------------------------------------------------------------------------
  // Internal state
  // ---------------------------------------------------------------------------

  /// Guard flag — prevents [processQueue] from being re-entered while a
  /// previous call is still in progress.
  bool _isProcessing = false;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Adds [op] to the tail of the queue.
  ///
  /// **Deduplication** — if another operation for the *same sheet* and the
  /// *same primary key* already exists in the queue, the newer operation wins:
  /// the old one is replaced.  The primary key is resolved as follows:
  ///
  ///   • Books        → `accession_no`
  ///   • Users        → `user_id`
  ///   • Transactions → `trx_id`
  ///
  /// This prevents the queue from growing unboundedly when the same record is
  /// edited multiple times offline before a sync.
  void enqueue(SyncOperation op) {
    final primaryKey = _primaryKeyFor(op.sheet);
    final newKeyValue = op.payload[primaryKey];

    // If we found a duplicate, remove the old entry before adding the new one.
    List<SyncOperation> updated = List<SyncOperation>.from(state);

    if (newKeyValue != null) {
      updated.removeWhere((existing) {
        if (existing.sheet != op.sheet) return false;
        return existing.payload[primaryKey] == newKeyValue;
      });
    }

    updated.add(op);
    state = updated;

    _debugLog('Enqueued: $op | Queue length: ${state.length}');

    // Automatically trigger processing when an item is added
    processQueue(ApiService.instance);
  }

  /// Drains the queue by dispatching each operation to [api] sequentially.
  ///
  /// Behaviour:
  ///  1. Acquires the [_isProcessing] lock; returns immediately if already
  ///     held (prevents concurrent runs triggered by rapid connectivity events).
  ///  2. Iterates the queue snapshot from head to tail.
  ///  3. On success: removes the operation from the live state.
  ///  4. On failure: increments [SyncOperation.retryCount].
  ///     If retries ≥ [kMaxRetryAttempts], the operation is permanently
  ///     discarded (logged as an error).
  ///  5. Waits [kSyncQueueRetryDelaySeconds] between each dispatch to honour
  ///     GAS's ~30 requests/minute per-user quota.
  /// Drains the queue by dispatching operations to Supabase.
  Future<void> processQueue([ApiService? api]) async {
    if (_isProcessing) {
      _debugLog('processQueue called while already processing — skipping.');
      return;
    }

    if (state.isEmpty) {
      return;
    }

    _isProcessing = true;
    _debugLog('Starting queue processing. Pending: ${state.length}');

    try {
      final snapshot = List<SyncOperation>.from(state);
      final List<String> successfullyPushedIds = [];

      for (final op in snapshot) {
        final tableName = op.sheet.toLowerCase();
        try {
          if (op.action == 'upsert') {
            final mapped = _mapToSupabasePayload(op.sheet, op.payload);
            await supabaseClient.from(tableName).upsert(mapped);
          } else if (op.action == 'delete') {
            final pk = _primaryKeyFor(op.sheet);
            final id = op.payload[pk]?.toString() ?? '';
            if (id.isNotEmpty) {
              await supabaseClient
                  .from(tableName)
                  .delete()
                  .eq(pk, id);
            }
          }
          successfullyPushedIds.add(op.id);
          _debugLog('Pushed op ${op.id} to Supabase ($tableName)');
        } catch (e) {
          _debugLog('Failed to push op ${op.id} to Supabase: $e');
          // Increment retry count
          op.retryCount++;
          // Network or server error — break loop to avoid pounding server while offline
          break;
        }
      }

      if (successfullyPushedIds.isNotEmpty) {
        final pushedSet = successfullyPushedIds.toSet();
        state = [
          for (final op in state)
            if (!pushedSet.contains(op.id)) op
        ];
        _debugLog(
            'Queue updated. Cleared ${pushedSet.length} ops. Remaining: ${state.length}');
      }
    } catch (e) {
      _debugLog('Error processing queue: $e');
    } finally {
      _isProcessing = false;
      _debugLog('Queue processing finished. Remaining: ${state.length}');
    }
  }

  /// Maps local payload to clean Supabase schema columns
  Map<String, dynamic> _mapToSupabasePayload(
      String sheet, Map<String, dynamic> p) {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    switch (sheet.toLowerCase()) {
      case 'books':
        return {
          'accession_no': p['accession_no']?.toString().trim() ?? '',
          'book_name': p['book_name']?.toString().trim() ?? '',
          'volume_no': (p['volume_no']?.toString().trim().isEmpty ?? true)
              ? null
              : p['volume_no']?.toString().trim(),
          'author': (p['author']?.toString().trim().isEmpty ?? true)
              ? null
              : p['author']?.toString().trim(),
          'translator': (p['translator']?.toString().trim().isEmpty ?? true)
              ? null
              : p['translator']?.toString().trim(),
          'publisher': (p['publisher']?.toString().trim().isEmpty ?? true)
              ? null
              : p['publisher']?.toString().trim(),
          'address': (p['address']?.toString().trim().isEmpty ?? true)
              ? null
              : p['address']?.toString().trim(),
          'subject_category':
              (p['subject_category']?.toString().trim().isEmpty ?? true)
                  ? null
                  : p['subject_category']?.toString().trim(),
          'shelf_no': (p['shelf_no']?.toString().trim().isEmpty ?? true)
              ? null
              : p['shelf_no']?.toString().trim(),
          'remarks': (p['remarks']?.toString().trim().isEmpty ?? true)
              ? null
              : p['remarks']?.toString().trim(),
          'status': (p['status']?.toString().trim().isEmpty ?? true)
              ? 'Available'
              : p['status']?.toString().trim(),
          'last_updated': nowIso,
        };
      case 'users':
        return {
          'user_id': p['user_id']?.toString().trim() ?? '',
          'name': p['name']?.toString().trim() ?? '',
          'phone': (p['phone']?.toString().trim().isEmpty ?? true)
              ? null
              : p['phone']?.toString().trim(),
          'pin': (p['pin']?.toString().trim().isEmpty ?? true)
              ? null
              : p['pin']?.toString().trim(),
          'type': p['type']?.toString().trim() ?? 'Student',
          'class_jamat': (p['class_jamat']?.toString().trim().isEmpty ?? true)
              ? null
              : p['class_jamat']?.toString().trim(),
          'status': (p['status']?.toString().trim().isEmpty ?? true)
              ? 'Active'
              : p['status']?.toString().trim(),
          'last_updated': nowIso,
        };
      case 'transactions':
        return {
          'trx_id': p['trx_id']?.toString().trim() ?? '',
          'accession_no': p['accession_no']?.toString().trim() ?? '',
          'user_id': p['user_id']?.toString().trim() ?? '',
          'issue_date': _parseTimestamp(p['issue_date']) ?? nowIso,
          'expected_return': _parseTimestamp(p['expected_return']),
          'actual_return': _parseTimestamp(p['actual_return']),
          'status': (p['status']?.toString().trim().isEmpty ?? true)
              ? 'Active'
              : p['status']?.toString().trim(),
          'last_updated': nowIso,
        };
      case 'assets':
        return {
          'asset_id': p['asset_id']?.toString().trim() ?? '',
          'name': p['name']?.toString().trim() ?? '',
          'category': (p['category']?.toString().trim().isEmpty ?? true)
              ? null
              : p['category']?.toString().trim(),
          'quantity': int.tryParse(p['quantity']?.toString() ?? '1') ?? 1,
          'unit': (p['unit']?.toString().trim().isEmpty ?? true)
              ? 'টি'
              : p['unit']?.toString().trim(),
          'location': (p['location']?.toString().trim().isEmpty ?? true)
              ? null
              : p['location']?.toString().trim(),
          'condition': p['condition']?.toString().trim() ?? 'good',
          'acquisition_type':
              p['acquisition_type']?.toString().trim() ?? 'purchased',
          'donor_or_source':
              (p['donor_or_source']?.toString().trim().isEmpty ?? true)
                  ? null
                  : p['donor_or_source']?.toString().trim(),
          'cost': double.tryParse(p['cost']?.toString() ?? '') ?? 0.0,
          'purchase_date': _parseTimestamp(p['purchase_date']),
          'remarks': (p['remarks']?.toString().trim().isEmpty ?? true)
              ? null
              : p['remarks']?.toString().trim(),
          'last_updated': nowIso,
        };
      default:
        return Map<String, dynamic>.from(p);
    }
  }

  String? _parseTimestamp(dynamic val) {
    if (val == null) return null;
    final str = val.toString().trim();
    if (str.isEmpty) return null;
    try {
      return DateTime.parse(str).toUtc().toIso8601String();
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Helper to extract the primary key value from an operation's payload.
  String _primaryKeyValue(SyncOperation op) {
    final pk = _primaryKeyFor(op.sheet);
    return op.payload[pk]?.toString() ?? '';
  }

  /// Returns the primary key field name (in payload) for the given [sheet].
  String _primaryKeyFor(String sheet) {
    switch (sheet.toLowerCase()) {
      case 'books':
        return 'accession_no';
      case 'users':
        return 'user_id';
      case 'transactions':
        return 'trx_id';
      case 'assets':
        return 'asset_id';
      default:
        // Fallback — we won't deduplicate unknown sheets.
        return 'id';
    }
  }

  /// Writes a debug-only log line prefixed with the class name.
  void _debugLog(String message) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[SyncQueueNotifier] $message');
    }
  }
}

// ─── RIVERPOD PROVIDER ───────────────────────────────────────────────────────

/// Global provider for the sync queue.
///
/// Repositories obtain the notifier via:
/// ```dart
/// ref.read(syncQueueProvider.notifier).enqueue(op);
/// ```
///
/// UI widgets watch the queue length for a "pending changes" badge via:
/// ```dart
/// final pendingCount = ref.watch(syncQueueProvider).length;
/// ```
final syncQueueProvider =
    StateNotifierProvider<SyncQueueNotifier, List<SyncOperation>>(
  (_) => SyncQueueNotifier(),
  name: 'syncQueueProvider',
);
