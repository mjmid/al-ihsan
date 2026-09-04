/// ---------------------------------------------------------------------------
/// asset_detail_page.dart
/// ---------------------------------------------------------------------------
/// Detailed view of a single asset with specifications and management actions.
/// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('মালামাল মুছে ফেলা'),
        content: Text(
          'আপনি কি নিশ্চিত যে "${_asset.name}" মালামালটি তালিকা থেকে স্থায়ীভাবে মুছে ফেলতে চান?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('বাতিল'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('মুছে ফেলুন'),
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
          const SnackBar(
            content: Text('মালামাল সফলভাবে মুছে ফেলা হয়েছে'),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'মালামালের বিবরণ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (widget.isAdmin) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'এডিট করুন',
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
              tooltip: 'মুছে ফেলুন',
              onPressed: _confirmDelete,
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
                          '${_asset.quantity} ${_asset.unit}',
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
                              _asset.condition.label,
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
                          _asset.acquisitionType.label,
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
                    const Text(
                      'বর্তমান অবস্থা পরিবর্তন করুন:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildStatusButton(
                          label: 'ভালো',
                          condition: AssetCondition.good,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        _buildStatusButton(
                          label: 'মেরামত',
                          condition: AssetCondition.repairNeeded,
                          color: Colors.amber.shade800,
                        ),
                        const SizedBox(width: 8),
                        _buildStatusButton(
                          label: 'নষ্ট',
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
                  const Text(
                    'মালামালের বিবরণ ও তথ্য',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    icon: Icons.category_outlined,
                    label: 'বিভাগ / ক্যাটাগরি',
                    value: _asset.category,
                  ),
                  _buildDetailRow(
                    icon: Icons.location_on_outlined,
                    label: 'অবস্থান (কোথায় আছে)',
                    value: _asset.location,
                  ),
                  _buildDetailRow(
                    icon: Icons.numbers_outlined,
                    label: 'মালামাল আইডি (Code)',
                    value: _asset.assetId,
                  ),
                  if (_asset.donorOrSource != null &&
                      _asset.donorOrSource!.isNotEmpty)
                    _buildDetailRow(
                      icon: Icons.person_outline,
                      label: _asset.acquisitionType == AcquisitionType.waqf
                          ? 'দাতার নাম (ওয়াকফকারী)'
                          : 'ক্রয়ের উৎস / দোকান',
                      value: _asset.donorOrSource!,
                    ),
                  if (_asset.cost != null)
                    _buildDetailRow(
                      icon: Icons.payments_outlined,
                      label: 'আনুমানিক মূল্য / খরচ',
                      value: '${_asset.cost!.toStringAsFixed(0)} ৳',
                    ),
                  if (_asset.purchaseDate != null)
                    _buildDetailRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'সংগ্রহের তারিখ',
                      value:
                          '${_asset.purchaseDate!.day}/${_asset.purchaseDate!.month}/${_asset.purchaseDate!.year}',
                    ),
                  if (_asset.remarks != null && _asset.remarks!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'মন্তব্য / বিবরণ:',
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
