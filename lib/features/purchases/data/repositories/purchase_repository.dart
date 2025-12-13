// File: lib/features/purchases/data/repositories/purchase_repository.dart

import 'package:ehab_company_admin/core/database/database_service.dart';
import 'package:ehab_company_admin/features/purchases/presentation/controllers/add_purchase_controller.dart';

import '../models/purchase_invoice_summary_model.dart';

class PurchaseRepository {
  final DatabaseService _dbService = DatabaseService();

  /// دالة لحفظ فاتورة الشراء بالكامل في transaction واحد
  Future<int> createPurchaseInvoice({
    required int? supplierId,
    required String? supplierInvoiceNumber,
    required DateTime invoiceDate,
    required double totalAmount,
    required double discountAmount,
    required double paidAmount,
    required double remainingAmount,
    required String? notes,
    required List<InvoiceItem> items,
    required bool deductFromFund, // <-- إضافة
  }) async {
    final db = await _dbService.database;
    int invoiceId = -1;

    await db.transaction((txn) async {
      // 1. إضافة الفاتورة الرئيسية
      invoiceId = await txn.insert('purchase_invoices', {
        'supplierId': supplierId,
        'invoiceNumber': supplierInvoiceNumber,
        'invoiceDate': invoiceDate.toIso8601String(),
        'totalAmount': totalAmount,
        'discountAmount': discountAmount,
        'paidAmount': paidAmount,
        'remainingAmount': remainingAmount,
        'notes': notes,
      });

      // 2. إضافة الأصناف وتحديث المخزون
      for (final item in items) {
        await txn.insert('purchase_invoice_items', {
          'invoiceId': invoiceId,
          'productId': item.product.id,
          'productName': item.product.name,
          'quantity': item.quantity,
          'purchasePrice': item.purchasePrice,
          'totalPrice': item.subtotal,
        });


        Map<String, dynamic> fieldsToUpdate = {
          'quantity': item.product.quantity + item.quantity,
          // الكمية الجديدة = القديمة + المشتراة
          'purchasePrice': item.purchasePrice,
        };
        if (item.newSalePrice != null) {
          fieldsToUpdate['salePrice'] = item.newSalePrice;
        }

        await txn.update(
          'products',
          fieldsToUpdate,
          where: 'id = ?',
          whereArgs: [item.product.id],
        );
      }
      if (remainingAmount > 0 && supplierId != null) {
        // أ. زيادة رصيد المورد
        await txn.rawUpdate(
          'UPDATE suppliers SET balance = balance + ? WHERE id = ?',
          [remainingAmount, supplierId],
        );
        // ب. تسجيل حركة "شراء آجل" في كشف حساب المورد
        await txn.insert('supplier_transactions', {
          'supplierId': supplierId,
          'type': 'PURCHASE', // تأكد من أن هذا النوع موجود في enum
          'amount': remainingAmount,
          'transactionDate': invoiceDate.toIso8601String(),
          'affectsFund': 0,
          'notes': 'فاتورة شراء آجلة رقم: $invoiceId',
        });
      }

      if (paidAmount > 0 && deductFromFund) { // أ. التحقق من رصيد الصندوق أولاً
        final fund = (await txn.query('funds', where: 'id = ?', whereArgs: [1]))
            .first;
        final double currentFundBalance = fund['balance'] as double;
        if (currentFundBalance < paidAmount) {
          // إذا كان الرصيد غير كافٍ، قم بإلغاء العملية بأكملها
          throw Exception(
              'الرصيد في الصندوق غير كافٍ. الرصيد الحالي: $currentFundBalance');
        }

        // ب. تسجيل حركة سحب في الصندوق
        await txn.insert('fund_transactions', {
          'fundId': 1,
          'type': 'WITHDRAWAL',
          'amount': paidAmount,
          'description': 'دفع جزء من فاتورة شراء رقم: $invoiceId',
          'referenceId': invoiceId,
          'transactionDate': DateTime.now().toIso8601String(),
        });

        // ج. تحديث رصيد الصندوق
        await txn.rawUpdate(
          'UPDATE funds SET balance = balance - ? WHERE id = ?',
          [paidAmount, 1],
        );
      }
      // --- نهاية التعديلات المهمة ---
    });

    return invoiceId;
  }

  Future<Map<String, dynamic>?> getInvoiceDetailsById(int invoiceId) async {
    final db = await _dbService.database;


    // 1. جلب بيانات الفاتورة الرئيسية مع اسم المورد
    final List<Map<String, dynamic>> invoiceData = await db.rawQuery('''
      SELECT
        pi.*,
        s.name as supplierName,
        s.phone as supplierPhone,
        pr.reason as reason -- جلب سبب الإرجاع
      FROM purchase_invoices pi
     LEFT JOIN suppliers s ON pi.supplierId = s.id
     LEFT JOIN purchase_returns pr ON pi.id = pr.originalInvoiceId -- ربط مع جدول
           WHERE pi.id = ?
    ''', [invoiceId]);

    if (invoiceData.isEmpty) {
      return null; // الفاتورة غير موجودة
    }

    // 2. جلب أصناف الفاتورة
    final List<Map<String, dynamic>> itemsData = await db.query(
      'purchase_invoice_items',
      where: 'invoiceId = ?',
      whereArgs: [invoiceId],
    );

    // 3. دمج النتائج في خريطة واحدة
    final result = {
      'invoice': invoiceData.first,
      'items': itemsData,
    };

    return result;
  }

// دالة لجلب آخر رقم فاتورة
  Future<int> getLastInvoiceId() async {
    final db = await _dbService.database;
    final result = await db.rawQuery(
        'SELECT MAX(id) as lastId FROM purchase_invoices');
    if (result.first['lastId'] != null) {
      return result.first['lastId'] as int;
    }
    return 0; // في حالة عدم وجود فواتير سابقة
  }

  Future<List<PurchaseInvoiceSummaryModel>> getAllInvoices({
    int? invoiceId,
    int? supplierId,
    String? status, // 'paid', 'due'
  }) async {
    final db = await _dbService.database;

    // بناء جملة الـ WHERE بشكل ديناميكي
    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    if (invoiceId != null) {
      whereClauses.add('pi.id = ?');
      whereArgs.add(invoiceId);
    }
    if (supplierId != null) {
      whereClauses.add('pi.supplierId = ?');
      whereArgs.add(supplierId);
    }
    if (status != null) {
      if (status == 'paid') {
        whereClauses.add("pi.status != 'RETURNED' AND pi.remainingAmount <= 0");
      } else if (status == 'due') {
        whereClauses.add("pi.status != 'RETURNED' AND pi.remainingAmount > 0");
      } else if (status == 'RETURNED') {
        whereClauses.add("pi.status = 'RETURNED'");
      }
    }

    final String whereStatement = whereClauses.isEmpty
        ? ''
        : 'WHERE ${whereClauses.join(' AND ')}';

    final String query = '''
    SELECT
      pi.id,
      pi.invoiceDate,
      pi.totalAmount,
      pi.remainingAmount,
      pi.status,  -- <-- إضافة جديدة
      s.name as supplierName
    FROM purchase_invoices pi
    LEFT JOIN suppliers s ON pi.supplierId = s.id
    $whereStatement
    ORDER BY pi.invoiceDate DESC
  ''';

    final List<Map<String, dynamic>> maps = await db.rawQuery(query, whereArgs);

    if (maps.isEmpty) {
      return [];
    }

    return List.generate(
        maps.length, (i) => PurchaseInvoiceSummaryModel.fromMap(maps[i]));
  }

  Future<void> addPaymentToInvoice({
    required int invoiceId,
    required int supplierId,
    required double paymentAmount,
  }) async {
    final db = await _dbService.database;

    await db.transaction((txn) async {
      // 1. التحقق من أن مبلغ الدفعة لا يتجاوز المتبقي
      final invoice = (await txn.query(
          'purchase_invoices', where: 'id = ?', whereArgs: [invoiceId])).first;
      final double currentRemaining = invoice['remainingAmount'] as double;

      if (paymentAmount > currentRemaining) {
        throw Exception('مبلغ الدفعة أكبر من المبلغ المتبقي على الفاتورة.');
      }

      // 2. تحديث
      await txn.rawUpdate(
        'UPDATE purchase_invoices SET paidAmount = paidAmount + ?, remainingAmount = remainingAmount - ? WHERE id = ?',
        [paymentAmount, paymentAmount, invoiceId],
      );

      // 3. تحديث رصيد المورد
      await txn.rawUpdate(
        'UPDATE suppliers SET balance = balance - ? WHERE id = ?',
        [paymentAmount, supplierId],
      );

      // 4. تسجيل حركة "دفعة نقدية" في كشف حساب المورد
      await txn.insert('supplier_transactions', {
        'supplierId': supplierId,
        'type': 'PAYMENT',
        'amount': paymentAmount,
        'transactionDate': DateTime.now().toIso8601String(),
        'affectsFund': 1,
        'notes': 'تسديد جزء من فاتورة شراء رقم: $invoiceId',
      });

      // 5. التحقق من رصيد الصندوق وتسجيل حركة سحب
      final fund = (await txn.query('funds', where: 'id = ?', whereArgs: [1]))
          .first;
      final double currentFundBalance = fund['balance'] as double;
      if (currentFundBalance < paymentAmount) {
        throw Exception('الرصيد في الصندوق غير كافٍ لإتمام الدفعة.');
      }

      await txn.insert('fund_transactions', {
        'fundId': 1,
        'type': 'WITHDRAWAL',
        'amount': paymentAmount,
        'description': 'تسديد جزء من فاتورة شراء رقم: $invoiceId',
        'referenceId': invoiceId,
        'transactionDate': DateTime.now().toIso8601String(),
      });

      await txn.rawUpdate('UPDATE funds SET balance = balance - ? WHERE id = ?',
        [paymentAmount, 1],
      );
    });
  }

  // --- بداية الإضافة: دالة جلب إجمالي المبالغ المتبقية ---
  Future<double> getTotalRemainingAmount() async {
    final db = await _dbService.database;

    // استخدام SUM() لحساب مجموع عمود remainingAmount
    final result = await db.rawQuery(
        'SELECT SUM(remainingAmount) as total FROM purchase_invoices');
    if (result.first['total'] != null) {
      // قد تكون النتيجة من نوع int إذا كانت كل المبالغ بدون كسور، لذا نتحقق
      final totalValue = result.first['total'];
      if (totalValue is int) {
        return totalValue.toDouble();
      }
      return totalValue as double;
    }

    return 0.0; // إرجاع صفر إذا لم تكن هناك فواتير
  }

  // --- بداية الإضافة: دالة إرجاع فاتورة شراء ---
  Future<int> returnPurchaseInvoice({
    required int originalInvoiceId,
    required String reason,
    required bool receivePayment,
  }) async {
    final db = await _dbService.database;
    int returnId = -1;

    await db.transaction((txn) async {
      // 1. جلب بيانات الفاتورة الأصلية
      final invoiceData = (await txn.query('purchase_invoices', where: 'id = ?', whereArgs: [originalInvoiceId])).first;
      final itemsData = await txn.query('purchase_invoice_items', where: 'invoiceId = ?', whereArgs: [originalInvoiceId]);

      final int supplierId = invoiceData['supplierId'] as int;
      final double paidAmount = invoiceData['paidAmount'] as double;
      final double remainingAmount = invoiceData['remainingAmount'] as double;
      final double totalValue = paidAmount + remainingAmount;

      if (invoiceData['status'] == 'RETURNED') {
        throw Exception('هذه الفاتورة قد تم إرجاعها بالفعل.');
      }

      // 2. تسجيل عملية الإرجاع
      returnId = await txn.insert('purchase_returns', {
        'originalInvoiceId': originalInvoiceId,
        'returnDate': DateTime.now().toIso8601String(),
        'reason': reason,
        'totalValue': totalValue,
      });

      // 3. تحديث حالة الفاتورة الأصلية إلى "مرتجعة"
      await txn.update('purchase_invoices', {'status': 'RETURNED'}, where: 'id = ?', whereArgs: [originalInvoiceId]);

      // 4. خصم الكميات المرتجعة من المخزون
      for (final item in itemsData) {
        await txn.rawUpdate('UPDATE products SET quantity = quantity - ? WHERE id = ?', [item['quantity'], item['productId']]);
      }

      // --- بداية الإصلاح الجذري ---

      // 5. [دائمًا] تسجيل حركة "مرتجع" عامة في كشف حساب المورد للتتبع
      await txn.insert('supplier_transactions', {
        'supplierId': supplierId,
        'type': 'RETURN',
        'amount': totalValue,
        'transactionDate': DateTime.now().toIso8601String(),
        'affectsFund': receivePayment && paidAmount > 0 ? 1 : 0,
        'notes': 'مرتجع فاتورة شراء رقم: $originalInvoiceId',
      });

      // 6. [فقط إذا كانت آجلة] قم بإلغاء الدين من رصيد المورد
      if (remainingAmount > 0) {
        await txn.rawUpdate('UPDATE suppliers SET balance = balance - ? WHERE id = ?', [remainingAmount, supplierId]);
      }

      // 7. [فقط إذا تم استلام المبلغ نقداً] قم بتوريد المبلغ المدفوع أصلاً إلى الصندوق
      if (receivePayment && paidAmount > 0) {
        // التحقق من رصيد الصندوق ليس ضروريًا عند الإيداع، لكنه ممارسة جيدة

        // أ. إضافة المبلغ المدفوع أصلاً إلى الصندوق
        await txn.insert('fund_transactions', {
          'fundId': 1,
          'type': 'DEPOSIT',
          'amount': paidAmount,
          'description': 'استلام قيمة مرتجع من فاتورة شراء رقم: $originalInvoiceId',
          'referenceId': returnId,
          'transactionDate': DateTime.now().toIso8601String(),
        });
        await txn.rawUpdate('UPDATE funds SET balance = balance + ? WHERE id = ?', [paidAmount, 1]);
      }
      // --- نهاية الإصلاح الجذري ---
    });

    return returnId;
  }

// --- نهاية الإضافة ---
}