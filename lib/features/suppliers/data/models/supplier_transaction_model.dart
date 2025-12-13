// File: lib/features/suppliers/data/models/supplier_transaction_model.dart

enum SupplierTransactionType { PAYMENT, OPENING_BALANCE, PURCHASE,RETURN }
class SupplierTransactionModel {
  final int? id; // رقم السند
  final int supplierId;
  final SupplierTransactionType type;
  final double amount;
  final String? notes;
  final DateTime transactionDate;
  final bool affectsFund;

  SupplierTransactionModel({
    this.id,
    required this.supplierId,
    required this.type,
    required this.amount,
    this.notes,
    required this.transactionDate,
    required this.affectsFund,
  });

  factory SupplierTransactionModel.fromMap(Map<String, dynamic> map) {
    return SupplierTransactionModel(
      id: map['id'],
      supplierId: map['supplierId'],
      type: map['type'] == 'PAYMENT'
          ? SupplierTransactionType.PAYMENT
          : SupplierTransactionType.OPENING_BALANCE,
      amount: map['amount'],
      notes: map['notes'],
      transactionDate: DateTime.parse(map['transactionDate']),
      affectsFund: map['affectsFund'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supplierId': supplierId,
      'type': type == SupplierTransactionType.PAYMENT ? 'PAYMENT' : 'OPENING_BALANCE',
      'amount': amount,
      'notes': notes,
      'transactionDate': transactionDate.toIso8601String(),
      'affectsFund': affectsFund ? 1 : 0,
    };
  }
}
