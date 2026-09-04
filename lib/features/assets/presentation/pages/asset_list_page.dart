/// ---------------------------------------------------------------------------
/// asset_list_page.dart
/// ---------------------------------------------------------------------------
/// Main asset & inventory page for Maktaba Ihsan.
/// Displays inventory summary, category/condition filters, search, and asset list.
/// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/asset_model.dart';
import '../../../../core/providers/asset_providers.dart';
import '../../../../core/services/print_service.dart';
import '../../../../core/theme/neu_card.dart';
import 'add_edit_asset_page.dart';
import 'asset_detail_page.dart';

class AssetListPage extends ConsumerWidget {
  final bool isAdmin;
  final bool isPrincipalOrSecretary;

  const AssetListPage({
    super.key,
    this.isAdmin = false,
    this.isPrincipalOrSecretary = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final assetsAsync = ref.watch(filteredAssetsProvider);
    final summaryAsync = ref.watch(assetSummaryCountsProvider);
    final selectedCategory = ref.watch(assetCategoryFilterProvider);
    final selectedCondition = ref.watch(assetConditionFilterProvider);
    final categoriesAsync = ref.watch(assetCategoriesProvider);

    return Scaffold(
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
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
              icon: const Icon(Icons.add),
              label: const Text('নতুন মালামাল'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(allAssetsProvider);
          ref.invalidate(assetSummaryCountsProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Top App Bar
            SliverAppBar(
              pinned: true,
              floating: true,
              title: const Text(
                'মালামাল ও সরঞ্জাম',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.print_outlined),
                  tooltip: 'অডিট তালিকা প্রিন্ট / পিডিএফ',
                  onPressed: () async {
                    final assets = assetsAsync.asData?.value ?? [];
                    if (assets.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('প্রিন্ট করার মতো কোনো মালামাল নেই')),
                      );
                      return;
                    }
                    await PrintService.printAssets(assets);
                  },
                ),
              ],
            ),

            // Top Summary KPI Cards
            SliverToBoxAdapter(
              child: summaryAsync.when(
                data: (summary) => _buildSummaryCards(context, summary),
                loading: () => const SizedBox(
                  height: 90,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'মালামাল, অবস্থান বা দাতার নাম দিয়ে খুঁজুন...',
                    prefixIcon: const Icon(Icons.search),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                  ),
                  onChanged: (value) {
                    ref.read(assetSearchQueryProvider.notifier).state = value;
                  },
                ),
              ),
            ),

            // Category Filter Chips
            SliverToBoxAdapter(
              child: categoriesAsync.when(
                data: (categories) => _buildCategoryChips(
                  context,
                  ref,
                  categories: categories,
                  selectedCategory: selectedCategory,
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            // Condition Filter Row
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildConditionFilterChip(
                        ref: ref,
                        label: 'সব অবস্থা',
                        condition: null,
                        isSelected: selectedCondition == null,
                      ),
                      const SizedBox(width: 8),
                      _buildConditionFilterChip(
                        ref: ref,
                        label: 'ভালো',
                        condition: AssetCondition.good,
                        isSelected: selectedCondition == AssetCondition.good,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      _buildConditionFilterChip(
                        ref: ref,
                        label: 'মেরামত প্রয়োজন',
                        condition: AssetCondition.repairNeeded,
                        isSelected: selectedCondition == AssetCondition.repairNeeded,
                        color: Colors.amber.shade700,
                      ),
                      const SizedBox(width: 8),
                      _buildConditionFilterChip(
                        ref: ref,
                        label: 'নষ্ট / বাতিল',
                        condition: AssetCondition.damaged,
                        isSelected: selectedCondition == AssetCondition.damaged,
                        color: Colors.red,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // Assets List
            assetsAsync.when(
              data: (assets) {
                if (assets.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: colorScheme.outline.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'কোনো মালামাল পাওয়া যায়নি',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (isAdmin) ...[
                            const SizedBox(height: 12),
                            FilledButton.icon(
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
                              icon: const Icon(Icons.add),
                              label: const Text('মালামাল যোগ করুন'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
  // Widgets
  // ---------------------------------------------------------------------------

  Widget _buildSummaryCards(BuildContext context, Map<String, int> summary) {
    final totalItems = summary['totalItems'] ?? 0;
    final totalQty = summary['totalQuantity'] ?? 0;
    final goodQty = summary['goodQuantity'] ?? 0;
    final repairQty = summary['repairQuantity'] ?? 0;
    final waqfQty = summary['waqfQuantity'] ?? 0;

    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 4.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildKpiCard(
              title: 'মোট মালামাল',
              value: '$totalQty টি',
              subtitle: '$totalItems পদ',
              color: Colors.blue,
              icon: Icons.inventory_2_rounded,
            ),
            const SizedBox(width: 10),
            _buildKpiCard(
              title: 'ভালো অবস্থায়',
              value: '$goodQty টি',
              subtitle: 'ব্যবহারযোগ্য',
              color: Colors.green,
              icon: Icons.check_circle_rounded,
            ),
            const SizedBox(width: 10),
            _buildKpiCard(
              title: 'মেরামত প্রয়োজন',
              value: '$repairQty টি',
              subtitle: 'রক্ষণাবেক্ষণ',
              color: Colors.orange,
              icon: Icons.build_circle_rounded,
            ),
            const SizedBox(width: 10),
            _buildKpiCard(
              title: 'ওয়াকফকৃত',
              value: '$waqfQty টি',
              subtitle: 'দান হিসেবে প্রাপ্ত',
              color: Colors.purple,
              icon: Icons.volunteer_activism_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      width: 135,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color.withOpacity(0.9),
                ),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.75),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(
    BuildContext context,
    WidgetRef ref, {
    required List<String> categories,
    required String? selectedCategory,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FilterChip(
              label: const Text('সব বিভাগ'),
              selected: selectedCategory == null,
              onSelected: (_) {
                ref.read(assetCategoryFilterProvider.notifier).state = null;
              },
            ),
            const SizedBox(width: 8),
            ...categories.map(
              (cat) => Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  label: Text(cat),
                  selected: selectedCategory == cat,
                  onSelected: (selected) {
                    ref.read(assetCategoryFilterProvider.notifier).state =
                        selected ? cat : null;
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionFilterChip({
    required WidgetRef ref,
    required String label,
    required AssetCondition? condition,
    required bool isSelected,
    Color? color,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: color?.withOpacity(0.2),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected && color != null ? color : null,
      ),
      onSelected: (_) {
        ref.read(assetConditionFilterProvider.notifier).state = condition;
      },
    );
  }

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
                  isAdmin: isAdmin,
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
                          Icon(Icons.location_on_outlined,
                              size: 14, color: colorScheme.onSurfaceVariant),
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
                        '${asset.quantity} ${asset.unit}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    if (isAdmin) ...[
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
                              child: Icon(Icons.add,
                                  size: 16, color: colorScheme.primary),
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
