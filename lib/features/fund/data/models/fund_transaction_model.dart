// File: lib/features/fund/data/models/fund_transaction_model.dart

enum TransactionType { DEPOSIT, WITHDRAWAL, TRANSFER }

class FundTransactionModel {
  final int? id;
  final int fundId;
  final TransactionType type;
  final double amount;
  final String description;
  final int? referenceId;
  final DateTime transactionDate;

  // حقول التحويل بين الصناديق
  final int? sourceFundId;
  final int? targetFundId;

  // حقول تفاصيل الحوالات والرسوم
  final String? transferCompany;
  final String? senderName;
  final String? receiverName;
  final String? transferNumber;
  final String? referenceType;
  
  // حقول جديدة للإصدار V16 + V26
  final double fees;
  final String? attachmentPath;
  final String? bankName;
  final String? bankReference;
  final String? notes;

  FundTransactionModel({
    this.id,
    required this.fundId,
    required this.type,
    required this.amount,
    required this.description,
    this.referenceId,
    required this.transactionDate,
    this.sourceFundId,
    this.targetFundId,
    this.transferCompany,
    this.senderName,
    this.receiverName,
    this.transferNumber,
    this.referenceType,
    this.fees = 0.0,
    this.attachmentPath,
    this.bankName,
    this.bankReference,
    this.notes,
  });

  factory FundTransactionModel.fromMap(Map<String, dynamic> map) {
    return FundTransactionModel(
      id: map['id'],
      fundId: map['fundId'],
      type: _parseType(map['type']),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      description: map['description'] ?? '',
      referenceId: map['referenceId'],
      transactionDate: DateTime.parse(map['transactionDate']),
      sourceFundId: map['sourceFundId'],
      targetFundId: map['targetFundId'],
      transferCompany: map['transferCompany'],
      senderName: map['senderName'],
      receiverName: map['receiverName'],
      transferNumber: map['transferNumber'],
      referenceType: map['referenceType'],
      fees: (map['fees'] as num?)?.toDouble() ?? 0.0,
      attachmentPath: map['attachmentPath'],
      bankName: map['bankName'],
      bankReference: map['bankReference'],
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fundId': fundId,
      'type': type.name,
      'amount': amount,
      'description': description,
      'referenceId': referenceId,
      'transactionDate': transactionDate.toIso8601String(),
      'sourceFundId': sourceFundId,
      'targetFundId': targetFundId,
      'transferCompany': transferCompany,
      'senderName': senderName,
      'receiverName': receiverName,
      'transferNumber': transferNumber,
      'referenceType': referenceType,
      'fees': fees,
      'attachmentPath': attachmentPath,
      'bankName': bankName,
      'bankReference': bankReference,
      'notes': notes,
    };
  }

  static TransactionType _parseType(String? type) {
    switch (type) {
      case 'DEPOSIT':
        return TransactionType.DEPOSIT;
      case 'WITHDRAWAL':
        return TransactionType.WITHDRAWAL;
      case 'TRANSFER':
        return TransactionType.TRANSFER;
      default:
        return TransactionType.DEPOSIT;
    }
  }

  FundTransactionModel copyWith({
    int? id,
    int? fundId,
    TransactionType? type,
    double? amount,
    String? description,
    int? referenceId,
    DateTime? transactionDate,
    int? sourceFundId,
    int? targetFundId,
    String? transferCompany,
    String? senderName,
    String? receiverName,
    String? transferNumber,
    String? referenceType,
    double? fees,
    String? attachmentPath,
    String? bankName,
    String? bankReference,
    String? notes,
  }) {
    return FundTransactionModel(
      id: id ?? this.id,
      fundId: fundId ?? this.fundId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      referenceId: referenceId ?? this.referenceId,
      transactionDate: transactionDate ?? this.transactionDate,
      sourceFundId: sourceFundId ?? this.sourceFundId,
      targetFundId: targetFundId ?? this.targetFundId,
      transferCompany: transferCompany ?? this.transferCompany,
      senderName: senderName ?? this.senderName,
      receiverName: receiverName ?? this.receiverName,
      transferNumber: transferNumber ?? this.transferNumber,
      referenceType: referenceType ?? this.referenceType,
      fees: fees ?? this.fees,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      bankName: bankName ?? this.bankName,
      bankReference: bankReference ?? this.bankReference,
      notes: notes ?? this.notes,
    );
  }
}
