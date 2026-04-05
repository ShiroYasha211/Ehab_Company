// File: lib/features/sales/data/models/sales_invoice_item_model.dart

class SalesInvoiceItemModel {
  final int? id;
  final int invoiceId;
  final int productId;
  final String productName;
  final double quantity;
  final double freeQuantity;
  final String? unit; // نص الوحدة (مثلاً: قطعة)
  final double salePrice;
  final double purchasePrice; // سعر الشراء وقت البيع
  final int? unitId; // المعرف الرقمي للوحدة
  final double totalPrice;

  SalesInvoiceItemModel({
    this.id,
    required this.invoiceId,
    required this.productId,
    required this.productName,
    required this.quantity,
    this.freeQuantity = 0.0,
    this.unit,
    required this.salePrice,
    required this.purchasePrice,
    this.unitId,
    required this.totalPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceId': invoiceId,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'freeQuantity': freeQuantity,
      'unit': unit,
      'salePrice': salePrice,
      'purchasePrice': purchasePrice,
      'unitId': unitId,
      'totalPrice': totalPrice,
    };
  }

  factory SalesInvoiceItemModel.fromMap(Map<String, dynamic> map) {
    return SalesInvoiceItemModel(
      id: map['id'],
      invoiceId: map['invoiceId'],
      productId: map['productId'],
      productName: map['productName'],
      quantity: (map['quantity'] as num).toDouble(),
      freeQuantity: (map['freeQuantity'] as num? ?? 0.0).toDouble(),
      unit: map['unit'],
      salePrice: (map['salePrice'] as num).toDouble(),
      purchasePrice: (map['purchasePrice'] as num? ?? 0.0).toDouble(),
      unitId: map['unitId'],
      totalPrice: (map['totalPrice'] as num).toDouble(),
    );
  }
}
