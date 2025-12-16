// File: lib/features/expenses/data/repositories/expense_repository.dart

import 'package:ehab_company_admin/core/database/database_service.dart';
import 'package:ehab_company_admin/features/expenses/data/models/expense_category_model.dart';
import 'package:ehab_company_admin/features/expenses/data/models/expense_model.dart';
import 'package:sqflite/sqflite.dart';

class ExpenseRepository {
  final DatabaseService _dbService = DatabaseService();

  // --- دوال خاصة ببنود المصروفات (Categories) ---

  /// جلب كل بنود المصروفات
  Future<List<ExpenseCategoryModel>> getAllCategories() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps =
    await db.query('expense_categories', orderBy: 'name ASC');
    if (maps.isEmpty) return [];
    return List.generate(
        maps.length, (i) => ExpenseCategoryModel.fromMap(maps[i]));
  }

  /// إضافة بند مصروف جديد
  Future<int> addCategory(String name) async {
    final db = await _dbService.database;
    return await db.insert('expense_categories', {'name': name},
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  /// تعديل اسم بند مصروف
  Future<int> updateCategory(int id, String newName) async {
    final db = await _dbService.database;
    return await db.update('expense_categories', {'name': newName},
        where: 'id = ?', whereArgs: [id]);
  }

  /// حذف بند مصروف (سيتم رفضه إذا كان مستخدمًا)
  Future<int> deleteCategory(int id) async {
    final db = await _dbService.database;
    return await db.delete('expense_categories', where: 'id = ?', whereArgs: [id]);
  }


  // --- دوال خاصة بالمصروفات (Expenses) ---

  /// جلب كل المصروفات مع اسم البند الخاص بها
  Future<List<ExpenseModel>> getAllExpenses({DateTime? from, DateTime? to}) async {
    final db = await _dbService.database;

    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    if (from != null) {
      whereClauses.add('e.expenseDate >= ?');
      whereArgs.add(from.toIso8601String());
    }
    if (to != null) {
      whereClauses.add('e.expenseDate <= ?');
      whereArgs.add(to.toIso8601String());
    }

    final String whereStatement = whereClauses.isEmpty ? '' : 'WHERE ${whereClauses.join(' AND ')}';

    final String query = '''
      SELECT 
        e.*, 
        ec.name as categoryName 
      FROM expenses e
      JOIN expense_categories ec ON e.categoryId = ec.id
      $whereStatement
      ORDER BY e.expenseDate DESC
    ''';

    final List<Map<String, dynamic>> maps = await db.rawQuery(query, whereArgs);

    if (maps.isEmpty) return [];
    return List.generate(maps.length, (i) => ExpenseModel.fromMap(maps[i]));
  }

  /// إضافة مصروف جديد
  Future<int> addExpense(ExpenseModel expense, bool deductFromFund) async {
    final db = await _dbService.database;
    int expenseId = -1;

    await db.transaction((txn) async {
      // 1. إضافة سجل المصروف
      final dataToInsert = expense.toMap();
      dataToInsert.remove('id');
      expenseId = await txn.insert('expenses', dataToInsert);

      // 2. إذا كان مطلوبًا، قم بخصم المبلغ من الصندوق
      if (deductFromFund) {
        // جلب اسم البند لتسجيله في وصف حركة الصندوق
        final category = (await txn.query('expense_categories', where: 'id = ?', whereArgs: [expense.categoryId])).first;
        final categoryName = category['name'] as String;

        // إضافة حركة سحب إلى الصندوق
        await txn.insert('fund_transactions', {
          'fundId': 1, // الصندوق الرئيسي
          'type': 'WITHDRAWAL', // سحب
          'amount': expense.amount,
          'description': 'مصروف ($categoryName): ${expense.notes ?? ''}',
          'referenceId': expenseId,
          'transactionDate': expense.expenseDate.toIso8601String(),
        });

        // تحديث رصيد الصندوق
        await txn.rawUpdate(
          'UPDATE funds SET balance = balance - ? WHERE id = ?',
          [expense.amount, 1],
        );
      }
    });

    return expenseId;
  }
}
