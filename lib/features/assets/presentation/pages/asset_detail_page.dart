library;
/// ---------------------------------------------------------------------------
/// asset_detail_page.dart
/// ---------------------------------------------------------------------------
/// Detailed view of a single asset with specifications and management actions.
/// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maktaba_ihsan/core/l10n/app_translations.dart';

import '../../../../core/models/asset_model.dart';
import '../../../../core/providers/asset_providers.dart';
import '../../../../core/theme/neu_card.dart';
import 'add_edit_asset_page.dart';

class AssetDetailPage extends ConsumerStatefulWidget {
  final Asset asset;
  final bool isAdmin;

  const AssetDetailPage({
    super.key,
    required this.asset,
    this.isAdmin = false,
  });

  @override
  ConsumerState<AssetDetailPage> createState() => _AssetDetailPageState();
}

class _AssetDetailPageState extends ConsumerState<AssetDetailPage> {
  late Asset _asset;

  @override
  void initState() {
    super.initState();
    _asset = widget.asset;
  }

  Future<void> _refreshAsset() async {
    final repo = ref.read(assetRepositoryProvider);
    final updated = await repo.getAssetById(_asset.assetId);
    if (updated != null && mounted) {
      setState(() => _asset = updated);
    }
  }

  Future<void> _changeCondition(AssetCondition newCondition) async {
    final updated = _asset.copyWith(
      condition: newCondition,
      lastUpdated: DateTime.now().toUtc(),
    );
    final repo = ref.read(assetRepositoryProvider);
    await repo.upsertAsset(updated);
    setState(() => _asset = updated);
    ref.invalidate(allAssetsProvider);
    ref.invalidate(assetSummaryCountsProvider);
  }

  Future<void> _confirmDelete(AppTranslations t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.deleteAssetConfirmTitle),
        content: Text('${t.deleteAssetConfirmMsg}\n("${_asset.name}")'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final repo = ref.read(assetRepositoryProvider);
      await repo.deleteAsset(_asset.assetId);
      ref.invalidate(allAssetsProvider);
      ref.invalidate(assetSummaryCountsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.deleteAssetSuccess),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final t = ref.watch(translationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.assetDetails,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (widget.isAdmin) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: t.edit,
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddEditAssetPage(asset: _asset),
                  ),
                );
                if (result == true) {
                  await _refreshAsset();
                  ref.invalidate(allAssetsProvider);
                  ref.invalidate(assetSummaryCountsProvider);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: t.delete,
              onPressed: () => _confirmDelete(t),
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            NeuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _asset.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${t.formatNumber(_asset.quantity)} ${t.translateUnit(_asset.unit)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Condition Chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _asset.condition.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _asset.condition.color.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_asset.condition.icon,
                                size: 14, color: _asset.condition.color),
                            const SizedBox(width: 6),
                            Text(
                              _asset.condition.getLocalizedLabel(t),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _asset.condition.color,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Acquisition Chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _asset.acquisitionType == AcquisitionType.waqf
                              ? Colors.purple.withOpacity(0.12)
                              : Colors.blue.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _asset.acquisitionType == AcquisitionType.waqf
                                ? Colors.purple.withOpacity(0.3)
                                : Colors.blue.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          _asset.acquisitionType.getLocalizedLabel(t),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _asset.acquisitionType == AcquisitionType.waqf
                                ? Colors.purple
                                : Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Condition Quick Switcher (for Admin)
            if (widget.isAdmin) ...[
              NeuCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.changeCurrentCondition,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildStatusButton(
                          label: t.conditionGood,
                          condition: AssetCondition.good,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        _buildStatusButton(
                          label: t.conditionRepair,
                          condition: AssetCondition.repairNeeded,
                          color: Colors.amber.shade800,
                        ),
                        const SizedBox(width: 8),
                        _buildStatusButton(
                          label: t.conditionDamaged,
                          condition: AssetCondition.damaged,
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Detailed Specifications Card
            NeuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.assetInfoAndSpecs,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    icon: Icons.category_outlined,
                    label: t.categoryLabel,
                    value: t.translateCategory(_asset.category),
                  ),
                  _buildDetailRow(
                    icon: Icons.location_on_outlined,
                    label: t.locationLabel,
                    value: _asset.location,
                  ),
                  _buildDetailRow(
                    icon: Icons.numbers_outlined,
                    label: t.assetIdLabel,
                    value: _asset.assetId,
                  ),
                  if (_asset.donorOrSource != null &&
                      _asset.donorOrSource!.isNotEmpty)
                    _buildDetailRow(
                      icon: Icons.person_outline,
                      label: _asset.acquisitionType == AcquisitionType.waqf ? t.donorNameLabel : t.sourceStoreLabel,
                      value: _asset.donorOrSource!,
                    ),
                  if (_asset.cost != null)
                    _buildDetailRow(
                      icon: Icons.payments_outlined,
                      label: t.costLabel,
                      value: '${t.formatNumber(_asset.cost!.toStringAsFixed(0))} ৳',
                    ),
                  if (_asset.purchaseDate != null)
                    _buildDetailRow(
                      icon: Icons.calendar_today_outlined,
                      label: t.acquisitionDateLabel,
                      value: '${t.formatNumber(_asset.purchaseDate!.day)}/${t.formatNumber(_asset.purchaseDate!.month)}/${t.formatNumber(_asset.purchaseDate!.year)}',
                    ),
                  if (_asset.remarks != null && _asset.remarks!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      t.remarksDetailLabel,
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _asset.remarks!,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton({
    required String label,
    required AssetCondition condition,
    required Color color,
  }) {
    final isCurrent = _asset.condition == condition;

    return Expanded(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: isCurrent ? color.withOpacity(0.15) : null,
          side: BorderSide(
            color: isCurrent ? color : Colors.grey.shade300,
            width: isCurrent ? 2 : 1,
          ),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        onPressed: () => _changeCondition(condition),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isCurrent ? color : null,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
