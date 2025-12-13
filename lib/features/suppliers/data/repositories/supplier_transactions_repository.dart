// File: lib/features/suppliers/data/repositories/supplier_transactions_repository.dart

import 'package:ehab_company_admin/core/database/database_service.dart';
import 'package:ehab_company_admin/features/suppliers/data/models/supplier_transaction_model.dart';

class SupplierTransactionsRepository {
  final DatabaseService _dbService = DatabaseService();

  /// دالة لجلب كل الحركات المالية لمورد معين
  Future<List<SupplierTransactionModel>> getTransactionsForSupplier(int supplierId) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'supplier_transactions',
      where: 'supplierId = ?',
      whereArgs: [supplierId],
      orderBy: 'transactionDate DESC', // الأحدث أولاً
    );

    if (maps.isEmpty) {
      return [];
    }
    return List.generate(maps.length, (i) => SupplierTransactionModel.fromMap(maps[i]));
  }
  // --- بداية الإضافة: دالة البحث عن سند ---
  /// دالة لجلب حركة واحدة باستخدام رقم السند (ID)
  Future<Map<String, dynamic>?> getTransactionById(int transactionId) async {
    final db = await _dbService.database;

    // سنقوم بعمل JOIN بين جدول الحركات وجدول الموردين لجلب اسم المورد أيضًا
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT 
        st.*, 
        s.name as supplierName 
      FROM supplier_transactions st
      LEFT JOIN suppliers s ON st.supplierId = s.id
      WHERE st.id = ?
    ''', [transactionId]);

    if (result.isNotEmpty) {
      // نرجع الخريطة الأولى التي تحتوي على بيانات الحركة + اسم المورد
      return result.first;
    }
    return null; // في حالة عدم العثور على السند
  }
// --- نهاية الإضافة ---
}
