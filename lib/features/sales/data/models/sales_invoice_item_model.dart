// File: lib/features/sales/data/models/sales_invoice_item_model.dart

class SalesInvoiceItemModel {
  final int? id;
  final int invoiceId;
  final int productId;
  final String productName;
  final double quantity;
  final double salePrice;
  final double totalPrice;

  SalesInvoiceItemModel({
    this.id,
    required this.invoiceId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.salePrice,
    required this.totalPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceId': invoiceId,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'salePrice': salePrice, // هنا نستخدم سعر البيع
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
      salePrice: (map['salePrice'] as num).toDouble(),
      totalPrice: (map['totalPrice'] as num).toDouble(),
    );
  }
}
