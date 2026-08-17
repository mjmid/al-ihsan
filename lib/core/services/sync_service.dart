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

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../database/database_helper.dart';
import 'api_service.dart';

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

  final ApiService _api;
  final DatabaseHelper _dbHelper;
  final SharedPreferences _prefs;

  SyncService({
    required ApiService api,
    required DatabaseHelper dbHelper,
    required SharedPreferences prefs,
  })  : _api = api,
        _dbHelper = dbHelper,
        _prefs = prefs;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Runs a complete sync (pulls all delta changes from the server).
  Future<SyncResult> syncAll() async {
    _log('syncAll() started');

    // Always pass empty string to get ALL data on every pull.
    // The GAS script returns all rows when last_synced_at is empty.
    final result = await _api.pull('');
    if (!result.isSuccess) {
      _log('syncAll failed: ${result.error}');
      // We don't know if it's offline or server error, so return partial failure.
      return SyncResult.partialFailure(
        totalSynced: 0,
        errors: {'global': result.error ?? 'Unknown error'},
      );
    }

    final data = result.data!;
    int totalSynced = 0;

    _log('Pull data keys: ${data.keys.toList()}');

    try {
      // 1. Sync Books
      final rawBooks = data['books'];
      _log(
          'Books raw type: ${rawBooks.runtimeType}, value preview: ${rawBooks.toString().substring(0, rawBooks.toString().length > 100 ? 100 : rawBooks.toString().length)}');
      final booksList = _toList(rawBooks);
      if (booksList.isNotEmpty) {
        final localBooks =
            booksList.map((r) => _mapBooksRow(_toMap(r))).toList();
        await _dbHelper.batchUpsert(kBooksTable, localBooks, 'accession_no');
        totalSynced += localBooks.length;
        _log('Upserted ${localBooks.length} books');
      }

      // 2. Sync Users
      final rawUsers = data['users'];
      _log('Users raw type: ${rawUsers.runtimeType}');
      final usersList = _toList(rawUsers);
      if (usersList.isNotEmpty) {
        final localUsers =
            usersList.map((r) => _mapUsersRow(_toMap(r))).toList();
        await _dbHelper.batchUpsert(kUsersTable, localUsers, 'user_id');
        totalSynced += localUsers.length;
        _log('Upserted ${localUsers.length} users');
      }

      // 3. Sync Transactions
      final rawTxs = data['transactions'];
      _log('Transactions raw type: ${rawTxs.runtimeType}');
      final txsList = _toList(rawTxs);
      if (txsList.isNotEmpty) {
        final localTxs =
            txsList.map((r) => _mapTransactionsRow(_toMap(r))).toList();
        await _dbHelper.batchUpsert(kTransactionsTable, localTxs, 'trx_id');
        totalSynced += localTxs.length;
        _log('Upserted ${localTxs.length} transactions');
      }

      // 4. Update last_synced_at
      final timestamp = data['timestamp']?.toString();
      if (timestamp != null && timestamp.isNotEmpty) {
        await _prefs.setString('last_synced_at', timestamp);
      }

      _log('syncAll() finished — synced $totalSynced rows total');
      return SyncResult.success(totalSynced);
    } catch (e, stackTrace) {
      _log('syncAll() exception: $e\n$stackTrace');
      return SyncResult.partialFailure(
        totalSynced: totalSynced,
        errors: {'database': 'Failed to save data: $e'},
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
        'accession_no': r['accession_no']?.toString() ?? '',
        'book_name': r['book_name']?.toString() ?? '',
        'volume_no': r['volume_no']?.toString() ?? '',
        'author': r['author']?.toString() ?? '',
        'translator': r['translator']?.toString() ?? '',
        'publisher': r['publisher']?.toString() ?? '',
        'address': r['address']?.toString() ?? '',
        'subject_category': r['subject_category']?.toString() ?? '',
        'shelf_no': r['shelf_no']?.toString() ?? '',
        'status': (r['status']?.toString().trim().isEmpty ?? true)
            ? 'Available'
            : r['status'].toString().trim(),
        'remarks': r['remarks']?.toString() ?? '',
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
