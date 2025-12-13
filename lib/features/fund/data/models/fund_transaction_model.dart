// File: lib/features/fund/data/models/fund_transaction_model.dart

enum TransactionType { DEPOSIT, WITHDRAWAL }

class FundTransactionModel {
  final int? id;
  final int fundId;
  final TransactionType type;
  final double amount;
  final String description;
  final int? referenceId;
  final DateTime transactionDate;

  FundTransactionModel({
    this.id,
    required this.fundId,
    required this.type,
    required this.amount,
    required this.description,
    this.referenceId,
    required this.transactionDate,
  });

  factory FundTransactionModel.fromMap(Map<String, dynamic> map) {
    return FundTransactionModel(
      id: map['id'],
      fundId: map['fundId'],
      type: map['type'] == 'DEPOSIT' ? TransactionType.DEPOSIT : TransactionType.WITHDRAWAL,
      amount: map['amount'],
      description: map['description'],
      referenceId: map['referenceId'],
      transactionDate: DateTime.parse(map['transactionDate']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fundId': fundId,
      'type': type == TransactionType.DEPOSIT ? 'DEPOSIT' : 'WITHDRAWAL',
      'amount': amount,
      'description': description,
      'referenceId': referenceId,
      'transactionDate': transactionDate.toIso8601String(),
    };
  }
}
