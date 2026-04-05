// File: lib/features/fund/data/models/fund_model.dart

enum FundType { cash, bank, transfer }

class FundModel {
  final int id;
  final String name;
  final double balance;
  final FundType fundType;
  final String? bankName;
  final String? accountNumber;
  final bool isActive;
  final double initialBalance;

  FundModel({
    required this.id,
    required this.name,
    required this.balance,
    this.fundType = FundType.cash,
    this.bankName,
    this.accountNumber,
    this.isActive = true,
    this.initialBalance = 0.0,
  });

  factory FundModel.fromMap(Map<String, dynamic> map) {
    return FundModel(
      id: map['id'],
      name: map['name'],
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      fundType: _parseFundType(map['fundType']),
      bankName: map['bankName'],
      accountNumber: map['accountNumber'],
      isActive: (map['isActive'] as int?) == 1,
      initialBalance: (map['initialBalance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'fundType': fundType.name,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'isActive': isActive ? 1 : 0,
      'initialBalance': initialBalance,
    };
  }

  /// Map بدون id للإدراج
  Map<String, dynamic> toInsertMap() {
    return {
      'name': name,
      'balance': balance,
      'fundType': fundType.name,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'isActive': isActive ? 1 : 0,
      'initialBalance': initialBalance,
    };
  }

  FundModel copyWith({
    int? id,
    String? name,
    double? balance,
    FundType? fundType,
    String? bankName,
    String? accountNumber,
    bool? isActive,
    double? initialBalance,
  }) {
    return FundModel(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      fundType: fundType ?? this.fundType,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      isActive: isActive ?? this.isActive,
      initialBalance: initialBalance ?? this.initialBalance,
    );
  }

  static FundType _parseFundType(String? type) {
    switch (type) {
      case 'bank':
        return FundType.bank;
      case 'transfer':
        return FundType.transfer;
      default:
        return FundType.cash;
    }
  }

  String get displayIcon {
    switch (fundType) {
      case FundType.cash:
        return '💵';
      case FundType.bank:
        return '🏦';
      case FundType.transfer:
        return '📨';
    }
  }
}
