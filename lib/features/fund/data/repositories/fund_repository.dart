// File: lib/features/fund/data/repositories/fund_repository.dart

import 'package:ehab_company_admin/core/database/database_service.dart';
import 'package:ehab_company_admin/features/fund/data/models/fund_model.dart';
import 'package:ehab_company_admin/features/fund/data/models/fund_transaction_model.dart';
import 'package:sqflite/sqflite.dart';

class FundRepository {
  final DatabaseService _dbService = DatabaseService();

  /// دالة لإضافة حركة جديدة على الصندوق وتحديث رصيده
  Future<void> addTransaction(FundTransactionModel transaction) async {
    final db = await _dbService.database;

    // استخدام transaction لضمان تنفيذ العمليتين معًا أو فشلهما معًا
    await db.transaction((txn) async {
      // 1. إضافة سجل الحركة الجديد
      await txn.insert(
        'fund_transactions',
        transaction.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 2. تحديث رصيد الصندوق
      final currentFund = await txn.query('funds', where: 'id = ?', whereArgs: [transaction.fundId]);
      if (currentFund.isNotEmpty) {
        double currentBalance = currentFund.first['balance'] as double;
        double newBalance;

        if (transaction.type == TransactionType.DEPOSIT) {
          newBalance = currentBalance + transaction.amount; // زيادة الرصيد عند الإيداع
        } else {
          newBalance = currentBalance - transaction.amount; // إنقاص الرصيد عند السحب
        }

        await txn.update(
          'funds',
          {'balance': newBalance},
          where: 'id = ?',
          whereArgs: [transaction.fundId],
        );
      }
    });
  }

  /// دالة لجلب كل حركات الصندوق
  Future<List<FundTransactionModel>> getAllTransactions(int fundId) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'fund_transactions',
      where: 'fundId = ?',
      whereArgs: [fundId],
      orderBy: 'transactionDate DESC', // الأحدث أولاً
    );

    if (maps.isEmpty) {
      return [];
    }
    return List.generate(maps.length, (i) => FundTransactionModel.fromMap(maps[i]));
  }

  /// دالة لجلب بيانات الصندوق الرئيسي (أو أي صندوق آخر)
  Future<FundModel?> getMainFund() async {
    final db = await _dbService.database;
    // نفترض أن الصندوق الرئيسي هو أول صندوق (ID = 1)
    final List<Map<String, dynamic>> maps = await db.query('funds', where: 'id = ?', whereArgs: [1]);

    if (maps.isNotEmpty) {
      return FundModel.fromMap(maps.first);
    }
    return null; // في حالة عدم وجود الصندوق
  }

  // --- بداية الحل: الدالة الداخلية الجديدة ---
  /// دالة داخلية لتنفيذ المنطق. تتطلب transaction موجودة مسبقًا.
  /// هذا يمنع حدوث Deadlock.
  Future<void> addTransactionWithinTransaction(DatabaseExecutor txn, FundTransactionModel transaction) async {    // 1. إضافة سجل الحركة الجديد
    await txn.insert(
      'fund_transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // 2. تحديث رصيد الصندوق
    final currentFund = await txn.query('funds', where: 'id = ?', whereArgs: [transaction.fundId]);
    if (currentFund.isNotEmpty) {
      double currentBalance = currentFund.first['balance'] as double;
      double newBalance;

      if (transaction.type == TransactionType.DEPOSIT) {
        newBalance = currentBalance + transaction.amount;
      } else {
        newBalance = currentBalance - transaction.amount;
      }

      await txn.update(
        'funds',
        {'balance': newBalance},
        where: 'id = ?',
        whereArgs: [transaction.fundId],
      );
    }
  }
// --- نهاية الحل ---

  Future<double> getFundBalance(int fundId) async {
    final db = await _dbService.database;
    final result = await db.query(
      'funds',
      columns: ['balance'],
      where: 'id = ?',
      whereArgs: [fundId],
    );
    if (result.isNotEmpty) {
      return result.first['balance'] as double;
    }
    return 0.0;
  }


}
