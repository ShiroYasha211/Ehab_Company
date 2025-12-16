// File: lib/features/expenses/data/models/expense_model.dart

class ExpenseModel {
  final int? id;
  final int categoryId;
  final String? categoryName; // سنحتاجه للعرض في القوائم
  final double amount;
  final DateTime expenseDate;
  final String? notes;

  ExpenseModel({
    this.id,
    required this.categoryId,
    this.categoryName,
    required this.amount,
    required this.expenseDate,
    this.notes,
  });

  // لتحويل البيانات من قاعدة البيانات إلى كائن
  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'],
      categoryId: map['categoryId'],
      categoryName: map['categoryName'], // قد يأتي من join
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      expenseDate: DateTime.parse(map['expenseDate']),
      notes: map['notes'],
    );
  }

  // لتحويل الكائن إلى Map لحفظه في قاعدة البيانات
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoryId': categoryId,
      'amount': amount,
      'expenseDate': expenseDate.toIso8601String(),
      'notes': notes,
    };
  }
}
