// File: lib/features/sales/data/models/sales_invoice_model.dart

import 'sales_invoice_payment_model.dart';

class SalesInvoiceModel {
  final int? id;
  final int? customerId;
  final double totalAmount;
  final double discountAmount;
  final double paidAmount;
  final double remainingAmount;
  final DateTime invoiceDate;
  final String? notes;
  final String status;
  final String? issuedBy;
  final List<SalesInvoicePaymentModel>? payments;

  SalesInvoiceModel({
    this.id,
    this.customerId,
    required this.totalAmount,
    required this.discountAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.invoiceDate,
    this.notes,
    this.status = 'COMPLETED',
    this.issuedBy,
    this.payments,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'totalAmount': totalAmount,
      'discountAmount': discountAmount,
      'paidAmount': paidAmount,
      'remainingAmount': remainingAmount,
      'invoiceDate': invoiceDate.toIso8601String(),
      'notes': notes,
      'status': status,
      'issuedBy': issuedBy,
    };
  }

  factory SalesInvoiceModel.fromMap(Map<String, dynamic> map) {
    return SalesInvoiceModel(
      id: map['id'],
      customerId: map['customerId'],
      totalAmount: (map['totalAmount'] as num).toDouble(),
      discountAmount: (map['discountAmount'] as num).toDouble(),
      paidAmount: (map['paidAmount'] as num).toDouble(),
      remainingAmount: (map['remainingAmount'] as num).toDouble(),
      invoiceDate: DateTime.parse(map['invoiceDate']),
      notes: map['notes'],
      status: map['status'],
      issuedBy: map['issuedBy'],
    );
  }
}
