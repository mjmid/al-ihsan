library;
/// ---------------------------------------------------------------------------
/// add_edit_asset_page.dart
/// ---------------------------------------------------------------------------
/// Form for adding new library assets or editing existing ones.
/// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maktaba_ihsan/core/l10n/app_translations.dart';

import '../../../../core/models/asset_model.dart';
import '../../../../core/providers/asset_providers.dart';

class AddEditAssetPage extends ConsumerStatefulWidget {
  final Asset? asset;

  const AddEditAssetPage({super.key, this.asset});

  @override
  ConsumerState<AddEditAssetPage> createState() => _AddEditAssetPageState();
}

class _AddEditAssetPageState extends ConsumerState<AddEditAssetPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _unitController;
  late TextEditingController _locationController;
  late TextEditingController _donorOrSourceController;
  late TextEditingController _costController;
  late TextEditingController _remarksController;

  String _selectedCategory = 'আসবাবপত্র';
  AssetCondition _selectedCondition = AssetCondition.good;
  AcquisitionType _selectedAcquisitionType = AcquisitionType.purchased;

  bool get isEdit => widget.asset != null;

  @override
  void initState() {
    super.initState();
    final a = widget.asset;

    _nameController = TextEditingController(text: a?.name ?? '');
    _quantityController =
        TextEditingController(text: a != null ? a.quantity.toString() : '1');
    _unitController = TextEditingController(text: a?.unit ?? 'টি');
    _locationController = TextEditingController(text: a?.location ?? '');
    _donorOrSourceController =
        TextEditingController(text: a?.donorOrSource ?? '');
    _costController =
        TextEditingController(text: a?.cost != null ? a!.cost.toString() : '');
    _remarksController = TextEditingController(text: a?.remarks ?? '');

    if (a != null) {
      _selectedCategory = a.category;
      _selectedCondition = a.condition;
      _selectedAcquisitionType = a.acquisitionType;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _locationController.dispose();
    _donorOrSourceController.dispose();
    _costController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _saveAsset(AppTranslations t) async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final qty = int.tryParse(_quantityController.text.trim()) ?? 1;
    final unit = _unitController.text.trim().isNotEmpty
        ? _unitController.text.trim()
        : 'টি';
    final location = _locationController.text.trim();
    final donorOrSource = _donorOrSourceController.text.trim();
    final cost = double.tryParse(_costController.text.trim());
    final remarks = _remarksController.text.trim();

    final assetId = isEdit
        ? widget.asset!.assetId
        : 'AST-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final newAsset = Asset(
      assetId: assetId,
      name: name,
      category: _selectedCategory,
      quantity: qty,
      unit: unit,
      location: location,
      condition: _selectedCondition,
      acquisitionType: _selectedAcquisitionType,
      donorOrSource: donorOrSource.isNotEmpty ? donorOrSource : null,
      cost: cost,
      purchaseDate: isEdit ? widget.asset!.purchaseDate : DateTime.now(),
      remarks: remarks.isNotEmpty ? remarks : null,
      lastUpdated: DateTime.now().toUtc(),
    );

    try {
      final repo = ref.read(assetRepositoryProvider);
      await repo.upsertAsset(newAsset);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? t.updateAssetSuccess : t.saveAssetSuccess),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${t.error}: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit ? t.editAsset : t.addNewAsset,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Asset Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: t.assetNameLabel,
                  hintText: t.assetNameHint,
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return t.assetNameRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 2. Category Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: t.categoryLabel,
                  prefixIcon: Icon(Icons.category_outlined),
                  border: OutlineInputBorder(),
                ),
                items: Asset.defaultCategories
                    .map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(t.translateCategory(cat)),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedCategory = val);
                  }
                },
              ),
              const SizedBox(height: 16),

              // 3. Quantity & Unit
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: InputDecoration(
                        labelText: t.quantityLabel,
                        prefixIcon: Icon(Icons.pin_outlined),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return t.quantityRequired;
                        }
                        final parsed = int.tryParse(val.trim());
                        if (parsed == null || parsed < 0) {
                          return t.invalidNumber;
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: Asset.defaultUnits.contains(_unitController.text)
                          ? _unitController.text
                          : 'টি',
                      decoration: InputDecoration(
                        labelText: t.unitLabel,
                        border: OutlineInputBorder(),
                      ),
                      items: Asset.defaultUnits
                          .map((u) => DropdownMenuItem(
                                value: u,
                                child: Text(t.translateUnit(u)),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          _unitController.text = val;
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 4. Location
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: t.locationFieldLabel,
                  hintText: t.locationFieldHint,
                  prefixIcon: Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return t.locationRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 5. Condition Segment
              Text(
                t.currentConditionLabel,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              SegmentedButton<AssetCondition>(
                segments: [
                  ButtonSegment(
                    value: AssetCondition.good,
                    label: Text(t.conditionGood),
                    icon: const Icon(Icons.check_circle_outline),
                  ),
                  ButtonSegment(
                    value: AssetCondition.repairNeeded,
                    label: Text(t.repairNeededLabel),
                    icon: const Icon(Icons.build_circle_outlined),
                  ),
                  ButtonSegment(
                    value: AssetCondition.damaged,
                    label: Text(t.damagedOrDisposedLabel),
                    icon: const Icon(Icons.cancel_outlined),
                  ),
                ],
                selected: {_selectedCondition},
                onSelectionChanged: (set) {
                  setState(() => _selectedCondition = set.first);
                },
              ),
              const SizedBox(height: 20),

              // 6. Acquisition Type
              Text(
                t.acquisitionTypeLabel,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              SegmentedButton<AcquisitionType>(
                segments: [
                  ButtonSegment(
                    value: AcquisitionType.purchased,
                    label: Text(t.purchasedLabel),
                    icon: Icon(Icons.shopping_bag_outlined),
                  ),
                  ButtonSegment(
                    value: AcquisitionType.waqf,
                    label: Text(t.waqfDonated),
                    icon: Icon(Icons.volunteer_activism_outlined),
                  ),
                ],
                selected: {_selectedAcquisitionType},
                onSelectionChanged: (set) {
                  setState(() => _selectedAcquisitionType = set.first);
                },
              ),
              const SizedBox(height: 16),

              // 7. Donor / Source
              TextFormField(
                controller: _donorOrSourceController,
                decoration: InputDecoration(
                  labelText: _selectedAcquisitionType == AcquisitionType.waqf
                      ? t.donorOrSourceWaqfLabel
                      : t.donorOrSourcePurchaseLabel,
                  hintText: _selectedAcquisitionType == AcquisitionType.waqf
                      ? t.donorOrSourceWaqfHint
                      : t.donorOrSourcePurchaseHint,
                  prefixIcon: const Icon(Icons.person_outline),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // 8. Cost (Optional)
              TextFormField(
                controller: _costController,
                decoration: InputDecoration(
                  labelText: t.costFieldLabel,
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // 9. Remarks
              TextFormField(
                controller: _remarksController,
                decoration: InputDecoration(
                  labelText: t.remarksFieldLabel,
                  hintText: t.remarksFieldHint,
                  prefixIcon: Icon(Icons.notes_outlined),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 28),

              // Save Button
              FilledButton.icon(
                onPressed: () => _saveAsset(t),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.save),
                label: Text(
                  isEdit ? t.updateAssetBtn : t.saveAssetBtn,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
