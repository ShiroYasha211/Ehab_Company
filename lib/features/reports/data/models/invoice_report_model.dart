// File: lib/features/reports/data/models/invoice_report_model.dart

// Enum لتحديد نوع الفاتورة في الفلتر والنموذج
enum InvoiceTypeFilter { all, sales, purchases }

// Enum لتحديد حالة الدفع في الفلتر والنموذج
enum PaymentStatusFilter { all, paid, due }

class InvoiceReportModel {
  final String invoiceType; // 'SALE' or 'PURCHASE'
  final int id;
  final DateTime invoiceDate;
  final double totalAmount;
  final double remainingAmount;
  final String partyName; // اسم العميل أو المورد

  InvoiceReportModel({
    required this.invoiceType,
    required this.id,
    required this.invoiceDate,
    required this.totalAmount,
    required this.remainingAmount,
    required this.partyName,
  });

  factory InvoiceReportModel.fromMap(Map<String, dynamic> map) {
    return InvoiceReportModel(
      invoiceType: map['invoiceType'],
      id: map['id'],
      invoiceDate: DateTime.parse(map['invoiceDate']),
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (map['remainingAmount'] as num?)?.toDouble() ?? 0.0,
      partyName: map['partyName'] ?? 'غير محدد',
    );
  }
}
