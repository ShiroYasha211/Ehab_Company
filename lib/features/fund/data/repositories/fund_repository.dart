// File: lib/features/fund/data/repositories/fund_repository.dart

import 'package:ehab_company_admin/core/database/database_service.dart';
import 'package:ehab_company_admin/features/fund/data/models/fund_model.dart';
import 'package:ehab_company_admin/features/fund/data/models/fund_transaction_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:get/get.dart';
import '../../../../core/services/auth_service.dart';

class FundRepository {
  final DatabaseService _dbService = DatabaseService();

  // ==================== إدارة الصناديق ====================

  /// جلب كل الصناديق الفرعية (ما عدا main)
  Future<List<FundModel>> getAllSubFunds() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'funds',
      where: 'isActive = ?',
      whereArgs: [1],
      orderBy: 'id ASC',
    );
    return maps.map((m) => FundModel.fromMap(m)).toList();
  }

  /// جلب صندوق بالـ ID
  Future<FundModel?> getFundById(int id) async {
    final db = await _dbService.database;
    final maps = await db.query('funds', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return FundModel.fromMap(maps.first);
    return null;
  }

  /// حساب الرصيد الإجمالي (مجموع كل الصناديق النشطة)
  Future<double> getTotalBalance() async {
    final db = await _dbService.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(balance), 0) as total FROM funds WHERE isActive = 1',
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// إنشاء صندوق فرعي جديد (بنك أو حوالات)
  Future<int> createFund(FundModel fund) async {
    final db = await _dbService.database;
    return await db.insert('funds', fund.toInsertMap());
  }

  /// حذف صندوق نهائياً (فقط إذا لم يكن له حركات)
  Future<void> deleteFund(int id) async {
    final db = await _dbService.database;
    await db.delete('funds', where: 'id = ?', whereArgs: [id]);
  }

  /// تعطيل صندوق (إخفاءه من القائمة)
  Future<void> deactivateFund(int id) async {
    final db = await _dbService.database;
    await db.update('funds', {'isActive': 0}, where: 'id = ?', whereArgs: [id]);
  }

  /// التحقق مما إذا كان للصندوق حركات مالية
  Future<bool> hasTransactions(int fundId) async {
    final db = await _dbService.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM fund_transactions WHERE fundId = ?',
      [fundId],
    );
    return (result.first['count'] as int) > 0;
  }

  /// تحديث بيانات صندوق
  Future<void> updateFund(FundModel fund) async {
    final db = await _dbService.database;
    await db.update('funds', fund.toMap(), where: 'id = ?', whereArgs: [fund.id]);
  }

  /// جلب رصيد صندوق معين
  Future<double> getFundBalance(int fundId) async {
    final db = await _dbService.database;
    final result = await db.query('funds', columns: ['balance'], where: 'id = ?', whereArgs: [fundId]);
    if (result.isNotEmpty) return (result.first['balance'] as num?)?.toDouble() ?? 0.0;
    return 0.0;
  }

  // ==================== الحركات المالية ====================

  /// إضافة حركة على صندوق وتحديث رصيده
  Future<void> addTransaction(FundTransactionModel transaction) async {
    final db = await _dbService.database;
    await db.transaction((txn) async {
      await _executeTransaction(txn, transaction);
    });
  }

  /// تنفيذ حركة داخل transaction موجودة (لمنع Deadlock)
  Future<void> addTransactionWithinTransaction(
      DatabaseExecutor txn, FundTransactionModel transaction) async {
    await _executeTransaction(txn, transaction);
  }

  /// المنطق الداخلي لتنفيذ الحركة
  Future<void> _executeTransaction(
      DatabaseExecutor txn, FundTransactionModel transaction) async {
    // 1. جلب الرصيد الحالي للصندوق
    final currentFund = await txn.query('funds', where: 'id = ?', whereArgs: [transaction.fundId]);
    if (currentFund.isNotEmpty) {
      double currentBalance = (currentFund.first['balance'] as num?)?.toDouble() ?? 0.0;
      
      // المعادلة: 
      // في الإيداع: الرصيد الجديد = القديم + المبلغ - الرسوم
      // في السحب: الرصيد الجديد = القديم - المبلغ - الرسوم
      double newBalance = transaction.type == TransactionType.DEPOSIT
          ? currentBalance + transaction.amount - transaction.fees
          : currentBalance - transaction.amount - transaction.fees;

      // جلب الموظف الحالي (جديد الإصدار 37)
      final authService = Get.find<AuthService>();
      final user = authService.currentUser.value;

      // 2. إضافة السجل مع بيانات الرقابة (V37)
      await txn.insert(
        'fund_transactions', 
        transaction.copyWith(
          userId: user?.id,
          userName: user?.name,
          balanceAfter: newBalance,
        ).toMap(), 
        conflictAlgorithm: ConflictAlgorithm.replace
      );

      // 3. تحديث رصيد الصندوق
      await txn.update('funds', {'balance': newBalance}, where: 'id = ?', whereArgs: [transaction.fundId]);
    }
  }

  /// تحويل بين صندوقين (سحب من المصدر + إيداع في الهدف)
  Future<void> transferBetweenFunds({
    required int sourceFundId,
    required int targetFundId,
    required double amount,
    required String description,
    DateTime? transactionDate,
    double fees = 0.0,
    String? transferNumber,
  }) async {
    final db = await _dbService.database;
    final date = transactionDate ?? DateTime.now();

    await db.transaction((txn) async {
      // سحب من المصدر (مع خصم الرسوم)
      final withdrawalDescription = 'تحويل إلى صـندوق: $description';
      final withdrawalTx = FundTransactionModel(
        fundId: sourceFundId,
        type: TransactionType.WITHDRAWAL,
        amount: amount,
        description: withdrawalDescription,
        transactionDate: date,
        transferNumber: transferNumber,
        sourceFundId: sourceFundId,
        targetFundId: targetFundId,
        referenceType: 'TRANSFER_OUT',
        fees: fees,
      );
      await _executeTransaction(txn, withdrawalTx);

      // إيداع في الهدف (المبلغ الصافي)
      final depositDescription = 'تحويل وارد من صـندوق: $description';
      final depositTx = FundTransactionModel(
        fundId: targetFundId,
        type: TransactionType.DEPOSIT,
        amount: amount,
        description: depositDescription,
        transactionDate: date,
        transferNumber: transferNumber,
        sourceFundId: sourceFundId,
        targetFundId: targetFundId,
        referenceType: 'TRANSFER_IN',
        fees: 0.0, // الرسوم تم خصمها من المصدر
      );
      await _executeTransaction(txn, depositTx);
    });
  }

  /// جلب حركات صندوق معين مع فلترة
  Future<List<FundTransactionModel>> getTransactions({
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
      whereArgs.add(type.name);
    }

    final maps = await db.query(
      'fund_transactions',
      where: whereClauses.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'transactionDate DESC',
    );
    return maps.map((m) => FundTransactionModel.fromMap(m)).toList();
  }

  /// ملخص اليوم لصندوق معين
  Future<Map<String, double>> getTodaysSummary(int fundId) async {
    final db = await _dbService.database;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final result = await db.rawQuery('''
      SELECT SUM(CASE WHEN type = 'DEPOSIT' THEN amount - fees ELSE 0 END) as totalDeposits,
        SUM(CASE WHEN type = 'WITHDRAWAL' THEN amount + fees ELSE 0 END) as totalWithdrawals
      FROM fund_transactions
      WHERE fundId = ? AND transactionDate >= ? AND transactionDate < ?
    ''', [fundId, startOfDay.toIso8601String(), endOfDay.toIso8601String()]);

    final summary = result.first;
    return {
      'todaysDeposits': (summary['totalDeposits'] as num?)?.toDouble() ?? 0.0,
      'todaysWithdrawals': (summary['totalWithdrawals'] as num?)?.toDouble() ?? 0.0,
    };
  }

  /// ملخص حركة الصندوق (Across all funds)
  Future<Map<String, double>> getFundFlowSummary({required DateTime from, required DateTime to}) async {
    final db = await _dbService.database;
    final inclusiveTo = to.add(const Duration(days: 1));
    final result = await db.rawQuery('''
      SELECT 
        SUM(CASE WHEN type = 'DEPOSIT' THEN amount - fees ELSE 0 END) as totalDeposits,
        SUM(CASE WHEN type = 'WITHDRAWAL' THEN amount + fees ELSE 0 END) as totalWithdrawals
      FROM fund_transactions
      WHERE transactionDate >= ? AND transactionDate < ?
    ''', [from.toIso8601String(), inclusiveTo.toIso8601String()]);

    final summary = result.first;
    return {
      'totalDeposits': (summary['totalDeposits'] as num?)?.toDouble() ?? 0.0,
      'totalWithdrawals': (summary['totalWithdrawals'] as num?)?.toDouble() ?? 0.0,
    };
  }

  /// بيانات تقرير حركة الصندوق
  Future<Map<String, dynamic>> generateFundFlowReportData({
    required int fundId,
    required DateTime from,
    required DateTime to,
  }) async {
    final db = await _dbService.database;
    final inclusiveTo = to.add(const Duration(days: 1));
    final fromString = from.toIso8601String();
    final toString = inclusiveTo.toIso8601String();

    // 1. الرصيد الافتتاحي
    final fundData = await db.query('funds', where: 'id = ?', whereArgs: [fundId]);
    final double initialBalance = fundData.isNotEmpty
        ? (fundData.first['initialBalance'] as num?)?.toDouble() ?? 0.0
        : 0.0;

    final priorResult = await db.rawQuery('''
      SELECT COALESCE(SUM(CASE WHEN type = 'DEPOSIT' THEN amount - fees ELSE -(amount + fees) END), 0) as netMovement
      FROM fund_transactions WHERE fundId = ? AND transactionDate < ?
    ''', [fundId, fromString]);
    final priorNet = (priorResult.first['netMovement'] as num?)?.toDouble() ?? 0.0;
    final openingBalance = initialBalance + priorNet;

    // 2. الحركات خلال الفترة
    final txMaps = await db.rawQuery('''
      SELECT * FROM fund_transactions
      WHERE fundId = ? AND transactionDate >= ? AND transactionDate < ?
      ORDER BY transactionDate ASC
    ''', [fundId, fromString, toString]);
    final txs = txMaps.map((m) => FundTransactionModel.fromMap(m)).toList();

    double totalDeposits = 0, totalWithdrawals = 0;
    for (var tx in txs) {
      if (tx.type == TransactionType.DEPOSIT) {
        totalDeposits += tx.amount;
      } else {
        totalWithdrawals += tx.amount;
      }
    }

    return {
      'openingBalance': openingBalance,
      'transactions': txs,
      'totalDeposits': totalDeposits,
      'totalWithdrawals': totalWithdrawals,
      'closingBalance': openingBalance + totalDeposits - totalWithdrawals,
    };
  }
}