// File: lib/features/expenses/data/models/expense_model.dart

class ExpenseModel {
  final int? id;
  final int categoryId;
  final String? categoryName;
  final double amount;
  final DateTime expenseDate;
  final String? notes;
  // --- 1. بداية الإضافة: تعريف الخاصية الجديدة ---
  final bool deductFromFund;
  // --- نهاية الإضافة ---

  ExpenseModel({
    this.id,
    required this.categoryId,
    this.categoryName,
    required this.amount,
    required this.expenseDate,
    this.notes,
    // --- 2. بداية الإضافة: إضافة الخاصية إلى المُنشئ ---
    required this.deductFromFund,
    // --- نهاية الإضافة ---
  });

  // لتحويل البيانات من قاعدة البيانات إلى كائن
  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'],
      categoryId: map['categoryId'],
      categoryName: map['categoryName'],
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      expenseDate: DateTime.parse(map['expenseDate']),
      notes: map['notes'],
      // --- 3. بداية الإضافة: قراءة الخاصية من قاعدة البيانات ---
      // في SQLite، القيم المنطقية تُخزن عادة كـ 0 أو 1
      deductFromFund: map['deductFromFund'] == 1,
      // --- نهاية الإضافة ---
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
      // --- 4. بداية الإضافة: إضافة الخاصية إلى دالة الحفظ ---
      'deductFromFund': deductFromFund ? 1 : 0,
      // --- نهاية الإضافة ---
    };
  }
}
