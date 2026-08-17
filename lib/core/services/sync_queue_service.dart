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
  Future<void> processQueue(ApiService api) async {
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

      // Convert SyncOperations to GAS format
      final changes = snapshot.map((op) {
        // Map local sheet names to expected GAS table names
        String gasTable;
        if (op.sheet == 'Books')
          gasTable = 'Books';
        else if (op.sheet == 'Users')
          gasTable = 'Users';
        else if (op.sheet == 'Transactions')
          gasTable = 'Transactions';
        else
          gasTable = op.sheet;

        // Map local operation to GAS operation
        String gasOp = 'UPDATE';
        if (op.action == 'upsert')
          gasOp = 'UPDATE'; // GAS handles both insert and update
        else if (op.action == 'delete') gasOp = 'DELETE';

        // Map local columns to GAS generic columns
        final mappedPayload = <String, dynamic>{};
        if (gasTable == 'Books') {
          mappedPayload['id'] = op.payload['accession_no'];
          if (op.action == 'upsert') {
            mappedPayload['accession_no'] = op.payload['accession_no'];
            mappedPayload['book_name'] = op.payload['book_name'];
            mappedPayload['volume_no'] = op.payload['volume_no'];
            mappedPayload['author'] = op.payload['author'];
            mappedPayload['translator'] = op.payload['translator'];
            mappedPayload['publisher'] = op.payload['publisher'];
            mappedPayload['address'] = op.payload['address'];
            mappedPayload['subject_category'] = op.payload['subject_category'];
            mappedPayload['shelf_no'] = op.payload['shelf_no'];
            mappedPayload['remarks'] = op.payload['remarks'];
            mappedPayload['status'] = op.payload['status'];
            mappedPayload['last_updated'] = op.payload['last_updated'];
          }
        } else if (gasTable == 'Users') {
          mappedPayload['user_id'] = op.payload['user_id'];
          if (op.action == 'upsert') {
            mappedPayload['name'] = op.payload['name'];
            mappedPayload['phone'] = op.payload['phone'];
            mappedPayload['pin'] = op.payload['pin'];
            mappedPayload['type'] = op.payload['type'];
            mappedPayload['class_jamat'] = op.payload['class_jamat'];
            mappedPayload['status'] = op.payload['status'];
            mappedPayload['last_updated'] = op.payload['last_updated'];
          }
        } else if (gasTable == 'Transactions') {
          mappedPayload['trx_id'] = op.payload['trx_id'];
          if (op.action == 'upsert') {
            mappedPayload['accession_no'] = op.payload['accession_no'];
            mappedPayload['user_id'] = op.payload['user_id'];
            mappedPayload['issue_date'] = op.payload['issue_date'];
            mappedPayload['expected_return'] = op.payload['expected_return'];
            mappedPayload['actual_return'] = op.payload['actual_return'];
            mappedPayload['status'] = op.payload['status'];
            mappedPayload['last_updated'] = op.payload['last_updated'];
          }
        }

        return {
          'table': gasTable,
          'operation': gasOp,
          'data': mappedPayload,
        };
      }).toList();

      // Push all changes in a single API call
      final result = await api.push(changes);

      if (result.isSuccess) {
        _debugLog(
            'Batch push successful — clearing ${snapshot.length} operations from queue.');
        // Remove all successfully pushed operations from the queue
        final pushedIds = snapshot.map((op) => op.id).toSet();
        state = [
          for (final op in state)
            if (!pushedIds.contains(op.id)) op
        ];
      } else {
        _debugLog('Batch push failed: ${result.error}');
        // Increment retry counts for all operations in the snapshot
        state = [
          for (final op in state)
            if (snapshot.any((s) => s.id == op.id))
              if (op.retryCount + 1 < kMaxRetryAttempts)
                op.copyWithIncrementedRetry()
              else
                // Drop operations that exceeded max retries
                null
        ].whereType<SyncOperation>().toList();
      }
    } catch (e) {
      _debugLog('Error processing queue: $e');
    } finally {
      _isProcessing = false;
      _debugLog('Queue processing finished. Remaining: ${state.length}');
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
