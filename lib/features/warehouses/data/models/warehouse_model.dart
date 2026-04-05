// File: lib/features/warehouses/data/models/warehouse_model.dart

class WarehouseModel {
  final int? id;
  final String name;
  final String type; // 'main' or 'rep'
  final String? salesRepName;
  final String? salesRepPhone;
  final double creditLimit;
  final bool isActive;
  final DateTime createdAt;

  WarehouseModel({
    this.id,
    required this.name,
    this.type = 'main',
    this.salesRepName,
    this.salesRepPhone,
    this.creditLimit = 0.0,
    this.isActive = true,
    required this.createdAt,
  });

  bool get isMain => type == 'main';
  bool get isRep => type == 'rep';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'salesRepName': salesRepName,
      'salesRepPhone': salesRepPhone,
      'creditLimit': creditLimit,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory WarehouseModel.fromMap(Map<String, dynamic> map) {
    return WarehouseModel(
      id: map['id'],
      name: map['name'] ?? '',
      type: map['type'] ?? 'main',
      salesRepName: map['salesRepName'],
      salesRepPhone: map['salesRepPhone'],
      creditLimit: (map['creditLimit'] ?? 0.0).toDouble(),
      isActive: (map['isActive'] ?? 1) == 1,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  WarehouseModel copyWith({
    int? id,
    String? name,
    String? type,
    String? salesRepName,
    String? salesRepPhone,
    double? creditLimit,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return WarehouseModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      salesRepName: salesRepName ?? this.salesRepName,
      salesRepPhone: salesRepPhone ?? this.salesRepPhone,
      creditLimit: creditLimit ?? this.creditLimit,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
