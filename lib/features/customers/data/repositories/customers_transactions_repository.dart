// File: lib/features/customers/data/repositories/customer_transactions_repository.dart

import 'package:ehab_company_admin/core/database/database_service.dart';
import 'package:ehab_company_admin/features/customers/data/models/customer_transaction_model.dart';

class CustomerTransactionsRepository {
  final DatabaseService _dbService = DatabaseService();

  /// دالة لجلب كل الحركات المالية الخاصة بعميل معين
  Future<List<CustomerTransactionModel>> getTransactionsForCustomer(int customerId) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customer_transactions',
      where: 'customerId = ?',
      whereArgs: [customerId],
      orderBy: 'transactionDate DESC', // ترتيب الحركات من الأحدث إلى الأقدم
    );

    if (maps.isEmpty) {
      return [];
    }

    return List.generate(maps.length, (i) => CustomerTransactionModel.fromMap(maps[i]));
  }
}
