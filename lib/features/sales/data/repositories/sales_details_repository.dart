// File: lib/features/sales/data/repositories/sales_details_repository.dart

import 'package:ehab_company_admin/core/database/database_service.dart';

class SalesDetailsRepository {
  final DatabaseService _dbService = DatabaseService();

  Future<Map<String, dynamic>?> getInvoiceDetailsById(int invoiceId) async {
    // ... (هذه الدالة تبقى كما هي)
    final db = await _dbService.database;
    final List<Map<String, dynamic>> invoiceData = await db.rawQuery('''
      SELECT
        si.*,
        c.name as customerName,
        c.phone as customerPhone
      FROM sales_invoices si
      LEFT JOIN customers c ON si.customerId = c.id
      WHERE si.id = ?
    ''', [invoiceId]);

    if (invoiceData.isEmpty) {
      return null;
    }
    final List<Map<String, dynamic>> itemsData = await db.query(
      'sales_invoice_items',
      where: 'invoiceId = ?',
      whereArgs: [invoiceId],
    );
    return {'invoice': invoiceData.first, 'items': itemsData};
  }

  // --- بداية الإضافة: دالة تسجيل دفعة على فاتورة مبيعات ---
  Future<void> addPaymentToSalesInvoice({
    required int invoiceId,
    required int customerId,
    required double paymentAmount,
  }) async {
    final db = await _dbService.database;

    await db.transaction((txn) async {
      // 1. التحقق من أن مبلغ الدفعة لا يتجاوز المتبقي
      final invoice = (await txn.query('sales_invoices', where: 'id = ?', whereArgs: [invoiceId])).first;
      final double currentRemaining = invoice['remainingAmount'] as double;

      if (paymentAmount > currentRemaining) {
        throw Exception('مبلغ الدفعة أكبر من المبلغ المتبقي على الفاتورة.');
      }

      // 2. تحديث مبالغ الفاتورة
      await txn.rawUpdate(
        'UPDATE sales_invoices SET paidAmount = paidAmount + ?, remainingAmount = remainingAmount - ? WHERE id = ?',
        [paymentAmount, paymentAmount, invoiceId],
      );

      // 3. تحديث رصيد العميل (خصم الدين)
      await txn.rawUpdate(
        'UPDATE customers SET balance = balance - ? WHERE id = ?',
        [paymentAmount, customerId],
      );

      // 4. تسجيل حركة "سند قبض" في كشف حساب العميل
      await txn.insert('customer_transactions', {
        'customerId': customerId,
        'type': 'RECEIPT',
        'amount': paymentAmount,
        'transactionDate': DateTime.now().toIso8601String(),
        'affectsFund': 1,
        'notes': 'سند قبض لفاتورة مبيعات رقم: $invoiceId',
      });

      // 5. تسجيل حركة "توريد" في الصندوق
      await txn.insert('fund_transactions', {
        'fundId': 1,
        'type': 'DEPOSIT',
        'amount': paymentAmount,
        'description': 'قبض من فاتورة مبيعات رقم: $invoiceId',
        'referenceId': invoiceId,
        'transactionDate': DateTime.now().toIso8601String(),
      });

      // 6. تحديث رصيد الصندوق
      await txn.rawUpdate(
        'UPDATE funds SET balance = balance + ? WHERE id = ?',
        [paymentAmount, 1],
      );
    });
  }
  // --- بداية الإضافة: دالة إرجاع فاتورة مبيعات ---
  Future<void> returnSalesInvoice({
    required int originalInvoiceId,
    required String reason,
    required bool returnPaymentToFund,
  }) async {
    final db = await _dbService.database;

    await db.transaction((txn) async {
      // 1. جلب بيانات الفاتورة الأصلية وأصنافها
      final invoiceData = (await txn.query('sales_invoices', where: 'id = ?', whereArgs: [originalInvoiceId])).first;
      final itemsData = await txn.query('sales_invoice_items', where: 'invoiceId = ?', whereArgs: [originalInvoiceId]);

      final int? customerId = invoiceData['customerId'] as int?;
      final double paidAmount = invoiceData['paidAmount'] as double;
      final double remainingAmount = invoiceData['remainingAmount'] as double;
      final double totalValue = paidAmount + remainingAmount;

      if (invoiceData['status'] == 'RETURNED') {
        throw Exception('هذه الفاتورة قد تم إرجاعها بالفعل.');
      }

      // 2. تحديث حالة الفاتورة الأصلية إلى "مرتجعة"
      await txn.update('sales_invoices', {'status': 'RETURNED'}, where: 'id = ?', whereArgs: [originalInvoiceId]);

      // 3. إعادة الكميات المرتجعة إلى المخزون
      for (final item in itemsData) {
        await txn.rawUpdate(
          'UPDATE products SET quantity = quantity + ? WHERE id = ?',
          [item['quantity'], item['productId']],
        );
      }

      if (customerId != null) {
        // 4. تسجيل حركة "مرتجع مبيعات" في كشف حساب العميل
        await txn.insert('customer_transactions', {
          'customerId': customerId,
          'type': 'RETURN', // نوع جديد، تأكد من إضافته إلى enum
          'amount': totalValue,
          'transactionDate': DateTime.now().toIso8601String(),
          'affectsFund': returnPaymentToFund && paidAmount > 0 ? 1 : 0,
          'notes': 'مرتجع مبيعات من فاتورة رقم: $originalInvoiceId',
        });

        // 5. خصم المبلغ من رصيد العميل
        await txn.rawUpdate(
          'UPDATE customers SET balance = balance - ? WHERE id = ?',
          [totalValue, customerId],
        );
      }

      // 6. إذا تم إرجاع المبلغ نقداً، قم بخصمه من الصندوق
      if (returnPaymentToFund && paidAmount > 0) {
        await txn.insert('fund_transactions', {
          'fundId': 1,
          'type': 'WITHDRAWAL', // سحب
          'amount': paidAmount,
          'description': 'إرجاع مبلغ لمرتجع مبيعات فاتورة رقم: $originalInvoiceId',
          'referenceId': originalInvoiceId,
          'transactionDate': DateTime.now().toIso8601String(),
        });
        await txn.rawUpdate(
          'UPDATE funds SET balance = balance - ? WHERE id = ?',
          [paidAmount, 1],
        );
      }
    });
  }
// --- نهاية الإضافة ---

// --- نهاية الإضافة ---
}
