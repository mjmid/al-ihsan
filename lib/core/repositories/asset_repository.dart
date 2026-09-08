/// ---------------------------------------------------------------------------
/// asset_repository.dart
/// ---------------------------------------------------------------------------
/// Repository for all local SQLite read/write operations on library assets,
/// furniture, equipment, and consumables.
/// ---------------------------------------------------------------------------

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../constants/app_constants.dart';
import '../database/database_helper.dart';
import '../models/asset_model.dart';
import '../services/sync_queue_service.dart';

final assetRepositoryProvider = Provider<AssetRepository>((ref) {
  return AssetRepository(
    db: DatabaseHelper.instance,
    syncQueue: ref.watch(syncQueueProvider.notifier),
  );
});

class AssetRepository {
  final DatabaseHelper _db;
  final SyncQueueNotifier _syncQueue;

  const AssetRepository({
    required DatabaseHelper db,
    required SyncQueueNotifier syncQueue,
  })  : _db = db,
        _syncQueue = syncQueue;

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  /// Fetches all assets ordered by name.
  Future<List<Asset>> getAllAssets({
    String? category,
    AssetCondition? condition,
    String? searchQuery,
  }) async {
    final db = await _db.database;

    final conditions = <String>[];
    final args = <dynamic>[];

    if (category != null && category.isNotEmpty) {
      conditions.add('category = ?');
      args.add(category);
    }

    if (condition != null) {
      conditions.add('condition = ?');
      args.add(condition.name);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = '%${searchQuery.trim()}%';
      conditions.add('(name LIKE ? OR location LIKE ? OR remarks LIKE ? OR donor_or_source LIKE ?)');
      args.addAll([q, q, q, q]);
    }

    conditions.add("name IS NOT NULL AND TRIM(name) != ''");

    final whereClause = conditions.isNotEmpty ? conditions.join(' AND ') : null;

    final rows = await db.query(
      kAssetsTable,
      where: whereClause,
      whereArgs: args.isNotEmpty ? args : null,
      orderBy: 'name ASC',
    );

    return rows.map(Asset.fromMap).toList();
  }

  /// Fetches a single asset by [assetId].
  Future<Asset?> getAssetById(String assetId) async {
    final db = await _db.database;
    final rows = await db.query(
      kAssetsTable,
      where: 'asset_id = ?',
      whereArgs: [assetId],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return Asset.fromMap(rows.first);
  }

  /// Returns summary statistics for assets:
  /// - totalItems
  /// - totalQuantity
  /// - goodCount
  /// - repairCount
  /// - damagedCount
  /// - waqfCount
  Future<Map<String, int>> getSummaryCounts() async {
    final db = await _db.database;

    final rows = await db.rawQuery('''
      SELECT
        COUNT(*) as total_items,
        COALESCE(SUM(quantity), 0) as total_quantity,
        SUM(CASE WHEN condition = 'good' THEN quantity ELSE 0 END) as good_quantity,
        SUM(CASE WHEN condition = 'repairNeeded' THEN quantity ELSE 0 END) as repair_quantity,
        SUM(CASE WHEN condition = 'damaged' THEN quantity ELSE 0 END) as damaged_quantity,
        SUM(CASE WHEN acquisition_type = 'waqf' THEN quantity ELSE 0 END) as waqf_quantity
      FROM $kAssetsTable
    ''');

    if (rows.isEmpty) {
      return {
        'totalItems': 0,
        'totalQuantity': 0,
        'goodQuantity': 0,
        'repairQuantity': 0,
        'damagedQuantity': 0,
        'waqfQuantity': 0,
      };
    }

    final r = rows.first;
    return {
      'totalItems': (r['total_items'] as num?)?.toInt() ?? 0,
      'totalQuantity': (r['total_quantity'] as num?)?.toInt() ?? 0,
      'goodQuantity': (r['good_quantity'] as num?)?.toInt() ?? 0,
      'repairQuantity': (r['repair_quantity'] as num?)?.toInt() ?? 0,
      'damagedQuantity': (r['damaged_quantity'] as num?)?.toInt() ?? 0,
      'waqfQuantity': (r['waqf_quantity'] as num?)?.toInt() ?? 0,
    };
  }

  /// Returns distinct categories in the database.
  Future<List<String>> getAllCategories() async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT DISTINCT category FROM $kAssetsTable
      WHERE category IS NOT NULL AND category != ''
      ORDER BY category ASC
    ''');

    final set = <String>{};
    for (final r in rows) {
      final cat = r['category']?.toString();
      if (cat != null && cat.isNotEmpty) set.add(cat);
    }
    return set.toList();
  }

  /// Returns distinct locations in the database.
  Future<List<String>> getAllLocations() async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT DISTINCT location FROM $kAssetsTable
      WHERE location IS NOT NULL AND location != ''
      ORDER BY location ASC
    ''');

    final set = <String>{};
    for (final r in rows) {
      final loc = r['location']?.toString();
      if (loc != null && loc.isNotEmpty) set.add(loc);
    }
    return set.toList();
  }

  // ---------------------------------------------------------------------------
  // Writes
  // ---------------------------------------------------------------------------

  /// Inserts or replaces [asset].
  Future<void> upsertAsset(Asset asset) async {
    final db = await _db.database;
    await db.insert(
      kAssetsTable,
      asset.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Enqueue remote sync operation
    _syncQueue.enqueue(
      SyncOperation.create(
        sheet: 'Assets',
        action: 'upsert',
        payload: asset.toMap(),
      ),
    );
  }

  /// Deletes an asset by [assetId].
  Future<void> deleteAsset(String assetId) async {
    final db = await _db.database;
    await db.delete(
      kAssetsTable,
      where: 'asset_id = ?',
      whereArgs: [assetId],
    );

    _syncQueue.enqueue(
      SyncOperation.create(
        sheet: 'Assets',
        action: 'delete',
        payload: {'asset_id': assetId},
      ),
    );
  }

  /// Increments or decrements asset quantity by [delta].
  /// Does not allow quantity to drop below 0.
  Future<void> updateQuantity(String assetId, int delta) async {
    final asset = await getAssetById(assetId);
    if (asset == null) return;

    final newQuantity = (asset.quantity + delta).clamp(0, 99999);
    final updated = asset.copyWith(
      quantity: newQuantity,
      lastUpdated: DateTime.now().toUtc(),
    );

    await upsertAsset(updated);
  }
}
