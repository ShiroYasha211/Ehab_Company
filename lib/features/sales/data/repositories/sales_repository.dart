// File: lib/features/sales/data/repositories/sales_repository.dart

import 'package:ehab_company_admin/core/database/database_service.dart';
import 'package:ehab_company_admin/features/sales/presentation/controllers/add_sales_invoice_controller.dart';

import '../models/sales_invoice_summary_model.dart'; // سنقوم بإنشاء هذا لاحقًا

class SalesRepository {
  final DatabaseService _dbService = DatabaseService();

  /// دالة لحفظ فاتورة المبيعات بالكامل في transaction واحد
  Future<int> createSalesInvoice({
    required int? customerId,
    required DateTime invoiceDate,
    required double totalAmount,
    required double discountAmount,
    required double paidAmount,
    required double remainingAmount,
    required String? notes,
    required List<SalesInvoiceItem> items,
  }) async {
    final db = await _dbService.database;
    int invoiceId = -1;

    await db.transaction((txn) async {
      // 1. إضافة فاتورة المبيعات الرئيسية
      invoiceId = await txn.insert('sales_invoices', {
        'customerId': customerId,
        'invoiceDate': invoiceDate.toIso8601String(),
        'totalAmount': totalAmount,
        'discountAmount': discountAmount,
        'paidAmount': paidAmount,
        'remainingAmount': remainingAmount, 'notes': notes,
      });

      // 2. إضافة الأصناف وتحديث المخزون
      for (final item in items) {
        // التحقق من توفر الكمية في المخزون
        final product = (await txn.query(
            'products', where: 'id = ?', whereArgs: [item.product.id])).first;
        final double currentQuantity = product['quantity'] as double;
        if (currentQuantity < item.quantity) {
          throw Exception(
              'الكمية غير متوفرة في المخزون للمنتج: ${item.product.name}');
        }

        // إضافة الصنف إلى فاتورة المبيعات
        await txn.insert('sales_invoice_items', {
          'invoiceId': invoiceId,
          'productId': item.product.id,
          'productName': item.product.name,
          'quantity': item.quantity,
          'salePrice': item.salePrice, // سعر البيع
          'totalPrice': item.subtotal,
        });

        // خصم الكمية من المخزون
        await txn.rawUpdate(
          'UPDATE products SET quantity = quantity - ? WHERE id = ?',
          [item.quantity, item.product.id],
        );
      }

      // 3. تحديث رصيد العميل (إذا كان هناك مبلغ متبقٍ)
      if (remainingAmount > 0 && customerId != null) {
        // أ. زيادة رصيد العميل
        await txn.rawUpdate(
          'UPDATE customers SET balance = balance + ? WHERE id = ?',
          [remainingAmount, customerId],
        );
        // ب. تسجيل حركة "بيع آجل" في كشف حساب العميل
        await txn.insert('customer_transactions', {
          'customerId': customerId,
          'type': 'SALE',
          'amount': remainingAmount,
          'transactionDate': invoiceDate.toIso8601String(),
          'affectsFund': 0,
          'notes': 'فاتورة مبيعات آجلة رقم: $invoiceId',
        });
      }

      // 4. تحديث الصندوق (إذا تم قبض مبلغ)
      if (paidAmount > 0) {
        // لا يوجد داعي للتحقق من الرصيد عند الإيداع
        await txn.insert('fund_transactions', {
          'fundId': 1,
          'type': 'DEPOSIT', // توريد
          'amount': paidAmount,
          'description': 'قبض من فاتورة مبيعات رقم: $invoiceId',
          'referenceId': invoiceId,
          'transactionDate': DateTime.now().toIso8601String(),
        });

        // تحديث رصيد الصندوق
        await txn.rawUpdate(
          'UPDATE funds SET balance = balance + ? WHERE id = ?',
          [paidAmount, 1],
        );
      }
    });

    return invoiceId;
  }

  Future<List<SalesInvoiceSummaryModel>> getAllInvoices({
    int? invoiceId,
    int? customerId,
    String? status, // 'paid', 'due', 'RETURNED'
  }) async {
    final db = await _dbService.database;

    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    if (invoiceId != null) {
      whereClauses.add('si.id = ?');
      whereArgs.add(invoiceId);
    }
    if (customerId != null) {
      whereClauses.add('si.customerId = ?');
      whereArgs.add(customerId);
    }

    if (status != null) {
      if (status == 'paid') {
        whereClauses.add("si.status != 'RETURNED' AND si.remainingAmount <= 0");
      } else if (status == 'due') {
        whereClauses.add("si.status != 'RETURNED' AND si.remainingAmount > 0");
      } else if (status == 'RETURNED') {
        whereClauses.add("si.status = 'RETURNED'");
      }
    }

    final String whereStatement =
    whereClauses.isEmpty ? '' : 'WHERE ${whereClauses.join(' AND ')}';

    final String query = '''
      SELECT
        si.id,
        si.invoiceDate,
        si.totalAmount,
        si.remainingAmount,
        si.status,
        c.name as customerName  -- جلب اسم العميل
      FROM sales_invoices si
      LEFT JOIN customers c ON si.customerId = c.id
      $whereStatement
      ORDER BY si.id DESC 
    ''';

    final List<Map<String, dynamic>> maps = await db.rawQuery(query, whereArgs);

    if (maps.isEmpty) {
      return [];
    }

    return List.generate(
        maps.length, (i) => SalesInvoiceSummaryModel.fromMap(maps[i]));
  }

  Future<double> getTotalSalesRevenue(
      {required DateTime from, required DateTime to}) async {
    final db = await _dbService.database;
    // إضافة يوم واحد لتاريخ النهاية ليشمل اليوم نفسه بالكامل
    final inclusiveTo = to.add(const Duration(days: 1));

    final result = await db.rawQuery('''
      SELECT SUM(totalAmount) as total 
      FROM sales_invoices
      WHERE invoiceDate >= ? AND invoiceDate < ? AND status != 'RETURNED'
    ''', [from.toIso8601String(), inclusiveTo.toIso8601String()]);

    if (result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  /// دالة لحساب تكلفة البضاعة المباعة (COGS) خلال فترة محددة
  Future<double> getCostOfGoodsSold(
      {required DateTime from, required DateTime to}) async {
    final db = await _dbService.database;
    final inclusiveTo = to.add(const Duration(days: 1));

    // هذا استعلام معقد يقوم بالآتي:
    // 1. يربط جدول أصناف المبيعات (sales_invoice_items) بجدول فواتير المبيعات (sales_invoices)
    //     // 2. يربط الناتج بجدول المنتجات (products) للحصول على سعر الشراء
    //     // 3. يفلتر النتائج حسب الفترة الزمنية المحددة وحالة الفاتورة (ليست مرتجعة)
    //     // 4. يحسب المجموع النهائي لـ (الكمية المباعة * سعر الشراء)
    final result = await db.rawQuery('''
          SELECT SUM(sii.quantity * p.purchasePrice) as totalCOGS
      FROM sales_invoice_items sii
      JOIN sales_invoices si ON sii.invoiceId = si.id
      JOIN products p ON sii.productId = p.id
      WHERE si.invoiceDate >= ? AND si.invoiceDate < ? AND si.status != 'RETURNED'
    ''', [from.toIso8601String(), inclusiveTo.toIso8601String()]);

    if (result.first['totalCOGS'] != null) {
      return (result.first['totalCOGS'] as num).toDouble();
    }
    return 0.0;
  }

  Future<List<Map<String, dynamic>>> getTopSellingProducts({
    required DateTime from,
    required DateTime to,
    required String orderBy, // 'totalQuantity' or 'totalRevenue'
    int limit = 10,
  }) async {
    final db = await _dbService.database;
    final inclusiveTo = to.add(const Duration(days: 1));

    final String query = '''
     SELECT 
       p.id,
       p.name,
       SUM(sii.quantity) as totalQuantity,
       SUM(sii.totalPrice) as totalRevenue
     FROM sales_invoice_items sii
     JOIN sales_invoices si ON sii.invoiceId = si.id
      JOIN products p ON sii.productId = p.id
      WHERE si.invoiceDate >= ? AND si.invoiceDate < ? AND si.status != 'RETURNED'
      GROUP BY p.id, p.name
      ORDER BY $orderBy DESC
        LIMIT ?
      ''';

    final List<Map<String, dynamic>> maps = await db.rawQuery(
        query, [from.toIso8601String(), inclusiveTo.toIso8601String(), limit]);

    return maps;
  }
}