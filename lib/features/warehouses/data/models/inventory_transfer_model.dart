// File: lib/features/warehouses/data/models/inventory_transfer_model.dart

/// موديل سند التحويل المخزني (العُهدة)
class InventoryTransferModel {
  final int? id;
  final int sourceWarehouseId;
  final int destinationWarehouseId;
  final DateTime transferDate;
  final double totalValue; // إجمالي بسعر البيع
  final double totalCostValue; // إجمالي بسعر الشراء
  final String status; // COMPLETED / RETURNED
  final String? notes;
  final DateTime createdAt;

  // حقول مساعدة للعرض (تُجلب من JOIN)
  final String? sourceWarehouseName;
  final String? destinationWarehouseName;

  InventoryTransferModel({
    this.id,
    required this.sourceWarehouseId,
    required this.destinationWarehouseId,
    required this.transferDate,
    this.totalValue = 0.0,
    this.totalCostValue = 0.0,
    this.status = 'COMPLETED',
    this.notes,
    required this.createdAt,
    this.sourceWarehouseName,
    this.destinationWarehouseName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sourceWarehouseId': sourceWarehouseId,
      'destinationWarehouseId': destinationWarehouseId,
      'transferDate': transferDate.toIso8601String(),
      'totalValue': totalValue,
      'totalCostValue': totalCostValue,
      'status': status,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory InventoryTransferModel.fromMap(Map<String, dynamic> map) {
    return InventoryTransferModel(
      id: map['id'],
      sourceWarehouseId: map['sourceWarehouseId'],
      destinationWarehouseId: map['destinationWarehouseId'],
      transferDate: DateTime.parse(map['transferDate']),
      totalValue: (map['totalValue'] ?? 0.0).toDouble(),
      totalCostValue: (map['totalCostValue'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'COMPLETED',
      notes: map['notes'],
      createdAt: DateTime.parse(map['createdAt']),
      sourceWarehouseName: map['sourceWarehouseName'],
      destinationWarehouseName: map['destinationWarehouseName'],
    );
  }
}

/// موديل تفاصيل صنف واحد داخل سند التحويل
class InventoryTransferItemModel {
  final int? id;
  final int transferId;
  final int productId;
  final String productName;
  final double quantity;
  final int? unitId;
  final double salePrice;
  final double purchasePrice;
  final double totalSaleValue;
  final double totalCostValue;
  final double quantityInBaseUnit;
  final double remainingQuantityInBaseUnit;
  final double salePricePerBaseUnit;

  InventoryTransferItemModel({
    this.id,
    required this.transferId,
    required this.productId,
    required this.productName,
    required this.quantity,
    this.unitId,
    required this.salePrice,
    required this.purchasePrice,
    required this.totalSaleValue,
    required this.totalCostValue,
    this.quantityInBaseUnit = 0.0,
    this.remainingQuantityInBaseUnit = 0.0,
    this.salePricePerBaseUnit = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transferId': transferId,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitId': unitId,
      'salePrice': salePrice,
      'purchasePrice': purchasePrice,
      'totalSaleValue': totalSaleValue,
      'totalCostValue': totalCostValue,
      'quantityInBaseUnit': quantityInBaseUnit,
      'remainingQuantityInBaseUnit': remainingQuantityInBaseUnit,
      'salePricePerBaseUnit': salePricePerBaseUnit,
    };
  }

  factory InventoryTransferItemModel.fromMap(Map<String, dynamic> map) {
    return InventoryTransferItemModel(
      id: map['id'],
      transferId: map['transferId'],
      productId: map['productId'],
      productName: map['productName'] ?? '',
      quantity: (map['quantity'] ?? 0.0).toDouble(),
      unitId: map['unitId'],
      salePrice: (map['salePrice'] ?? 0.0).toDouble(),
      purchasePrice: (map['purchasePrice'] ?? 0.0).toDouble(),
      totalSaleValue: (map['totalSaleValue'] ?? 0.0).toDouble(),
      totalCostValue: (map['totalCostValue'] ?? 0.0).toDouble(),
      quantityInBaseUnit: (map['quantityInBaseUnit'] ?? 0.0).toDouble(),
      remainingQuantityInBaseUnit: (map['remainingQuantityInBaseUnit'] ?? 0.0)
          .toDouble(),
      salePricePerBaseUnit: (map['salePricePerBaseUnit'] ?? 0.0).toDouble(),
    );
  }
}
