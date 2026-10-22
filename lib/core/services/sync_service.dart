/// ---------------------------------------------------------------------------
/// sync_service.dart
/// ---------------------------------------------------------------------------
/// Orchestrates data synchronisation between the local SQLite database
/// and the Google Apps Script (GAS) Web-App backed by Google Sheets.
/// ---------------------------------------------------------------------------
library;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../database/database_helper.dart';
import '../database/hive_helper.dart';
import 'api_service.dart';
import 'sync_queue_service.dart';

// ─── SYNC RESULT ─────────────────────────────────────────────────────────────

/// Outcome of a [SyncService.syncAll] run.
class SyncResult {
  final bool isSuccess;
  final bool isOffline;
  final int totalSynced;
  final Map<String, String> errors;

  const SyncResult._({
    required this.isSuccess,
    required this.isOffline,
    required this.totalSynced,
    required this.errors,
  });

  factory SyncResult.offline() => const SyncResult._(
        isSuccess: false,
        isOffline: true,
        totalSynced: 0,
        errors: {},
      );

  factory SyncResult.success(int totalSynced) => SyncResult._(
        isSuccess: true,
        isOffline: false,
        totalSynced: totalSynced,
        errors: const {},
      );

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

  String? get error =>
      errors.values.isNotEmpty ? errors.values.join(', ') : null;

  @override
  String toString() =>
      'SyncResult(success: $isSuccess, offline: $isOffline, synced: $totalSynced, errors: $errors)';
}

// ─── SYNC SERVICE ─────────────────────────────────────────────────────────────

class SyncService {
  final ApiService _api;
  final DatabaseHelper _dbHelper;
  final SharedPreferences _prefs;
  final SyncQueueNotifier? _syncQueue;

  SyncService({
    required ApiService api,
    required DatabaseHelper dbHelper,
    required SharedPreferences prefs,
    SyncQueueNotifier? syncQueue,
  })  : _api = api,
        _dbHelper = dbHelper,
        _prefs = prefs,
        _syncQueue = syncQueue;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Runs a complete data sync with Google Apps Script (Google Sheets backend).
  Future<SyncResult> syncAll({bool forceRefresh = false}) async {
    _log('syncAll() started (forceRefresh: $forceRefresh)');

    // 0. Flush any pending offline changes from the local queue to GAS
    if (_syncQueue != null) {
      try {
        await _syncQueue.processQueue(_api);
      } catch (e) {
        _log('Sync queue flush warning: $e');
      }
    }

    // 1. Pull latest data from Google Apps Script Web App
    final result = await _api.pull('');
    if (!result.isSuccess) {
      _log('syncAll failed: ${result.error}');
      final errStr = (result.error ?? '').toLowerCase();
      if (errStr.contains('socketexception') ||
          errStr.contains('network') ||
          errStr.contains('clientexception') ||
          errStr.contains('timeout') ||
          errStr.contains('failed host lookup') ||
          errStr.contains('connection refused') ||
          errStr.contains('connection closed') ||
          errStr.contains('handshakeexception')) {
        return SyncResult.offline();
      }
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
      final usersList = _toList(rawUsers);
      if (usersList.isNotEmpty) {
        final localUsers =
            usersList.map((r) => _mapUsersRow(_toMap(r))).toList();
        await _dbHelper.batchUpsert(kUsersTable, localUsers, 'user_id');
        totalSynced += localUsers.length;
        _log('Upserted ${localUsers.length} users');

        // Automatically update admin WhatsApp number from users table
        final adminUser = localUsers.cast<Map<String, dynamic>?>().firstWhere(
          (u) => (u?['type']?.toString().toLowerCase() == 'admin' &&
                  u?['phone']?.toString().trim().isNotEmpty == true),
          orElse: () => null,
        );
        if (adminUser != null) {
          final phone = adminUser['phone'].toString().trim();
          final current =
              HiveHelper.getSetting<String>('admin_whatsapp_number', '');
          if (current != phone) {
            await HiveHelper.setSetting('admin_whatsapp_number', phone);
            _log('Synced admin WhatsApp number from users table: $phone');
          }
        }
      }

      // 3. Sync Transactions
      final rawTxs = data['transactions'];
      final txsList = _toList(rawTxs);
      if (txsList.isNotEmpty) {
        final localTxs =
            txsList.map((r) => _mapTransactionsRow(_toMap(r))).toList();

        final remoteIds = localTxs.map((e) => "'${e['trx_id']}'").join(',');
        if (remoteIds.isNotEmpty) {
          final db = await _dbHelper.database;
          // Delete transactions not on server, protecting recently created offline ones (last 1 hour)
          final oneHourAgo = DateTime.now()
              .subtract(const Duration(hours: 1))
              .toIso8601String();
          await db.execute(
            'DELETE FROM $kTransactionsTable WHERE trx_id NOT IN ($remoteIds) AND last_updated < ?',
            [oneHourAgo],
          );
        }

        await _dbHelper.batchUpsert(kTransactionsTable, localTxs, 'trx_id');
        totalSynced += localTxs.length;
        _log('Upserted ${localTxs.length} transactions');
      }

      // 4. Sync Assets
      final rawAssets = data['assets'];
      if (rawAssets != null) {
        final assetsList = _toList(rawAssets);
        if (assetsList.isNotEmpty) {
          final localAssets = assetsList
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

          final remoteIds =
              localAssets.map((e) => "'${e['asset_id']}'").join(',');
          if (remoteIds.isNotEmpty) {
            final oneHourAgo = DateTime.now()
                .subtract(const Duration(hours: 1))
                .toIso8601String();
            await db.execute(
              'DELETE FROM $kAssetsTable WHERE asset_id NOT IN ($remoteIds) AND last_updated < ?',
              [oneHourAgo],
            );
          }

          if (localAssets.isNotEmpty) {
            await _dbHelper.batchUpsert(kAssetsTable, localAssets, 'asset_id');
            totalSynced += localAssets.length;
            _log('Upserted ${localAssets.length} assets');
          }
        }
      }

      // 5. Update last_synced_at timestamp
      final timestamp = data['timestamp']?.toString();
      if (timestamp != null && timestamp.isNotEmpty) {
        await _prefs.setString('last_synced_at', timestamp);
        await _prefs.setString(kLastSyncSupabaseKey, timestamp);
      }

      // 6. Reconcile book statuses based on active transactions
      try {
        final db = await _dbHelper.database;
        await db.execute('''
          UPDATE $kBooksTable 
          SET status = 'Lent'
          WHERE accession_no IN (
            SELECT accession_no FROM $kTransactionsTable 
            WHERE status IN ('Active', 'Overdue')
          ) AND status != 'Lent';
        ''');
      } catch (e) {
        _log('Warning: book status reconciliation error: $e');
      }

      // 7. Repair any data inconsistencies
      await _dbHelper.repairBookStatuses();

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
  // Column name mapping (Remote GAS columns -> Local SQLite columns)
  // ---------------------------------------------------------------------------

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

  void _log(String message) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[SyncService] $message');
    }
  }
}
