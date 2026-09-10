/// ---------------------------------------------------------------------------
/// sync_service.dart
/// ---------------------------------------------------------------------------
/// Orchestrates bi-directional data synchronisation between the local SQLite
/// database and the remote Google Apps Script (GAS) Web-App.
///
/// Two sync paths are supported:
///
///   1. **Delta sync** (`syncAll` / `_syncSheet`)
///      Fetches only rows changed since the last successful sync.
///      Called on app resume, after background reconnection, etc.
///
///   2. **Initial / paginated sync** (`performInitialSync`)
///      Used on first install (or after a local DB wipe) to pull all rows
///      in [kPageSize]-row pages with a progress callback for a loading bar.
///
/// Column name mapping:
///   Remote (PascalCase) → Local (snake_case) is handled by [_remoteToLocal].
/// ---------------------------------------------------------------------------
library;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../database/database_helper.dart';
import 'api_service.dart';
import 'package:supabase/supabase.dart';
import 'supabase_client.dart';
import 'sync_queue_service.dart';

// ─── SYNC RESULT ─────────────────────────────────────────────────────────────

/// Outcome of a [SyncService.syncAll] or [SyncService.performInitialSync] run.
class SyncResult {
  /// `true` when every sheet synced without errors.
  final bool isSuccess;

  /// `true` when the device had no internet at the start of the sync.
  final bool isOffline;

  /// Total number of rows written to the local database during this run.
  final int totalSynced;

  /// Per-sheet error messages (empty on full success or offline).
  final Map<String, String> errors;

  const SyncResult._({
    required this.isSuccess,
    required this.isOffline,
    required this.totalSynced,
    required this.errors,
  });

  /// Device was offline — sync was skipped entirely.
  factory SyncResult.offline() => const SyncResult._(
        isSuccess: false,
        isOffline: true,
        totalSynced: 0,
        errors: {},
      );

  /// All sheets synced successfully.
  factory SyncResult.success(int totalSynced) => SyncResult._(
        isSuccess: true,
        isOffline: false,
        totalSynced: totalSynced,
        errors: const {},
      );

  /// At least one sheet failed, but others may have succeeded.
  factory SyncResult.partialFailure({
    required int totalSynced,
    required Map<String, String> errors,
  }) =>
      SyncResult._(
        isSuccess: false,
        isOffline: false,
        totalSynced: totalSynced,
        errors: errors,
      );

  String? get error => errors.values.isNotEmpty ? errors.values.join(', ') : null;

  @override
  String toString() => 'SyncResult(success: $isSuccess, offline: $isOffline, '
      'synced: $totalSynced, errors: $errors)';
}

// ─── SYNC SERVICE ─────────────────────────────────────────────────────────────

/// Coordinates delta-sync and initial-sync operations across all three sheets.
///
/// Inject this via a Riverpod provider in `providers.dart` so that [prefs]
/// and [dbHelper] are resolved once per app lifetime.
class SyncService {
  // ---------------------------------------------------------------------------
  // Dependencies
  // ---------------------------------------------------------------------------

  final DatabaseHelper _dbHelper;
  final SharedPreferences _prefs;
  final SyncQueueNotifier? _syncQueue;

  SyncService({
    ApiService? api,
    required DatabaseHelper dbHelper,
    required SharedPreferences prefs,
    SyncQueueNotifier? syncQueue,
  })  : _dbHelper = dbHelper,
        _prefs = prefs,
        _syncQueue = syncQueue;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Runs a complete delta sync (pulls only changed rows from Supabase).
  /// If [forceRefresh] is true, ignores last sync timestamp and pulls all rows.
  Future<SyncResult> syncAll({bool forceRefresh = false}) async {
    _log('syncAll() started (forceRefresh: $forceRefresh)');

    // 0. Flush any pending offline changes from the local queue to Supabase
    if (_syncQueue != null) {
      try {
        await _syncQueue!.processQueue();
      } catch (e) {
        _log('Sync queue flush warning: $e');
      }
    }

    final supabase = supabaseClient;
    final lastSyncedAt =
        forceRefresh ? null : _prefs.getString(kLastSyncSupabaseKey);
    _log('Using lastSyncedAt: $lastSyncedAt');

    int totalSynced = 0;

    try {
      // 1. Build queries
      final Future<dynamic> booksQuery;
      final Future<dynamic> usersQuery;
      final Future<dynamic> txsQuery;
      final Future<dynamic> assetsQuery;

      // Delta sync filter: only fetch records updated after last sync
      if (lastSyncedAt != null && lastSyncedAt.isNotEmpty) {
        booksQuery =
            supabase.from('books').select().gt('last_updated', lastSyncedAt);
        usersQuery =
            supabase.from('users').select().gt('last_updated', lastSyncedAt);
        txsQuery = supabase
            .from('transactions')
            .select()
            .gt('last_updated', lastSyncedAt);
        assetsQuery =
            supabase.from('assets').select().gt('last_updated', lastSyncedAt);
      } else {
        booksQuery = supabase.from('books').select();
        usersQuery = supabase.from('users').select();
        txsQuery = supabase.from('transactions').select();
        assetsQuery = supabase.from('assets').select();
      }

      // Fetch all tables concurrently
      final results = await Future.wait<dynamic>([
        booksQuery,
        usersQuery,
        txsQuery,
        assetsQuery,
      ]);

      final rawBooks = (results[0] as List?) ?? [];
      final rawUsers = (results[1] as List?) ?? [];
      final rawTxs = (results[2] as List?) ?? [];
      final rawAssets = (results[3] as List?) ?? [];

      _log(
          'Delta fetched: books=${rawBooks.length}, users=${rawUsers.length}, transactions=${rawTxs.length}, assets=${rawAssets.length}');

      // 2. Sync Books
      if (rawBooks.isNotEmpty) {
        final localBooks =
            rawBooks.map((r) => _mapBooksRow(_toMap(r))).toList();
        await _dbHelper.batchUpsert(kBooksTable, localBooks, 'accession_no');
        totalSynced += localBooks.length;
        _log('Upserted ${localBooks.length} books');
      }

      // 3. Sync Users
      if (rawUsers.isNotEmpty) {
        final localUsers =
            rawUsers.map((r) => _mapUsersRow(_toMap(r))).toList();
        await _dbHelper.batchUpsert(kUsersTable, localUsers, 'user_id');
        totalSynced += localUsers.length;
        _log('Upserted ${localUsers.length} users');
      }

      // 4. Sync Transactions
      if (rawTxs.isNotEmpty) {
        final localTxs =
            rawTxs.map((r) => _mapTransactionsRow(_toMap(r))).toList();

        if (lastSyncedAt == null) {
          final remoteIds = localTxs.map((e) => "'${e['trx_id']}'").join(',');
          if (remoteIds.isNotEmpty) {
            final db = await _dbHelper.database;
            final oneHourAgo = DateTime.now()
                .subtract(const Duration(hours: 1))
                .toIso8601String();
            await db.execute(
                'DELETE FROM $kTransactionsTable WHERE trx_id NOT IN ($remoteIds) AND last_updated < ?',
                [oneHourAgo]);
          }
        }

        await _dbHelper.batchUpsert(kTransactionsTable, localTxs, 'trx_id');
        totalSynced += localTxs.length;
        _log('Upserted ${localTxs.length} transactions');
      }

      // 5. Sync Assets
      if (rawAssets.isNotEmpty) {
        final localAssets = rawAssets
            .map((r) => _mapAssetsRow(_toMap(r)))
            .where((a) =>
                a['asset_id'] != null &&
                a['asset_id'].toString().trim().isNotEmpty &&
                a['name'] != null &&
                a['name'].toString().trim().isNotEmpty)
            .toList();

        final db = await _dbHelper.database;
        await db.execute(
            "DELETE FROM $kAssetsTable WHERE name IS NULL OR TRIM(name) = '';");

        if (lastSyncedAt == null) {
          final remoteIds =
              localAssets.map((e) => "'${e['asset_id']}'").join(',');
          if (remoteIds.isNotEmpty) {
            final oneHourAgo = DateTime.now()
                .subtract(const Duration(hours: 1))
                .toIso8601String();
            await db.execute(
                'DELETE FROM $kAssetsTable WHERE asset_id NOT IN ($remoteIds) AND last_updated < ?',
                [oneHourAgo]);
          }
        }

        if (localAssets.isNotEmpty) {
          await _dbHelper.batchUpsert(kAssetsTable, localAssets, 'asset_id');
          totalSynced += localAssets.length;
          _log('Upserted ${localAssets.length} assets');
        }
      }

      // 6. Update last_synced_at timestamp to current UTC
      final newTimestamp = DateTime.now().toUtc().toIso8601String();
      await _prefs.setString(kLastSyncSupabaseKey, newTimestamp);

      // 7. Repair any data inconsistencies
      await _dbHelper.repairBookStatuses();

      _log('syncAll() finished — synced $totalSynced rows total');
      return SyncResult.success(totalSynced);
    } catch (e, stackTrace) {
      _log('syncAll() exception: $e\n$stackTrace');
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('socketexception') ||
          errStr.contains('failed host lookup') ||
          errStr.contains('network is unreachable') ||
          errStr.contains('connection refused') ||
          errStr.contains('clientexception')) {
        return SyncResult.offline();
      }
      return SyncResult.partialFailure(
        totalSynced: totalSynced,
        errors: {'database': 'Failed to sync: $e'},
      );
    }
  }

  /// Safely converts any value to a List of items.
  List<dynamic> _toList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value;
    _log('WARNING: Expected List but got ${value.runtimeType}: $value');
    return [];
  }

  /// Safely converts any value to a Map<String, dynamic>.
  Map<String, dynamic> _toMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    _log('WARNING: Expected Map but got ${value.runtimeType}');
    return {};
  }

  // ---------------------------------------------------------------------------
  // Column name mapping (Remote GAS JS columns -> Local SQLite columns)
  // ---------------------------------------------------------------------------

  /// Maps a remote Books row to local column names.
  Map<String, dynamic> _mapBooksRow(Map<String, dynamic> r) => {
        'accession_no': r['accession_no']?.toString().trim() ?? '',
        'book_name': r['book_name']?.toString().trim() ?? '',
        'volume_no': r['volume_no']?.toString().trim() ?? '',
        'author': r['author']?.toString().trim() ?? '',
        'translator': r['translator']?.toString().trim() ?? '',
        'publisher': r['publisher']?.toString().trim() ?? '',
        'address': r['address']?.toString().trim() ?? '',
        'subject_category': r['subject_category']?.toString().trim() ?? '',
        'shelf_no': r['shelf_no']?.toString().trim() ?? '',
        'status': (r['status']?.toString().trim().isEmpty ?? true)
            ? 'Available'
            : r['status'].toString().trim(),
        'remarks': r['remarks']?.toString().trim() ?? '',
        'last_updated': r['last_updated']?.toString() ?? '',
      };

  /// Maps a remote Users row to local column names.
  Map<String, dynamic> _mapUsersRow(Map<String, dynamic> r) => {
        'user_id': r['user_id']?.toString() ?? '',
        'name': r['name']?.toString() ?? '',
        'phone': r['phone']?.toString() ?? '',
        'pin': r['pin']?.toString() ?? '',
        'type': r['type']?.toString() ?? 'Student',
        'class_jamat': r['class_jamat']?.toString() ?? '',
        'status': (r['status']?.toString().trim().isEmpty ?? true)
            ? 'Active'
            : r['status'].toString().trim(),
        'last_updated': r['last_updated']?.toString() ?? '',
      };

  /// Maps a remote Transactions row to local column names.
  Map<String, dynamic> _mapTransactionsRow(Map<String, dynamic> r) => {
        'trx_id': r['trx_id']?.toString() ?? '',
        'accession_no': r['accession_no']?.toString() ?? '',
        'user_id': r['user_id']?.toString() ?? '',
        'issue_date': r['issue_date']?.toString() ?? '',
        'expected_return': r['expected_return']?.toString() ?? '',
        'actual_return': r['actual_return']?.toString() ?? '',
        'status': (r['status']?.toString().trim().isEmpty ?? true)
            ? 'Active'
            : r['status'].toString().trim(),
        'last_updated': r['last_updated']?.toString() ?? '',
      };

  /// Maps a remote Assets row to local column names.
  Map<String, dynamic> _mapAssetsRow(Map<String, dynamic> r) => {
        'asset_id': r['asset_id']?.toString() ?? '',
        'name': r['name']?.toString() ?? '',
        'category': r['category']?.toString() ?? '',
        'quantity': int.tryParse(r['quantity']?.toString() ?? '1') ?? 1,
        'unit': r['unit']?.toString() ?? 'টি',
        'location': r['location']?.toString() ?? '',
        'condition': r['condition']?.toString() ?? 'good',
        'acquisition_type': r['acquisition_type']?.toString() ?? 'purchased',
        'donor_or_source': r['donor_or_source']?.toString() ?? '',
        'cost': double.tryParse(r['cost']?.toString() ?? ''),
        'purchase_date': r['purchase_date']?.toString() ?? '',
        'remarks': r['remarks']?.toString() ?? '',
        'last_updated': r['last_updated']?.toString() ?? '',
      };

  // ---------------------------------------------------------------------------
  // Logging
  // ---------------------------------------------------------------------------

  void _log(String message) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[SyncService] $message');
    }
  }
}
