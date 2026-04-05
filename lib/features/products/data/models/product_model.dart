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
  final int? unitId;          // <-- تم التعديل من String إلى int
  final DateTime? productionDate;// <-- إضافة جديدة
  final DateTime? expiryDate;  // <-- إضافة جديدة
  final double minStockLevel;
  final List<int>? allowedUnits; // وحدات البيع المسموح بها (قائمة بالـ IDs)
  final bool isSalesStopped;   // <-- إضافة ميزة إيقاف البيع
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
    this.unitId,
    this.productionDate,
    this.expiryDate,
    required this.minStockLevel,
    this.allowedUnits,
    this.isSalesStopped = false, // القيمة الافتراضية
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
      'unitId': unitId,
      'productionDate': productionDate?.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'minStockLevel': minStockLevel,
      'allowedUnits': allowedUnits?.join(','), // حفظ القائمة كنص مفصول بفاصلة لـ SQLite
      'isSalesStopped': isSalesStopped ? 1 : 0, // حفظ كـ integer في SQLite
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
      quantity: (map['quantity'] ?? 0.0).toDouble(),
      purchasePrice: (map['purchasePrice'] ?? 0.0).toDouble(),
      salePrice: (map['salePrice'] ?? 0.0).toDouble(),
      imageUrl: map['imageUrl'],
      category: map['category'],
      unitId: map['unitId'],
      productionDate: map['productionDate'] != null
          ? DateTime.parse(map['productionDate'])
          : null,
      expiryDate: map['expiryDate'] != null
          ? DateTime.parse(map['expiryDate'])
          : null,
      minStockLevel: (map['minStockLevel'] ?? 0.0).toDouble(),
      allowedUnits: map['allowedUnits'] != null 
          ? (map['allowedUnits'] as String).split(',').where((e) => e.isNotEmpty).map(int.parse).toList() 
          : null,
      isSalesStopped: (map['isSalesStopped'] ?? 0) == 1,
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
