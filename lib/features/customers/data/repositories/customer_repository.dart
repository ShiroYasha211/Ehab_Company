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
          fundId: 1, // الصندوق الرئيسي
          type: TransactionType.DEPOSIT, // توريد
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
      {String orderBy = 'balance DESC'}) async { // الافتراضي هو الترتيب حسب الأعلى دينًا
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: 'balance > 0', // الشرط الأهم: جلب العملاء الذين رصيدهم أكبر من صفر
      orderBy: orderBy,
    );
    if (maps.isEmpty) return [];
    return List.generate(maps.length, (i) => CustomerModel.fromMap(maps[i]));
  }
}
