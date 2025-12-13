// File: lib/features/fund/data/models/fund_model.dart

class FundModel {
  final int id;
  final String name;
  final double balance;FundModel({
    required this.id,
    required this.name,
    required this.balance,
  });

  factory FundModel.fromMap(Map<String, dynamic> map) {
    return FundModel(
      id: map['id'],
      name: map['name'],
      balance: map['balance'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
    };
  }
}
