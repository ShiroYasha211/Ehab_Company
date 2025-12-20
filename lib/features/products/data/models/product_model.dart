// File: lib/features/products/data/models/product_model.dart

class ProductModel {
  final int? id;
  final String name;
  final String? code;
  final String? description;
  final double quantity;
  final double purchasePrice;
  final double salePrice;
  final String? imageUrl;
  final String? category;      // <-- إضافة جديدة
  final String? unit;          // <-- إضافة جديدة
  final DateTime? productionDate;// <-- إضافة جديدة
  final DateTime? expiryDate;  // <-- إضافة جديدة
  final double minStockLevel; // <-- إضافة جديدة
  final DateTime createdAt;

  ProductModel({
    this.id,
    required this.name,
    this.code,
    this.description,
    required this.quantity,
    required this.purchasePrice,
    required this.salePrice,
    this.imageUrl,
    this.category,
    this.unit,
    this.productionDate,
    this.expiryDate,
    required this.minStockLevel, // <-- إضافة جديدة
    required this.createdAt,
  });

  // تحديث toMap()
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'description': description,
      'quantity': quantity,
      'purchasePrice': purchasePrice,
      'salePrice': salePrice,
      'imageUrl': imageUrl,
      'category': category,
      'unit': unit,
      'productionDate': productionDate?.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'minStockLevel': minStockLevel, // <-- إضافة جديدة
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // تحديث fromMap()
  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'],
      name: map['name'],
      code: map['code'],
      description: map['description'],
      quantity: map['quantity'],
      purchasePrice: map['purchasePrice'],
      salePrice: map['salePrice'],
      imageUrl: map['imageUrl'],
      category: map['category'],
      unit: map['unit'],
      productionDate: map['productionDate'] != null ? DateTime.parse(map['productionDate']) : null,
      expiryDate: map['expiryDate'] != null ? DateTime.parse(map['expiryDate']) : null,
      minStockLevel: map['minStockLevel'] ?? 0.0, // <-- إضافة جديدة
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
  bool get isExpired {
    final now = DateTime.now();
    // يعتبر منتهيًا إذا كان تاريخ الانتهاء هو الأمس أو قبل ذلك
    return expiryDate != null && expiryDate!.isBefore(DateTime(now.year, now.month, now.day));
  }

  bool get isExpiringSoon {
    final now = DateTime.now();
    // يعتبر قريبًا من الانتهاء إذا كان تاريخ الانتهاء خلال الـ 30 يومًا القادمة
    return expiryDate != null &&
        !isExpired &&
        expiryDate!.isBefore(now.add(const Duration(days: 30)));
  }
}
