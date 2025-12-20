// File: lib/features/suppliers/data/repositories/supplier_repository.dart

import 'package:ehab_company_admin/core/database/database_service.dart';
import 'package:ehab_company_admin/features/fund/data/models/fund_transaction_model.dart';
import 'package:ehab_company_admin/features/fund/data/repositories/fund_repository.dart';
import 'package:ehab_company_admin/features/suppliers/data/models/supplier_model.dart';
import 'package:ehab_company_admin/features/suppliers/data/models/supplier_transaction_model.dart';
import 'package:sqflite/sqflite.dart';

class SupplierRepository {
  final DatabaseService _dbService = DatabaseService();
  final FundRepository _fundRepository = FundRepository();

  Future<int> addSupplier(SupplierModel supplier) async {
    final db = await _dbService.database;
    return await db.insert('suppliers', supplier.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateSupplier(SupplierModel supplier) async {
    final db = await _dbService.database;
    return await db.update('suppliers', supplier.toMap(),
        where: 'id = ?', whereArgs: [supplier.id]);
  }

  Future<int> deleteSupplier(int id) async {
    final db = await _dbService.database;
    return await db.delete('suppliers', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<SupplierModel>> getAllSuppliers() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
        'suppliers', orderBy: 'name ASC');
    if (maps.isEmpty) return [];
    return List.generate(maps.length, (i) => SupplierModel.fromMap(maps[i]));
  }

  // --- بداية الحل النهائي والصحيح ---
  Future<int> addSupplierTransaction(
      SupplierTransactionModel transaction) async {
    final db = await _dbService.database;
    int transactionId = -1;

    await db.transaction((txn) async {
      // 1. تحضير البيانات للإضافة
      //    نقوم بإنشاء نسخة من الخريطة ونزيل 'id' منها
      //    لأن قاعدة البيانات هي التي ستنشئه (AUTOINCREMENT).
      final Map<String, dynamic> dataToInsert = transaction.toMap();
      dataToInsert.remove('id');

      // 2. إضافة سجل الحركة المالية للمورد والحصول على رقم السند
      transactionId = await txn.insert('supplier_transactions', dataToInsert,
          conflictAlgorithm: ConflictAlgorithm.fail);

      // 3. تحديث رصيد المورد بناءً على نوع الحركة
      if (transaction.type == SupplierTransactionType.PAYMENT) {
        // إذا كانت دفعة، قم بإنقاص رصيد المورد
        await txn.rawUpdate(
          'UPDATE suppliers SET balance = balance - ? WHERE id = ?',
          [transaction.amount, transaction.supplierId],
        );
      } else { // (SupplierTransactionType.OPENING_BALANCE)
        // إذا كان رصيدًا افتتاحيًا، قم بزيادة رصيد المورد
        await txn.rawUpdate(
          'UPDATE suppliers SET balance = balance + ? WHERE id = ?',
          [transaction.amount, transaction.supplierId],
        );
      }

      // 4. (اختياري) تحديث رصيد الصندوق
      if (transaction.affectsFund &&
          transaction.type == SupplierTransactionType.PAYMENT) {
        final supplier = (await txn.query(
            'suppliers', where: 'id = ?', whereArgs: [transaction.supplierId]))
            .first;
        final supplierName = supplier['name'] as String;

        final fundTransaction = FundTransactionModel(
          fundId: 1,
          // الصندوق الرئيسي
          type: TransactionType.WITHDRAWAL,
          amount: transaction.amount,
          description: 'دفعة للمورد: $supplierName (سند رقم: $transactionId)',
          referenceId: transactionId,
          transactionDate: transaction.transactionDate,
        );

        await _fundRepository.addTransactionWithinTransaction(
            txn, fundTransaction);
      }
    });

    return transactionId;
  }

  // --- بداية الإضافة ---
  /// دالة لحساب إجمالي أرصدة الموردين (الديون)
  Future<double> getTotalBalance() async {
    final db = await _dbService.database;
    // حساب مجموع الأرصدة التي هي أكبر من صفر (الديون التي عليك)
    final result = await db.rawQuery('''
      SELECT SUM(balance) as totalDebt 
      FROM suppliers 
      WHERE balance > 0
    ''');

    if (result.first['totalDebt'] != null) {
      return result.first['totalDebt'] as double;
    }
    return 0.0;
  }

  Future<List<SupplierTransactionModel>> getPaymentVouchers({
    int? supplierId,
    DateTime? from,
    DateTime? to,
  }) async {
    final db = await _dbService.database;

    List<String> whereClauses = [
      // الشرط الأساسي: جلب سندات الدفع وسندات الرصيد الافتتاحي
      "(st.type = 'PAYMENT' OR st.type = 'OPENING_BALANCE')"
    ];
    List<dynamic> whereArgs = [];

    if (supplierId != null) {
      whereClauses.add('st.supplierId = ?');
      whereArgs.add(supplierId);
    }

    if (from != null) {
      whereClauses.add('st.transactionDate >= ?');
      whereArgs.add(from.toIso8601String());
    }

    if (to != null) {
      final inclusiveTo = to.add(const Duration(days: 1));
      whereClauses.add('st.transactionDate < ?');
      whereArgs.add(inclusiveTo.toIso8601String());
    }

    final String whereStatement =
    whereClauses.isEmpty ? '' : 'WHERE ${whereClauses.join(' AND ')}';

    final String query = '''
      SELECT 
        st.*, 
        s.name as supplierName  -- جلب اسم المورد
      FROM supplier_transactions st
      JOIN suppliers s ON st.supplierId = s.id
      $whereStatement
      ORDER BY st.transactionDate DESC
    ''';

    final List<Map<String, dynamic>> maps = await db.rawQuery(query, whereArgs);

    if (maps.isEmpty) {
      return [];
    }

    // ملاحظة: SupplierTransactionModel لا يحتوي على supplierName
    // سنقوم بإنشاء نسخة جديدة من الخريطة ونضيفه
    return List.generate(maps.length, (i) {
      final map = Map<String, dynamic>.from(maps[i]);
      // سنحتاج إلى تعديل الـ model لاستقبال هذا الحقل
      return SupplierTransactionModel.fromMap(map);
    });
  }
}