// File: lib/features/customers/data/repositories/customer_repository.dart

import 'package:ehab_company_admin/core/database/database_service.dart';
import 'package:ehab_company_admin/features/customers/data/models/customer_model.dart';
import 'package:ehab_company_admin/features/customers/data/models/customer_transaction_model.dart';
import 'package:ehab_company_admin/features/fund/data/models/fund_transaction_model.dart';
import 'package:ehab_company_admin/features/fund/data/repositories/fund_repository.dart';
import 'package:sqflite/sqflite.dart';

class CustomerRepository {
  final DatabaseService _dbService = DatabaseService();
  final FundRepository _fundRepository = FundRepository();

  Future<int> addCustomer(CustomerModel customer) async {
    final db = await _dbService.database;
    final dataToInsert = customer.toMap();
    dataToInsert.remove('id');
    return await db.insert('customers', dataToInsert,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateCustomer(CustomerModel customer) async {
    final db = await _dbService.database;
    return await db.update('customers', customer.toMap(),
        where: 'id = ?', whereArgs: [customer.id]);
  }

  Future<int> deleteCustomer(int id) async {
    final db = await _dbService.database;
    return await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<CustomerModel>> getAllCustomers() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps =
    await db.query('customers', orderBy: 'name ASC');
    if (maps.isEmpty) return [];
    return List.generate(maps.length, (i) => CustomerModel.fromMap(maps[i]));
  }

  /// دالة لإضافة حركة مالية لعميل وتحديث رصيده
  Future<int> addCustomerTransaction(
      CustomerTransactionModel transaction) async {
    final db = await _dbService.database;
    int transactionId = -1;

    await db.transaction((txn) async {
      // 1. إضافة سجل الحركة المالية
      final dataToInsert = transaction.toMap();
      dataToInsert.remove('id');
      transactionId =
      await txn.insert('customer_transactions', dataToInsert);

      // 2. تحديث رصيد العميل
      if (transaction.type == CustomerTransactionType.RECEIPT) {
        // إذا كانت دفعة من العميل، قم بإنقاص رصيده (لأن دينه قل)
        await txn.rawUpdate(
          'UPDATE customers SET balance = balance - ? WHERE id = ?',
          [transaction.amount, transaction.customerId],
        );
      } else {
        // إذا كانت فاتورة آجلة أو رصيد افتتاحي، قم بزيادة رصيده
        await txn.rawUpdate(
          'UPDATE customers SET balance = balance + ? WHERE id = ?',
          [transaction.amount, transaction.customerId],
        );
      }

      // --- بداية التعديل ---
      // 3. تحديث تاريخ آخر حركة للعميل
      await txn.rawUpdate(
        'UPDATE customers SET lastTransactionDate = ? WHERE id = ?',
        [transaction.transactionDate.toIso8601String(), transaction.customerId],
      );
      // --- نهاية التعديل ---

      // 4. تحديث رصيد الصندوق
      if (transaction.affectsFund &&
          transaction.type == CustomerTransactionType.RECEIPT) {
        final customer = (await txn.query(
            'customers', where: 'id = ?', whereArgs: [transaction.customerId]))
            .first;
        final customerName = customer['name'] as String;

        final fundTransaction = FundTransactionModel(
          fundId: 1,
          // الصندوق الرئيسي
          type: TransactionType.DEPOSIT,
          // توريد
          amount: transaction.amount,
          description: 'دفعة من العميل: $customerName (سند رقم: $transactionId)',
          referenceId: transactionId,
          transactionDate: transaction.transactionDate,
        );

        // استخدام دالة repository الصندوق لإضافة الحركة
        await _fundRepository.addTransactionWithinTransaction(
            txn, fundTransaction);
      }
    });

    return transactionId;
  }

  /// دالة لحساب إجمالي ديون العملاء
  Future<double> getTotalBalance() async {
    final db = await _dbService.database;
    // حساب مجموع الأرصدة التي هي أكبر من صفر (الديون المستحقة لك)
    final result = await db.rawQuery('''
      SELECT SUM(balance) as totalDebt 
      FROM customers 
      WHERE balance > 0
    ''');

    if (result.first['totalDebt'] != null) {
      return result.first['totalDebt'] as double;
    }
    return 0.0;
  }

  Future<List<CustomerModel>> getIndebtedCustomers(
      {String orderBy = 'balance DESC'}) async {
    // الافتراضي هو الترتيب حسب الأعلى دينًا
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: 'balance > 0', // الشرط الأهم: جلب العملاء الذين رصيدهم أكبر من صفر
      orderBy: orderBy,
    );
    if (maps.isEmpty) return [];
    return List.generate(maps.length, (i) => CustomerModel.fromMap(maps[i]));
  }

  Future<List<CustomerTransactionModel>> getReceiptVouchers({
    int? customerId,
    DateTime? from,
    DateTime? to,
  }) async {
    final db = await _dbService.database;

    List<String> whereClauses = [
      // الشرط الأساسي: جلب سندات القبض وسندات الرصيد الافتتاحي
      "(ct.type = 'RECEIPT' OR ct.type = 'OPENING_BALANCE')"
    ];
    List<dynamic> whereArgs = [];

    if (customerId != null) {
      whereClauses.add('ct.customerId = ?');
      whereArgs.add(customerId);
    }

    if (from != null) {
      whereClauses.add('ct.transactionDate >= ?');
      whereArgs.add(from.toIso8601String());
    }

    if (to != null) {
      final inclusiveTo = to.add(const Duration(days: 1));
      whereClauses.add('ct.transactionDate < ?');
      whereArgs.add(inclusiveTo.toIso8601String());
    }

    final String whereStatement =
    whereClauses.isEmpty ? '' : 'WHERE ${whereClauses.join(' AND ')}';

    final String query = '''
      SELECT 
        ct.*, 
        c.name as customerName  -- جلب اسم العميل
      FROM customer_transactions ct
      JOIN customers c ON ct.customerId = c.id
      $whereStatement
      ORDER BY ct.transactionDate DESC
    ''';

    final List<Map<String, dynamic>> maps = await db.rawQuery(query, whereArgs);

    if (maps.isEmpty) {
      return [];
    }

    // سنحتاج إلى تعديل الـ model لاستقبال حقل customerName
    return List.generate(maps.length, (i) {
      final map = Map<String, dynamic>.from(maps[i]);
      return CustomerTransactionModel.fromMap(map);
    });
  }

  // --- بداية الإضافة: دالة للتحقق من وجود علاقات للعميل ---  /// يتحقق مما إذا كان للعميل أي فواتير مبيعات أو حركات مالية مرتبطة به
  Future<bool> checkCustomerHasRelations(int customerId) async {
    final db = await _dbService.database;

    // 1. التحقق من وجود فواتير مبيعات
    final salesCount = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM sales_invoices WHERE customerId = ?',
      [customerId],
    ));

    if (salesCount != null && salesCount > 0) {
      return true; // وجدنا فواتير، لا داعي لإكمال البحث
    }

    // 2. التحقق من وجود حركات مالية (إذا لم نجد فواتير)
    final transactionsCount = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM customer_transactions WHERE customerId = ?',
      [customerId],
    ));

    if (transactionsCount != null && transactionsCount > 0) {
      return true; // وجدنا حركات مالية
    }

    // إذا وصلنا إلى هنا، فالعميل ليس له أي علاقات
    return false;
  }

// --- نهاية الإضافة ---

  /// يجلب كل العملاء مع أرصدتهم مرتبة حسب الأعلى دينًا
  Future<List<CustomerModel>> getCustomersForReport() async {
    final db = await _dbService.database;
    // استعلام لجلب كل العملاء، مع ترتيبهم حسب الرصيد تنازليًا
    final
    List
    <
        Map<String, dynamic>> maps = await db.query(
      'customers',
      orderBy: 'balance DESC',
    );

    if (maps.isEmpty) {
      return [];
    }
    return List.generate(maps.length, (i) => CustomerModel.fromMap(maps[i]));
  } // --- نهاية الإضافة ---
  // --- بداية الإضافة: دالة جديدة لتجهيز بيانات كشف الحساب ---
  Future<Map<String, dynamic>> getCustomerStatementData({
    required int customerId,
    required DateTime from,
    required DateTime to,
  }) async {
    final db = await _dbService.database;
    final inclusiveTo = to.add(const Duration(days: 1));

    final fromString = from.toIso8601String();
    final toString = inclusiveTo.toIso8601String();

// 1. حساب الرصيد الافتتاحي (رصيد العميل قبل تاريخ "من")
// هذا يحسب صافي كل الحركات التي حدثت قبل بداية الفترة
    final openingBalanceResult = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(CASE WHEN type = 'SALE' OR type = 'OPENING_BALANCE' THEN amount ELSE -amount END), 0) as openingBalance
      FROM customer_transactions
      WHERE customerId = ? AND transactionDate < ?
    ''', [customerId, fromString]);
    final double openingBalance = (openingBalanceResult
        .first['openingBalance'] as num?)?.toDouble() ?? 0.0;

// 2. جلب كل الحركات خلال الفترة المحددة
    final transactionsResult = await db.query(
      'customer_transactions',
      where: 'customerId = ? AND transactionDate >= ? AND transactionDate < ?',
      whereArgs: [customerId, fromString, toString],
      orderBy: 'transactionDate ASC', // الترتيب من الأقدم للأحدث مهم جدًا
    );

    final List<CustomerTransactionModel> transactions =
    transactionsResult
        .map((map) => CustomerTransactionModel.fromMap(map))
        .toList();

    return {
      'openingBalance': openingBalance,
      'transactions': transactions,
    };
  }
// --- نهاية الإضافة ---
}