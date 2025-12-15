// File: lib/features/sales/data/models/sales_invoice_summary_model.dart

class SalesInvoiceSummaryModel {
  final int id;
  final String? customerName; // اسم العميل بدلاً من المورد
  final DateTime invoiceDate;
  final double totalAmount;
  final double remainingAmount;
  final String status;

  SalesInvoiceSummaryModel({
    required this.id,
    this.customerName,
    required this.invoiceDate,
    required this.totalAmount,
    required this.remainingAmount,
    required this.status,
  });

  factory SalesInvoiceSummaryModel.fromMap(Map<String, dynamic> map) {
    return SalesInvoiceSummaryModel(
      id: map['id'],
      customerName: map['customerName'],
      invoiceDate: DateTime.parse(map['invoiceDate']),
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (map['remainingAmount'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'COMPLETED',
    );
  }
}
