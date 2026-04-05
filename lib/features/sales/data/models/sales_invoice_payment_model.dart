// File: lib/features/sales/data/models/sales_invoice_payment_model.dart

class SalesInvoicePaymentModel {
  final int? id;
  final int? invoiceId;
  final String method; // 'cash', 'transfer', 'bank'
  final double amount;
  
  // بيانات الحوالة
  final String? transferNumber;
  final String? senderName;
  final String? transferCompany;
  final String? transferImage;
  
  // بيانات البنك
  final String? bankName;
  final String? bankReference;
  final String? bankImage;
  
  final String? notes;
  final DateTime createdAt;

  SalesInvoicePaymentModel({
    this.id,
    this.invoiceId,
    required this.method,
    required this.amount,
    this.transferNumber,
    this.senderName,
    this.transferCompany,
    this.transferImage,
    this.bankName,
    this.bankReference,
    this.bankImage,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceId': invoiceId,
      'method': method,
      'amount': amount,
      'transferNumber': transferNumber,
      'senderName': senderName,
      'transferCompany': transferCompany,
      'transferImage': transferImage,
      'bankName': bankName,
      'bankReference': bankReference,
      'bankImage': bankImage,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SalesInvoicePaymentModel.fromMap(Map<String, dynamic> map) {
    return SalesInvoicePaymentModel(
      id: map['id'],
      invoiceId: map['invoiceId'],
      method: map['method'],
      amount: (map['amount'] as num).toDouble(),
      transferNumber: map['transferNumber'],
      senderName: map['senderName'],
      transferCompany: map['transferCompany'],
      transferImage: map['transferImage'],
      bankName: map['bankName'],
      bankReference: map['bankReference'],
      bankImage: map['bankImage'],
      notes: map['notes'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
