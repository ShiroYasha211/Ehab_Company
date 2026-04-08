class CustodyProductSummary {
  final int productId;
  final String productName;
  final String? productCode;
  final int? unitId;
  final List<int>? allowedUnitIds;
  final double quantity;
  final double currentValue;
  final int layerCount;

  const CustodyProductSummary({
    required this.productId,
    required this.productName,
    this.productCode,
    this.unitId,
    this.allowedUnitIds,
    required this.quantity,
    required this.currentValue,
    required this.layerCount,
  });

  factory CustodyProductSummary.fromMap(Map<String, dynamic> map) {
    return CustodyProductSummary(
      productId: map['productId'] as int,
      productName: map['productName'] as String? ?? '',
      productCode: map['productCode'] as String?,
      unitId: map['unitId'] as int?,
      allowedUnitIds: map['allowedUnits'] != null
          ? (map['allowedUnits'] as String)
                .split(',')
                .where((e) => e.isNotEmpty)
                .map(int.parse)
                .toList()
          : null,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      currentValue: (map['currentValue'] as num?)?.toDouble() ?? 0.0,
      layerCount: (map['layerCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class CustodyLayerModel {
  final int transferItemId;
  final int transferId;
  final int productId;
  final String productName;
  final String? productCode;
  final int? unitId;
  final double remainingQty;
  final double salePricePerBaseUnit;
  final DateTime transferDate;

  const CustodyLayerModel({
    required this.transferItemId,
    required this.transferId,
    required this.productId,
    required this.productName,
    this.productCode,
    this.unitId,
    required this.remainingQty,
    required this.salePricePerBaseUnit,
    required this.transferDate,
  });

  factory CustodyLayerModel.fromMap(Map<String, dynamic> map) {
    return CustodyLayerModel(
      transferItemId: map['transferItemId'] as int,
      transferId: map['transferId'] as int,
      productId: map['productId'] as int,
      productName: map['productName'] as String? ?? '',
      productCode: map['productCode'] as String?,
      unitId: map['unitId'] as int?,
      remainingQty: (map['remainingQty'] as num?)?.toDouble() ?? 0.0,
      salePricePerBaseUnit:
          (map['salePricePerBaseUnit'] as num?)?.toDouble() ?? 0.0,
      transferDate: DateTime.parse(map['transferDate'] as String),
    );
  }
}

class CustodySettlementModel {
  final int? id;
  final int warehouseId;
  final double totalSoldValue;
  final double receivedAmount;
  final double settlementDifference;
  final double previousBalance;
  final double newBalance;
  final String? paymentMethod;
  final int? fundId;
  final String? notes;
  final DateTime settlementDate;
  final DateTime createdAt;
  final String? warehouseName;

  const CustodySettlementModel({
    this.id,
    required this.warehouseId,
    required this.totalSoldValue,
    required this.receivedAmount,
    required this.settlementDifference,
    required this.previousBalance,
    required this.newBalance,
    this.paymentMethod,
    this.fundId,
    this.notes,
    required this.settlementDate,
    required this.createdAt,
    this.warehouseName,
  });

  factory CustodySettlementModel.fromMap(Map<String, dynamic> map) {
    return CustodySettlementModel(
      id: map['id'] as int?,
      warehouseId: map['warehouseId'] as int,
      totalSoldValue: (map['totalSoldValue'] as num?)?.toDouble() ?? 0.0,
      receivedAmount: (map['receivedAmount'] as num?)?.toDouble() ?? 0.0,
      settlementDifference:
          (map['settlementDifference'] as num?)?.toDouble() ?? 0.0,
      previousBalance: (map['previousBalance'] as num?)?.toDouble() ?? 0.0,
      newBalance: (map['newBalance'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['paymentMethod'] as String?,
      fundId: map['fundId'] as int?,
      notes: map['notes'] as String?,
      settlementDate: DateTime.parse(map['settlementDate'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
      warehouseName: map['warehouseName'] as String?,
    );
  }
}

class CustodySettlementItemModel {
  final int? id;
  final int settlementId;
  final int? transferItemId;
  final int? transferId;
  final int productId;
  final String productName;
  final double availableQty;
  final double soldQty;
  final double returnedQty;
  final double remainingQty;
  final double salePricePerBaseUnit;
  final double soldValue;
  final DateTime? transferDate;

  const CustodySettlementItemModel({
    this.id,
    required this.settlementId,
    this.transferItemId,
    this.transferId,
    required this.productId,
    required this.productName,
    required this.availableQty,
    required this.soldQty,
    required this.returnedQty,
    required this.remainingQty,
    required this.salePricePerBaseUnit,
    required this.soldValue,
    this.transferDate,
  });

  factory CustodySettlementItemModel.fromMap(Map<String, dynamic> map) {
    return CustodySettlementItemModel(
      id: map['id'] as int?,
      settlementId: map['settlementId'] as int,
      transferItemId: map['transferItemId'] as int?,
      transferId: map['transferId'] as int?,
      productId: map['productId'] as int,
      productName: map['productName'] as String? ?? '',
      availableQty: (map['availableQty'] as num?)?.toDouble() ?? 0.0,
      soldQty: (map['soldQty'] as num?)?.toDouble() ?? 0.0,
      returnedQty: (map['returnedQty'] as num?)?.toDouble() ?? 0.0,
      remainingQty: (map['remainingQty'] as num?)?.toDouble() ?? 0.0,
      salePricePerBaseUnit:
          (map['salePricePerBaseUnit'] as num?)?.toDouble() ?? 0.0,
      soldValue: (map['soldValue'] as num?)?.toDouble() ?? 0.0,
      transferDate: map['transferDate'] != null
          ? DateTime.parse(map['transferDate'] as String)
          : null,
    );
  }
}

class WarehouseDashboardModel {
  final int warehouseId;
  final double currentQty;
  final double currentValue;
  final int productCount;
  final DateTime? lastTransferDate;
  final DateTime? lastSettlementDate;

  const WarehouseDashboardModel({
    required this.warehouseId,
    required this.currentQty,
    required this.currentValue,
    required this.productCount,
    this.lastTransferDate,
    this.lastSettlementDate,
  });
}
