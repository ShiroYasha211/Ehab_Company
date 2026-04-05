// File: lib/features/warehouses/data/models/settlement_model.dart

class SettlementModel {
  final int? id;
  final int warehouseId;
  final double totalSales;
  final double totalReturned;
  final double totalCredit;
  final double amountPaid;
  final double deficit;
  final DateTime settlementDate;
  final String? notes;
  final String? paymentMethod;
  final int? fundId;
  final bool isStockCleared;
  final bool isCreditToCustomers;
  final DateTime createdAt;

  SettlementModel({
    this.id,
    required this.warehouseId,
    required this.totalSales,
    required this.totalReturned,
    required this.totalCredit,
    required this.amountPaid,
    this.deficit = 0.0,
    required this.settlementDate,
    this.notes,
    this.paymentMethod,
    this.fundId,
    this.isStockCleared = false,
    this.isCreditToCustomers = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'warehouseId': warehouseId,
      'totalSales': totalSales,
      'totalReturned': totalReturned,
      'totalCredit': totalCredit,
      'amountPaid': amountPaid,
      'deficit': deficit,
      'settlementDate': settlementDate.toIso8601String(),
      'notes': notes,
      'paymentMethod': paymentMethod,
      'fundId': fundId,
      'isStockCleared': isStockCleared ? 1 : 0,
      'isCreditToCustomers': isCreditToCustomers ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SettlementModel.fromMap(Map<String, dynamic> map) {
    return SettlementModel(
      id: map['id'],
      warehouseId: map['warehouseId'],
      totalSales: (map['totalSales'] ?? 0.0).toDouble(),
      totalReturned: (map['totalReturned'] ?? 0.0).toDouble(),
      totalCredit: (map['totalCredit'] ?? 0.0).toDouble(),
      amountPaid: (map['amountPaid'] ?? 0.0).toDouble(),
      deficit: (map['deficit'] ?? 0.0).toDouble(),
      settlementDate: DateTime.parse(map['settlementDate']),
      notes: map['notes'],
      paymentMethod: map['paymentMethod'],
      fundId: map['fundId'],
      isStockCleared: (map['isStockCleared'] ?? 0) == 1,
      isCreditToCustomers: (map['isCreditToCustomers'] ?? 0) == 1,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}

class SettlementItemModel {
  final int? id;
  final int settlementId;
  final int productId;
  final String? productName;
  final double initialQty;
  final double soldQty;
  final double returnedQty;
  final int? unitId;
  final double salePrice;

  SettlementItemModel({
    this.id,
    required this.settlementId,
    required this.productId,
    this.productName,
    required this.initialQty,
    required this.soldQty,
    required this.returnedQty,
    this.unitId,
    required this.salePrice,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'settlementId': settlementId,
      'productId': productId,
      'initialQty': initialQty,
      'soldQty': soldQty,
      'returnedQty': returnedQty,
      'unitId': unitId,
      'salePrice': salePrice,
    };
  }

  factory SettlementItemModel.fromMap(Map<String, dynamic> map) {
    return SettlementItemModel(
      id: map['id'],
      settlementId: map['settlementId'],
      productId: map['productId'],
      productName: map['productName'], // قد يأتي من Join
      initialQty: (map['initialQty'] ?? 0.0).toDouble(),
      soldQty: (map['soldQty'] ?? 0.0).toDouble(),
      returnedQty: (map['returnedQty'] ?? 0.0).toDouble(),
      unitId: map['unitId'],
      salePrice: (map['salePrice'] ?? 0.0).toDouble(),
    );
  }
}

class WarehouseTransactionModel {
  final int? id;
  final int warehouseId;
  final String type;
  final double amount;
  final String? notes;
  final DateTime transactionDate;
  final int? referenceId;

  WarehouseTransactionModel({
    this.id,
    required this.warehouseId,
    required this.type,
    required this.amount,
    this.notes,
    required this.transactionDate,
    this.referenceId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'warehouseId': warehouseId,
      'type': type,
      'amount': amount,
      'notes': notes,
      'transactionDate': transactionDate.toIso8601String(),
      'referenceId': referenceId,
    };
  }

  factory WarehouseTransactionModel.fromMap(Map<String, dynamic> map) {
    return WarehouseTransactionModel(
      id: map['id'],
      warehouseId: map['warehouseId'],
      type: map['type'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      notes: map['notes'],
      transactionDate: DateTime.parse(map['transactionDate']),
      referenceId: map['referenceId'],
    );
  }
}
