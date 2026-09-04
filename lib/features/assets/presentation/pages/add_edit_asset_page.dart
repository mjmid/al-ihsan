/// ---------------------------------------------------------------------------
/// add_edit_asset_page.dart
/// ---------------------------------------------------------------------------
/// Form for adding new library assets or editing existing ones.
/// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  Future<void> _saveAsset() async {
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
            content: Text(isEdit
                ? 'মালামালের তথ্য সফলভাবে আপডেট হয়েছে'
                : 'নতুন মালামাল সফলভাবে যুক্ত হয়েছে'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ত্রুটি: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit ? 'মালামাল এডিট করুন' : 'নতুন মালামাল যোগ করুন',
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
                decoration: const InputDecoration(
                  labelText: 'মালামালের নাম *',
                  hintText: 'যেমন: বড় কাঠের বুকশেলফ, অফিস চেয়ার, প্রিন্টার',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'দয়া করে মালামালের নাম লিখুন';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 2. Category Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'বিভাগ / ক্যাটাগরি *',
                  prefixIcon: Icon(Icons.category_outlined),
                  border: OutlineInputBorder(),
                ),
                items: Asset.defaultCategories
                    .map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat),
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
                      decoration: const InputDecoration(
                        labelText: 'পরিমাণ *',
                        prefixIcon: Icon(Icons.pin_outlined),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'পরিমাণ দিন';
                        }
                        final parsed = int.tryParse(val.trim());
                        if (parsed == null || parsed < 0) {
                          return 'সঠিক সংখ্যা দিন';
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
                      decoration: const InputDecoration(
                        labelText: 'একক',
                        border: OutlineInputBorder(),
                      ),
                      items: Asset.defaultUnits
                          .map((u) => DropdownMenuItem(
                                value: u,
                                child: Text(u),
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
                decoration: const InputDecoration(
                  labelText: 'কোথায় রাখা আছে (অবস্থান) *',
                  hintText: 'যেমন: মাকতাবা রুম-১, উত্তর দেয়াল, বুকশেলফ-৩',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'দয়া করে মালামালের অবস্থান উল্লেখ করুন';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 5. Condition Segment
              const Text(
                'বর্তমান অবস্থা:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              SegmentedButton<AssetCondition>(
                segments: [
                  ButtonSegment(
                    value: AssetCondition.good,
                    label: const Text('ভালো'),
                    icon: const Icon(Icons.check_circle_outline),
                  ),
                  ButtonSegment(
                    value: AssetCondition.repairNeeded,
                    label: const Text('মেরামত প্রয়োজন'),
                    icon: const Icon(Icons.build_circle_outlined),
                  ),
                  ButtonSegment(
                    value: AssetCondition.damaged,
                    label: const Text('নষ্ট / বাতিল'),
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
              const Text(
                'সংগ্রহের ধরন:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              SegmentedButton<AcquisitionType>(
                segments: const [
                  ButtonSegment(
                    value: AcquisitionType.purchased,
                    label: Text('ক্রয়কৃত'),
                    icon: Icon(Icons.shopping_bag_outlined),
                  ),
                  ButtonSegment(
                    value: AcquisitionType.waqf,
                    label: Text('ওয়াকফ / দানকৃত'),
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
                      ? 'দাতার নাম / উৎস'
                      : 'ক্রয়ের উৎস / দোকানের নাম',
                  hintText: _selectedAcquisitionType == AcquisitionType.waqf
                      ? 'যেমন: আলহাজ্ব মাওলানা আব্দুর রহমান সাহেব'
                      : 'যেমন: স্টেডিয়াম মার্কেট, ঢাকা',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // 8. Cost (Optional)
              TextFormField(
                controller: _costController,
                decoration: const InputDecoration(
                  labelText: 'আনুমানিক মূল্য / খরচ (টাকা - ঐচ্ছিক)',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // 9. Remarks
              TextFormField(
                controller: _remarksController,
                decoration: const InputDecoration(
                  labelText: 'মন্তব্য / অতিরিক্ত বিবরণ (ঐচ্ছিক)',
                  hintText: 'মালামাল সংক্রান্ত কোনো বিশেষ দ্রষ্টব্য থাকলে লিখুন...',
                  prefixIcon: Icon(Icons.notes_outlined),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 28),

              // Save Button
              FilledButton.icon(
                onPressed: _saveAsset,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.save),
                label: Text(
                  isEdit ? 'আপডেট সংরক্ষণ করুন' : 'মালামাল যুক্ত করুন',
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
