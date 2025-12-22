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
      final currentFund = await txn.query(
          'funds', where: 'id = ?', whereArgs: [transaction.fundId]);
      if (currentFund.isNotEmpty) {
        double currentBalance = currentFund.first['balance'] as double;
        double newBalance;

        if (transaction.type == TransactionType.DEPOSIT) {
          newBalance =
              currentBalance + transaction.amount; // زيادة الرصيد عند الإيداع
        } else {
          newBalance =
              currentBalance - transaction.amount; // إنقاص الرصيد عند السحب
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
  Future<List<FundTransactionModel>> getAllTransactions({
    required int fundId,
    DateTime? from,
    DateTime? to,
    TransactionType? type,
  }) async {
    final db = await _dbService.database;

    List<String> whereClauses = ['fundId = ?'];
    List<dynamic> whereArgs = [fundId];

    if (from != null) {
      whereClauses.add('transactionDate >= ?');
      whereArgs.add(from.toIso8601String());
    }
    if (to != null) {
      final inclusiveTo = to.add(const Duration(days: 1));
      whereClauses.add('transactionDate < ?');
      whereArgs.add(inclusiveTo.toIso8601String());
    }
    if (type != null) {
      whereClauses.add('type = ?');
      whereArgs.add(type
          .toString()
          .split('.')
          .last);
    }

    final String whereStatement = whereClauses.join(' AND ');

    final List<Map<String, dynamic>> maps = await db.query(
      'fund_transactions',
      where: whereStatement,
      whereArgs: whereArgs,
      orderBy: 'transactionDate DESC',
    );

    if (maps.isEmpty) {
      return [];
    }
    return List.generate(
        maps.length, (i) => FundTransactionModel.fromMap(maps[i]));
  }

  Future<Map<String, double>> getTodaysSummary(int fundId) async {
    final db = await _dbService.database;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final result = await db.rawQuery('''
      SELECT SUM(CASE WHEN type = 'DEPOSIT' THEN amount ELSE 0 END) as totalDeposits,
        SUM(CASE WHEN type = 'WITHDRAWAL' THEN amount ELSE 0 END) as totalWithdrawals
      FROM fund_transactions
      WHERE fundId = ? AND transactionDate >= ? AND transactionDate < ?
    ''', [fundId, startOfDay.toIso8601String(), endOfDay.toIso8601String()]);

    final summary = result.first;
    return {
      'todaysDeposits': (summary['totalDeposits'] as num?)?.toDouble() ?? 0.0,
      'todaysWithdrawals': (summary['totalWithdrawals'] as num?)?.toDouble() ??
          0.0,
    };
  }

  // --- نهاية الإضافة ---


  /// دالة لجلب بيانات الصندوق الرئيسي (أو أي صندوق آخر)
  Future<FundModel?> getMainFund() async {
    final db = await _dbService.database;
    // نفترض أن الصندوق الرئيسي هو أول صندوق (ID = 1)
    final List<Map<String, dynamic>> maps = await db.query(
        'funds', where: 'id = ?', whereArgs: [1]);

    if (maps.isNotEmpty) {
      return FundModel.fromMap(maps.first);
    }
    return null; // في حالة عدم وجود الصندوق
  }


  // --- بداية الحل: الدالة الداخلية الجديدة ---
  /// دالة داخلية لتنفيذ المنطق. تتطلب transaction موجودة مسبقًا.
  /// هذا يمنع حدوث Deadlock.
  Future<void> addTransactionWithinTransaction(DatabaseExecutor txn,
      FundTransactionModel transaction) async {
    // 1. إضافة سجل الحركة الجديد
    await txn.insert(
      'fund_transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // 2. تحديث رصيد الصندوق
    final currentFund = await txn.query(
        'funds', where: 'id = ?', whereArgs: [transaction.fundId]);
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

  Future<Map<String, double>> getFundFlowSummary(
      {required DateTime from, required DateTime to}) async {
    final db = await _dbService.database;
    // إضافة يوم واحد لتاريخ النهاية ليشمل اليوم نفسه بالكامل
    final inclusiveTo = to.add(const Duration(days: 1));

    // استعلام يجلب مجموع الوارد ومجموع الصادر في مرة واحدة
    final result = await db.rawQuery('''
      SELECT 
        SUM(CASE WHEN type = 'DEPOSIT' THEN amount ELSE 0 END) as totalDeposits,
        SUM(CASE WHEN type = 'WITHDRAWAL' THEN amount ELSE 0 END) as totalWithdrawals
      FROM fund_transactions
      WHERE transactionDate >= ? AND transactionDate < ?
    ''', [from.toIso8601String(), inclusiveTo.toIso8601String()]);

    final summary = result.first;

    return {
      'totalDeposits': (summary['totalDeposits'] as num?)?.toDouble() ?? 0.0,
      'totalWithdrawals': (summary['totalWithdrawals'] as num?)?.toDouble() ??
          0.0,
    };
  }

  // --- بداية الإضافة: دالة جديدة لتجهيز بيانات تقرير حركة الصندوق ---
  Future<Map<String, dynamic>> generateFundFlowReportData({
    required int fundId,
    required DateTime from,
    required DateTime to,
  }) async {
    final db = await _dbService.database;
    final inclusiveTo = to.add(const Duration(days: 1));
    final fromString = from.toIso8601String();
    final toString = inclusiveTo.toIso8601String();

    // 1. حساب الرصيد الافتتاحي (رصيد الصندوق قبل تاريخ "من")
// --- بداية التعديل: فصل استعلامات حساب الرصيد الافتتاحي ---
// 1. جلب الرصيد الأولي للصندوق
    final fundData = await db.query('funds', where: 'id = ?', whereArgs: [fundId]);
    final double initialBalance = fundData.isNotEmpty
        ? (fundData.first['initialBalance'] as num?)?.toDouble() ?? 0.0
        : 0.0;
// 2. حساب صافي الحركات قبل تاريخ بداية التقرير
    final priorTransactionsResult = await db.rawQuery('''
  SELECT COALESCE(SUM(CASE WHEN type = 'DEPOSIT' THEN amount ELSE -amount END), 0) as netMovement
  FROM fund_transactions
  WHERE fundId = ? AND transactionDate < ?
''', [fundId, fromString]);
    final double priorNetMovement = (priorTransactionsResult.first['netMovement'] as num?)?.toDouble() ?? 0.0;

// 3. حساب الرصيد الافتتاحي الفعلي بجمع النتيجتين
    final double openingBalance = initialBalance + priorNetMovement;
// --- نهاية التعديل ---

    // 2. جلب كل الحركات خلال الفترة المحددة
    final transactions = await db.rawQuery('''
      SELECT *
      FROM fund_transactions
      WHERE fundId = ? AND transactionDate >= ? AND transactionDate < ?
      ORDER BY transactionDate ASC
    ''', [fundId, fromString, toString]);
    final List<FundTransactionModel> transactionModels =
    transactions.map((map) => FundTransactionModel.fromMap(map)).toList();

    // 3. حساب الملخصات (إجمالي الوارد والصادر) خلال الفترة
    double totalDeposits = 0.0;
    double totalWithdrawals = 0.0;
    for (var tx in transactionModels) {
      if (tx.type == TransactionType.DEPOSIT) {
        totalDeposits += tx.amount;
      } else {
        totalWithdrawals += tx.amount;
      }
    }

    return {
      'openingBalance': openingBalance,
      'transactions': transactionModels,
      'totalDeposits': totalDeposits,
      'totalWithdrawals': totalWithdrawals,
      'closingBalance': openingBalance + totalDeposits - totalWithdrawals,

  };
  }
// --- نهاية الإضافة ---
}