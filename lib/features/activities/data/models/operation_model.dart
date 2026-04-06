// File: lib/features/activities/data/models/operation_model.dart

enum OperationType {
  sale,
  purchase,
  expense,
  transfer,
  settlement,
  returnSale,
  returnPurchase
}

class OperationModel {
  final int id;
  final DateTime date;
  final double amount;
  final OperationType type;
  final String? userName;
  final String? details;
  final String? referenceTable;
  final int? referenceId;

  OperationModel({
    required this.id,
    required this.date,
    required this.amount,
    required this.type,
    this.userName,
    this.details,
    this.referenceTable,
    this.referenceId,
  });

  // اسم العرض لنوع العملية باللغة العربية
  String get typeLabel {
    switch (type) {
      case OperationType.sale: return 'بيع';
      case OperationType.purchase: return 'شراء';
      case OperationType.expense: return 'مصروف';
      case OperationType.transfer: return 'تحويل مخزني';
      case OperationType.settlement: return 'تسوية عهدة';
      case OperationType.returnSale: return 'مرتجع بيع';
      case OperationType.returnPurchase: return 'مرتجع شراء';
    }
  }

  factory OperationModel.fromMap(Map<String, dynamic> map) {
    return OperationModel(
      id: map['id'],
      date: DateTime.parse(map['date']),
      amount: (map['amount'] as num).toDouble(),
      type: _parseType(map['category']),
      userName: map['userName'],
      details: map['details'],
      referenceTable: map['referenceTable'],
      referenceId: map['referenceId'],
    );
  }

  static OperationType _parseType(String category) {
    switch (category.toLowerCase()) {
      case 'sale': return OperationType.sale;
      case 'purchase': return OperationType.purchase;
      case 'expense': return OperationType.expense;
      case 'transfer': return OperationType.transfer;
      case 'settlement': return OperationType.settlement;
      case 'return_sale': return OperationType.returnSale;
      case 'return_purchase': return OperationType.returnPurchase;
      default: return OperationType.expense;
    }
  }
}
