// File: lib/features/purchases/data/models/purchase_invoice_payment_model.dart

class PurchaseInvoicePaymentModel {
  final int? id;
  final int? invoiceId;
  final String method; // 'cash', 'transfer', 'bank'
  final double amount;
  final int? fundId; 
  
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

  PurchaseInvoicePaymentModel({
    this.id,
    this.invoiceId,
    required this.method,
    required this.amount,
    this.fundId,
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
      'fundId': fundId,
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

  factory PurchaseInvoicePaymentModel.fromMap(Map<String, dynamic> map) {
    return PurchaseInvoicePaymentModel(
      id: map['id'],
      invoiceId: map['invoiceId'],
      method: map['method'],
      amount: (map['amount'] as num).toDouble(),
      fundId: map['fundId'],
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
