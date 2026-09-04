/// ---------------------------------------------------------------------------
/// asset_providers.dart
/// ---------------------------------------------------------------------------
/// Riverpod providers for library asset management.
/// ---------------------------------------------------------------------------

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/asset_model.dart';
import '../repositories/asset_repository.dart';

export '../repositories/asset_repository.dart';

/// Search query string state
final assetSearchQueryProvider = StateProvider<String>((ref) => '');

/// Selected category filter (null = all)
final assetCategoryFilterProvider = StateProvider<String?>((ref) => null);

/// Selected condition filter (null = all)
final assetConditionFilterProvider = StateProvider<AssetCondition?>((ref) => null);

/// Fetches all assets from local database
final allAssetsProvider = FutureProvider.autoDispose<List<Asset>>((ref) async {
  final repo = ref.watch(assetRepositoryProvider);
  return repo.getAllAssets();
});

/// Computes filtered assets based on search query, category, and condition
final filteredAssetsProvider = Provider.autoDispose<AsyncValue<List<Asset>>>((ref) {
  final assetsAsync = ref.watch(allAssetsProvider);
  final query = ref.watch(assetSearchQueryProvider).toLowerCase().trim();
  final category = ref.watch(assetCategoryFilterProvider);
  final condition = ref.watch(assetConditionFilterProvider);

  return assetsAsync.whenData((assets) {
    return assets.where((asset) {
      if (category != null && category.isNotEmpty && asset.category != category) {
        return false;
      }
      if (condition != null && asset.condition != condition) {
        return false;
      }
      if (query.isNotEmpty) {
        final matchesName = asset.name.toLowerCase().contains(query);
        final matchesLoc = asset.location.toLowerCase().contains(query);
        final matchesDonor = (asset.donorOrSource ?? '').toLowerCase().contains(query);
        final matchesRemarks = (asset.remarks ?? '').toLowerCase().contains(query);
        if (!matchesName && !matchesLoc && !matchesDonor && !matchesRemarks) {
          return false;
        }
      }
      return true;
    }).toList();
  });
});

/// Summary counts for top KPI cards
final assetSummaryCountsProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final repo = ref.watch(assetRepositoryProvider);
  return repo.getSummaryCounts();
});

/// Distinct categories
final assetCategoriesProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final repo = ref.watch(assetRepositoryProvider);
  final dbCats = await repo.getAllCategories();
  // Merge default categories with any custom ones in DB
  final all = <String>{...Asset.defaultCategories, ...dbCats};
  return all.toList();
});

/// Distinct locations
final assetLocationsProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final repo = ref.watch(assetRepositoryProvider);
  return repo.getAllLocations();
});
