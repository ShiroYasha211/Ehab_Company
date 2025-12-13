// File: lib/features/purchases/data/models/purchase_invoice_summary_model.dart

class PurchaseInvoiceSummaryModel {
  final int id;
  final String? supplierName;
  final DateTime invoiceDate;
  final double totalAmount;
  final double remainingAmount;
  final String status; // <-- إضافة جديدة

  PurchaseInvoiceSummaryModel({
    required this.id,
    this.supplierName,
    required this.invoiceDate,
    required this.totalAmount,
    required this.remainingAmount,
    required this.status, // <-- إضافة جديدة
  });

  factory PurchaseInvoiceSummaryModel.fromMap(Map<String, dynamic> map) {
    return PurchaseInvoiceSummaryModel(
      id: map['id'],
      supplierName: map['supplierName'],
      invoiceDate: DateTime.parse(map['invoiceDate']),
      totalAmount: map['totalAmount'] ?? 0.0,
      remainingAmount: map['remainingAmount'] ?? 0.0,
      status: map['status'] ?? 'COMPLETED', // <-- إضافة جديدة
    );
  }
}
