// File: lib/features/expenses/data/models/expense_category_model.dart

class ExpenseCategoryModel {
  final int? id;
  final String name;

  ExpenseCategoryModel({
    this.id,
    required this.name,
  });

  // لتحويل البيانات من قاعدة البيانات إلى كائن
  factory ExpenseCategoryModel.fromMap(Map<String, dynamic> map) {
    return ExpenseCategoryModel(
      id: map['id'],
      name: map['name'],
    );
  }

  // لتحويل الكائن إلى Map لحفظه في قاعدة البيانات
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  // دالة لتسهيل عملية النسخ مع التعديل
  ExpenseCategoryModel copyWith({
    int? id,
    String? name,
  }) {
    return ExpenseCategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }
}
