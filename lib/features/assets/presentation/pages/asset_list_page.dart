import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/asset_model.dart';
import '../../../../core/providers/asset_providers.dart';
import '../../../../core/services/print_service.dart';
import '../../../../core/theme/neu_card.dart';
import 'add_edit_asset_page.dart';
import 'asset_detail_page.dart';

class AssetListPage extends ConsumerStatefulWidget {
  final bool isAdmin;
  final bool isPrincipalOrSecretary;

  const AssetListPage({
    super.key,
    this.isAdmin = false,
    this.isPrincipalOrSecretary = false,
  });

  @override
  ConsumerState<AssetListPage> createState() => _AssetListPageState();
}

class _AssetListPageState extends ConsumerState<AssetListPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _toBn(int n) {
    const bn = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    return n.toString().split('').map((c) {
      final idx = int.tryParse(c);
      return idx != null ? bn[idx] : c;
    }).join('');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final assetsAsync = ref.watch(filteredAssetsProvider);
    final summaryAsync = ref.watch(assetSummaryCountsProvider);
    final selectedCategory = ref.watch(assetCategoryFilterProvider);
    final selectedCondition = ref.watch(assetConditionFilterProvider);
    final categoriesAsync = ref.watch(assetCategoriesProvider);
    final categories = categoriesAsync.asData?.value ?? [];
    final searchQuery = ref.watch(assetSearchQueryProvider);

    final isFiltered = searchQuery.isNotEmpty ||
        selectedCategory != null ||
        selectedCondition != null;

    final allAssetsList = assetsAsync.asData?.value ?? [];

    return Scaffold(
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton(
              heroTag: 'add_asset_fab',
              tooltip: 'নতুন মালামাল যোগ করুন',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddEditAssetPage(),
                  ),
                ).then((_) {
                  ref.invalidate(allAssetsProvider);
                  ref.invalidate(assetSummaryCountsProvider);
                });
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(allAssetsProvider);
          ref.invalidate(assetSummaryCountsProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Pinned Search + Category + Print Bar
            SliverAppBar(
              toolbarHeight: 0,
              pinned: true,
              floating: true,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(62),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 7.0,
                  ),
                  child: Row(
                    children: [
                      // Search TextField
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'মালামাল, অবস্থান বা দাতা খুঁজুন...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            suffixIcon: searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      ref
                                          .read(assetSearchQueryProvider.notifier)
                                          .state = '';
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 11,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest,
                          ),
                          onChanged: (value) {
                            ref
                                .read(assetSearchQueryProvider.notifier)
                                .state = value;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Category Popup Button
                      _buildCategoryButton(
                        context,
                        ref,
                        categories: categories,
                        selectedCategory: selectedCategory,
                        colorScheme: colorScheme,
                        isLoading: categoriesAsync.isLoading,
                      ),
                      const SizedBox(width: 8),

                      // Print Report Button
                      _buildPrintButton(
                        context,
                        assets: allAssetsList,
                        colorScheme: colorScheme,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Modern 4-Stat Metric Banner
            SliverToBoxAdapter(
              child: summaryAsync.when(
                data: (summary) => _buildSummaryBanner(
                  context,
                  ref,
                  summary: summary,
                  selectedCondition: selectedCondition,
                ),
                loading: () => const SizedBox(
                  height: 76,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            // Active Filter Chip Indicator (if any filter is on)
            if (isFiltered)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    top: 2.0,
                    bottom: 6.0,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.filter_list_rounded,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'সক্রিয় ফিল্টার:',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              if (selectedCategory != null) ...[
                                _buildActiveTag(
                                  label: selectedCategory,
                                  onDelete: () {
                                    ref
                                        .read(assetCategoryFilterProvider.notifier)
                                        .state = null;
                                  },
                                  colorScheme: colorScheme,
                                ),
                                const SizedBox(width: 6),
                              ],
                              if (selectedCondition != null) ...[
                                _buildActiveTag(
                                  label: selectedCondition.label,
                                  onDelete: () {
                                    ref
                                        .read(assetConditionFilterProvider.notifier)
                                        .state = null;
                                  },
                                  colorScheme: colorScheme,
                                ),
                                const SizedBox(width: 6),
                              ],
                              if (searchQuery.isNotEmpty) ...[
                                _buildActiveTag(
                                  label: '"$searchQuery"',
                                  onDelete: () {
                                    _searchController.clear();
                                    ref
                                        .read(assetSearchQueryProvider.notifier)
                                        .state = '';
                                  },
                                  colorScheme: colorScheme,
                                ),
                                const SizedBox(width: 6),
                              ],
                            ],
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _searchController.clear();
                          ref.read(assetSearchQueryProvider.notifier).state = '';
                          ref.read(assetCategoryFilterProvider.notifier).state =
                              null;
                          ref.read(assetConditionFilterProvider.notifier).state =
                              null;
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(40, 28),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'সব মুছুন',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Asset List / Empty State
            assetsAsync.when(
              data: (assets) {
                if (assets.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colorScheme.primary.withOpacity(0.08),
                              ),
                              child: Icon(
                                isFiltered
                                    ? Icons.search_off_rounded
                                    : Icons.inventory_2_outlined,
                                size: 44,
                                color: colorScheme.primary.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              isFiltered
                                  ? 'কোনো মালামাল মেলেনি'
                                  : 'কোনো মালামাল এন্ট্রি করা হয়নি',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isFiltered
                                  ? 'অনুসন্ধান বা ফিল্টারের শর্ত পরিবর্তন করে চেষ্টা করুন'
                                  : 'মাকতাবার আসবাবপত্র, আলমারি, বুকশেলফ বা ইলেকট্রনিক্স সরঞ্জাম সংরক্ষণ করুন',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 20),
                            if (isFiltered)
                              OutlinedButton.icon(
                                onPressed: () {
                                  _searchController.clear();
                                  ref
                                      .read(assetSearchQueryProvider.notifier)
                                      .state = '';
                                  ref
                                      .read(assetCategoryFilterProvider.notifier)
                                      .state = null;
                                  ref
                                      .read(assetConditionFilterProvider.notifier)
                                      .state = null;
                                },
                                icon: const Icon(Icons.refresh_rounded, size: 18),
                                label: const Text('ফিল্টার রিসেট করুন'),
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              )
                            else if (widget.isAdmin)
                              FilledButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const AddEditAssetPage(),
                                    ),
                                  ).then((_) {
                                    ref.invalidate(allAssetsProvider);
                                    ref.invalidate(assetSummaryCountsProvider);
                                  });
                                },
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('নতুন মালামাল যোগ করুন'),
                                style: FilledButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final asset = assets[index];
                        return _buildAssetTile(context, ref, asset);
                      },
                      childCount: assets.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, st) => SliverFillRemaining(
                child: Center(child: Text('ত্রুটি: $e')),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Category Button (Matches BookListPage Design)
  // ---------------------------------------------------------------------------

  Widget _buildCategoryButton(
    BuildContext context,
    WidgetRef ref, {
    required List<String> categories,
    required String? selectedCategory,
    required ColorScheme colorScheme,
    required bool isLoading,
  }) {
    if (selectedCategory != null) {
      return Container(
        height: 48,
        decoration: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.25),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PopupMenuButton<String?>(
              initialValue: selectedCategory,
              tooltip: 'বিভাগ পরিবর্তন করুন',
              elevation: 6,
              offset: const Offset(0, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onSelected: (cat) {
                ref.read(assetCategoryFilterProvider.notifier).state = cat;
              },
              itemBuilder: (ctx) => _buildCategoryMenuItems(
                categories: categories,
                selectedCategory: selectedCategory,
                isLoading: isLoading,
                colorScheme: colorScheme,
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 12,
                  top: 12,
                  bottom: 12,
                  right: 4,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: colorScheme.onPrimary,
                    ),
                    const SizedBox(width: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 85),
                      child: Text(
                        selectedCategory,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      size: 18,
                      color: colorScheme.onPrimary,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  ref.read(assetCategoryFilterProvider.notifier).state = null;
                },
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return PopupMenuButton<String?>(
      initialValue: selectedCategory,
      tooltip: 'বিষয় / বিভাগ ফিল্টার',
      elevation: 6,
      offset: const Offset(0, 52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (cat) {
        ref.read(assetCategoryFilterProvider.notifier).state = cat;
      },
      itemBuilder: (ctx) => _buildCategoryMenuItems(
        categories: categories,
        selectedCategory: selectedCategory,
        isLoading: isLoading,
        colorScheme: colorScheme,
      ),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tune_rounded,
              size: 18,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              'বিভাগ',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  List<PopupMenuEntry<String?>> _buildCategoryMenuItems({
    required List<String> categories,
    required String? selectedCategory,
    required bool isLoading,
    required ColorScheme colorScheme,
  }) {
    if (isLoading) {
      return [
        const PopupMenuItem<String?>(
          enabled: false,
          child: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 10),
              Text('বিভাগ লোড হচ্ছে...'),
            ],
          ),
        ),
      ];
    }

    final items = <PopupMenuEntry<String?>>[
      PopupMenuItem<String?>(
        value: null,
        child: Row(
          children: [
            Icon(
              selectedCategory == null
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              size: 18,
              color: selectedCategory == null ? colorScheme.primary : null,
            ),
            const SizedBox(width: 10),
            const Text(
              'সব বিভাগ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      const PopupMenuDivider(),
    ];

    if (categories.isEmpty) {
      items.add(
        const PopupMenuItem<String?>(
          enabled: false,
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: Colors.grey),
              SizedBox(width: 10),
              Text(
                'কোনো বিভাগ পাওয়া যায়নি',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    } else {
      for (final cat in categories) {
        final isSel = selectedCategory == cat;
        items.add(
          PopupMenuItem<String?>(
            value: cat,
            child: Row(
              children: [
                Icon(
                  isSel
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  size: 18,
                  color: isSel ? colorScheme.primary : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    cat,
                    style: TextStyle(
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      color: isSel ? colorScheme.primary : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    return items;
  }

  // ---------------------------------------------------------------------------
  // Print Button
  // ---------------------------------------------------------------------------

  Widget _buildPrintButton(
    BuildContext context, {
    required List<Asset> assets,
    required ColorScheme colorScheme,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        if (assets.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('প্রিন্ট করার মতো কোনো মালামাল নেই')),
          );
          return;
        }
        await PrintService.printAssets(assets);
      },
      child: Container(
        height: 48,
        width: 48,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.12),
          ),
        ),
        child: Icon(
          Icons.print_outlined,
          size: 20,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4-Column Metric Strip (Modern, Glassmorphic & Interactive)
  // ---------------------------------------------------------------------------

  Widget _buildSummaryBanner(
    BuildContext context,
    WidgetRef ref, {
    required Map<String, int> summary,
    required AssetCondition? selectedCondition,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final totalItems = summary['totalItems'] ?? 0;
    final totalQty = summary['totalQuantity'] ?? 0;
    final goodQty = summary['goodQuantity'] ?? 0;
    final repairQty = summary['repairQuantity'] ?? 0;
    final damagedQty = summary['damagedQuantity'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.35),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outline.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildMetricItem(
                label: 'মোট মালামাল',
                count: totalQty,
                subLabel: '${_toBn(totalItems)} পদ',
                color: const Color(0xFF0284C7),
                icon: Icons.inventory_2_outlined,
                isSelected: selectedCondition == null,
                onTap: () {
                  ref.read(assetConditionFilterProvider.notifier).state = null;
                },
              ),
            ),
            Container(
              width: 1,
              height: 32,
              color: colorScheme.outline.withOpacity(0.12),
            ),
            Expanded(
              child: _buildMetricItem(
                label: 'ভালো',
                count: goodQty,
                subLabel: 'ব্যবহারযোগ্য',
                color: const Color(0xFF059669),
                icon: Icons.check_circle_outline,
                isSelected: selectedCondition == AssetCondition.good,
                onTap: () {
                  ref.read(assetConditionFilterProvider.notifier).state =
                      selectedCondition == AssetCondition.good
                          ? null
                          : AssetCondition.good;
                },
              ),
            ),
            Container(
              width: 1,
              height: 32,
              color: colorScheme.outline.withOpacity(0.12),
            ),
            Expanded(
              child: _buildMetricItem(
                label: 'মেরামত',
                count: repairQty,
                subLabel: 'রক্ষণাবেক্ষণ',
                color: const Color(0xFFD97706),
                icon: Icons.build_outlined,
                isSelected: selectedCondition == AssetCondition.repairNeeded,
                onTap: () {
                  ref.read(assetConditionFilterProvider.notifier).state =
                      selectedCondition == AssetCondition.repairNeeded
                          ? null
                          : AssetCondition.repairNeeded;
                },
              ),
            ),
            Container(
              width: 1,
              height: 32,
              color: colorScheme.outline.withOpacity(0.12),
            ),
            Expanded(
              child: _buildMetricItem(
                label: 'নষ্ট/বাতিল',
                count: damagedQty,
                subLabel: 'অনুপযোগী',
                color: const Color(0xFFDC2626),
                icon: Icons.error_outline,
                isSelected: selectedCondition == AssetCondition.damaged,
                onTap: () {
                  ref.read(assetConditionFilterProvider.notifier).state =
                      selectedCondition == AssetCondition.damaged
                          ? null
                          : AssetCondition.damaged;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required int count,
    required String subLabel,
    required Color color,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 12, color: color),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              '${_toBn(count)} টি',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              subLabel,
              style: TextStyle(
                fontSize: 9.5,
                color: color.withOpacity(0.8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Active Tag Pill
  // ---------------------------------------------------------------------------

  Widget _buildActiveTag({
    required String label,
    required VoidCallback onDelete,
    required ColorScheme colorScheme,
  }) {
    return Container(
      padding: const EdgeInsets.only(left: 8, right: 2, top: 2, bottom: 2),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onDelete,
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: Icon(
                Icons.close_rounded,
                size: 14,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Asset Tile
  // ---------------------------------------------------------------------------

  Widget _buildAssetTile(BuildContext context, WidgetRef ref, Asset asset) {
    final colorScheme = Theme.of(context).colorScheme;

    IconData getCategoryIcon(String cat) {
      if (cat.contains('আসবাবপত্র')) return Icons.chair_outlined;
      if (cat.contains('ইলেকট্রনিক্স')) return Icons.devices_outlined;
      if (cat.contains('বই')) return Icons.auto_stories_outlined;
      if (cat.contains('স্টেশনারি')) return Icons.edit_note_outlined;
      if (cat.contains('পরিচ্ছন্নতা')) return Icons.cleaning_services_outlined;
      return Icons.inventory_2_outlined;
    }

    final categoryIcon = getCategoryIcon(asset.category);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: NeuCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AssetDetailPage(
                  asset: asset,
                  isAdmin: widget.isAdmin,
                ),
              ),
            ).then((_) {
              ref.invalidate(allAssetsProvider);
              ref.invalidate(assetSummaryCountsProvider);
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Icon Avatar
                CircleAvatar(
                  radius: 22,
                  backgroundColor: colorScheme.primary.withOpacity(0.12),
                  child: Icon(
                    categoryIcon,
                    color: colorScheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),

                // Main Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        asset.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              asset.location,
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          // Condition Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: asset.condition.color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: asset.condition.color.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  asset.condition.icon,
                                  size: 12,
                                  color: asset.condition.color,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  asset.condition.label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: asset.condition.color,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Waqf Badge
                          if (asset.acquisitionType == AcquisitionType.waqf)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.purple.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                asset.donorOrSource != null &&
                                        asset.donorOrSource!.isNotEmpty
                                    ? 'ওয়াকফ (${asset.donorOrSource})'
                                    : 'ওয়াকফকৃত',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.purple,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Quantity & Quick +/- counter for Admin
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_toBn(asset.quantity)} ${asset.unit}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    if (widget.isAdmin) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () async {
                              final repo = ref.read(assetRepositoryProvider);
                              await repo.updateQuantity(asset.assetId, -1);
                              ref.invalidate(allAssetsProvider);
                              ref.invalidate(assetSummaryCountsProvider);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.remove, size: 16),
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () async {
                              final repo = ref.read(assetRepositoryProvider);
                              await repo.updateQuantity(asset.assetId, 1);
                              ref.invalidate(allAssetsProvider);
                              ref.invalidate(assetSummaryCountsProvider);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.add,
                                size: 16,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
