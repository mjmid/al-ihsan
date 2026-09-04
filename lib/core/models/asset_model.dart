/// ---------------------------------------------------------------------------
/// asset_model.dart
/// ---------------------------------------------------------------------------
/// Data model for non-book library assets, furniture, electronics, and supplies.
/// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';

enum AssetCondition {
  good,
  repairNeeded,
  damaged;

  String get label {
    switch (this) {
      case AssetCondition.good:
        return 'ভালো';
      case AssetCondition.repairNeeded:
        return 'মেরামত প্রয়োজন';
      case AssetCondition.damaged:
        return 'নষ্ট / বাতিল';
    }
  }

  Color get color {
    switch (this) {
      case AssetCondition.good:
        return Colors.green;
      case AssetCondition.repairNeeded:
        return Colors.amber.shade700;
      case AssetCondition.damaged:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case AssetCondition.good:
        return Icons.check_circle_outline;
      case AssetCondition.repairNeeded:
        return Icons.build_circle_outlined;
      case AssetCondition.damaged:
        return Icons.cancel_outlined;
    }
  }

  static AssetCondition fromString(String? val) {
    if (val == null) return AssetCondition.good;
    final lower = val.toLowerCase().trim();
    if (lower == 'repairneeded' || lower.contains('repair') || lower.contains('মেরামত')) {
      return AssetCondition.repairNeeded;
    }
    if (lower == 'damaged' || lower.contains('নষ্ট') || lower.contains('বাতিল')) {
      return AssetCondition.damaged;
    }
    return AssetCondition.good;
  }
}

enum AcquisitionType {
  purchased,
  waqf;

  String get label {
    switch (this) {
      case AcquisitionType.purchased:
        return 'ক্রয়কৃত';
      case AcquisitionType.waqf:
        return 'ওয়াকফ / দানকৃত';
    }
  }

  static AcquisitionType fromString(String? val) {
    if (val == null) return AcquisitionType.purchased;
    final lower = val.toLowerCase().trim();
    if (lower == 'waqf' || lower.contains('দান') || lower.contains('ওয়াকফ')) {
      return AcquisitionType.waqf;
    }
    return AcquisitionType.purchased;
  }
}

class Asset {
  final String assetId;
  final String name;
  final String category;
  final int quantity;
  final String unit;
  final String location;
  final AssetCondition condition;
  final AcquisitionType acquisitionType;
  final String? donorOrSource;
  final double? cost;
  final DateTime? purchaseDate;
  final String? remarks;
  final DateTime lastUpdated;

  const Asset({
    required this.assetId,
    required this.name,
    required this.category,
    this.quantity = 1,
    this.unit = 'টি',
    required this.location,
    this.condition = AssetCondition.good,
    this.acquisitionType = AcquisitionType.purchased,
    this.donorOrSource,
    this.cost,
    this.purchaseDate,
    this.remarks,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() => {
        'asset_id': assetId,
        'name': name,
        'category': category,
        'quantity': quantity,
        'unit': unit,
        'location': location,
        'condition': condition.name,
        'acquisition_type': acquisitionType.name,
        'donor_or_source': donorOrSource,
        'cost': cost,
        'purchase_date': purchaseDate?.toIso8601String(),
        'remarks': remarks,
        'last_updated': lastUpdated.toIso8601String(),
      };

  factory Asset.fromMap(Map<String, dynamic> map) {
    return Asset(
      assetId: map['asset_id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      category: map['category']?.toString() ?? 'আসবাবপত্র',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      unit: map['unit']?.toString() ?? 'টি',
      location: map['location']?.toString() ?? '',
      condition: AssetCondition.fromString(map['condition']?.toString()),
      acquisitionType: AcquisitionType.fromString(map['acquisition_type']?.toString()),
      donorOrSource: map['donor_or_source']?.toString(),
      cost: (map['cost'] as num?)?.toDouble(),
      purchaseDate: map['purchase_date'] != null
          ? DateTime.tryParse(map['purchase_date'].toString())
          : null,
      remarks: map['remarks']?.toString(),
      lastUpdated: map['last_updated'] != null
          ? DateTime.tryParse(map['last_updated'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Asset copyWith({
    String? assetId,
    String? name,
    String? category,
    int? quantity,
    String? unit,
    String? location,
    AssetCondition? condition,
    AcquisitionType? acquisitionType,
    String? donorOrSource,
    double? cost,
    DateTime? purchaseDate,
    String? remarks,
    DateTime? lastUpdated,
  }) {
    return Asset(
      assetId: assetId ?? this.assetId,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      location: location ?? this.location,
      condition: condition ?? this.condition,
      acquisitionType: acquisitionType ?? this.acquisitionType,
      donorOrSource: donorOrSource ?? this.donorOrSource,
      cost: cost ?? this.cost,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      remarks: remarks ?? this.remarks,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  static const List<String> defaultCategories = [
    'আসবাবপত্র',
    'ইলেকট্রনিক্স ও প্রযুক্তি',
    'বই সংরক্ষণ ও বাঁধাই',
    'স্টেশনারি ও অফিস',
    'পরিচ্ছন্নতা ও অন্যান্য',
  ];

  static const List<String> defaultUnits = [
    'টি',
    'সেট',
    'জোড়া',
    'প্যাকেট',
    'রোল',
    'বক্স',
  ];
}
