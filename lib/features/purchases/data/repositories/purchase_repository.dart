// File: lib/features/purchases/data/repositories/purchase_repository.dart

import 'package:ehab_company_admin/core/database/database_service.dart';
import '../models/purchase_invoice_item.dart';
import '../models/purchase_invoice_summary_model.dart';
import '../models/purchase_invoice_payment_model.dart';

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
    required List<PurchaseInvoiceItem> items,
    required List<PurchaseInvoicePaymentModel> payments,
    required String? issuedBy,
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
        'issuedBy': issuedBy,
      });

      // 2. إضافة الأصناف وتحديث المخزون
      for (final item in items) {
        // حساب معامل التحويل بين وحدة الشراء ووحدة المنتج الأساسية
        double conversionFactor = 1.0;
        String unitName = '';

        if (item.selectedUnitId != null) {
          int? productMainUnitId = item.product.unitId; // الوحدة الكبيرة (المخزن بها)
          int purchaseUnitId = item.selectedUnitId!;    // الوحدة التي تم الشراء بها
          
          if (productMainUnitId != purchaseUnitId) {
            // نبحث عن المسار من وحدة المنتج الكبرى (مثلاً كرتون) هبوطاً إلى وحدة الشراء (مثلاً باكت)
            int? tempId = productMainUnitId; 
            while (tempId != null && tempId != purchaseUnitId) {
              final unitDataList = await txn.query('units', where: 'id = ?', whereArgs: [tempId]);
              if (unitDataList.isEmpty) break;
              
              final unitData = unitDataList.first;
              double factor = (unitData['conversionFactor'] as num).toDouble();
              
              // نضرب في المعامل للانتقال للمستوى الأصغر
              conversionFactor *= factor;
              tempId = unitData['childUnitId'] as int?;
            }
          }
          
          final unitData = (await txn.query('units', where: 'id = ?', whereArgs: [purchaseUnitId])).first;
          unitName = unitData['name'] as String;
        }

        // الكمية التي سيتم إضافتها للمخزون (مقدرة بالوحدة الأساسية للمنتج التي يتم التخزين بها، وهي غالباً الكبرى)
        // تشمل الكمية المشتراة + الكمية المجانية (البونص)
        double totalQuantity = item.quantity + item.freeQuantity;
        double quantityToAdd = totalQuantity / conversionFactor;

        // إضافة الصنف إلى تفاصيل الفاتورة
        await txn.insert('purchase_invoice_items', {
          'invoiceId': invoiceId,
          'productId': item.product.id,
          'productName': item.product.name,
          'quantity': item.quantity,
          'freeQuantity': item.freeQuantity, // <-- إضافة
          'unit': unitName, // حفظ اسم الوحدة التي تم الشراء بها
          'purchasePrice': item.purchasePrice,
          'totalPrice': item.subtotal,
        });

        // تحديث المنتج (الكمية والأسعار)
        Map<String, dynamic> fieldsToUpdate = {
          'quantity': item.product.quantity + quantityToAdd,
          'purchasePrice': item.rootPurchasePrice, // تحديث السعر العالمي بالوحدة الكبرى
        };
        
        if (item.newSalePrice != null) {
          fieldsToUpdate['salePrice'] = item.newSalePrice; // تحديث سعر البيع العالمي بالوحدة الكبرى
        }

        await txn.update(
          'products',
          fieldsToUpdate,
          where: 'id = ?',
          whereArgs: [item.product.id],
        );

        // --- ميزة المزامنة: تحديث المخزن الرئيسي (ID=1) لضمان ظهوره في التحويلات ---
        final mainStock = await txn.rawQuery(
          'SELECT id FROM warehouse_stock WHERE warehouseId = 1 AND productId = ?',
          [item.product.id],
        );

        if (mainStock.isEmpty) {
          await txn.insert('warehouse_stock', {
            'warehouseId': 1,
            'productId': item.product.id,
            'quantity': quantityToAdd,
          });
        } else {
          await txn.rawUpdate(
            'UPDATE warehouse_stock SET quantity = quantity + ? WHERE warehouseId = 1 AND productId = ?',
            [quantityToAdd, item.product.id],
          );
        }
      }

      // 3. إضافة المدفوعات وتحديث الصناديق/البنوك
      for (final payment in payments) {
        // أ. إدراج الدفعة في جدول المدفوعات
        await txn.insert('purchase_invoice_payments', {
          ...payment.toMap(),
          'invoiceId': invoiceId,
        });

        // ب. تحديث الصندوق أو البنك المختار
        final int targetFundId = payment.fundId ?? 1; // الافتراضي الصندوق الرئيسي
        
        final fundData = (await txn.query('funds', where: 'id = ?', whereArgs: [targetFundId])).first;
        final double currentBalance = (fundData['balance'] as num).toDouble();
        
        if (currentBalance < payment.amount) {
          throw Exception('الرصيد في ${fundData['name']} غير كافٍ. المتوفر: $currentBalance');
        }

        await txn.rawUpdate(
          'UPDATE funds SET balance = balance - ? WHERE id = ?',
          [payment.amount, targetFundId],
        );

        // ج. تسجيل حركة سحب في الصندوق/البنك
        await txn.insert('fund_transactions', {
          'fundId': targetFundId,
          'type': 'WITHDRAWAL',
          'amount': payment.amount,
          'description': 'سحب لدفع فاتورة مشتريات رقم: $invoiceId',
          'transactionDate': invoiceDate.toIso8601String(),
          'notes': payment.notes ?? 'دفع فاتورة شراء',
          'referenceType': 'purchase_invoice',
          'referenceId': invoiceId,
          'transferNumber': payment.transferNumber,
          'senderName': payment.senderName,
          'transferCompany': payment.transferCompany,
          'attachmentPath': payment.transferImage ?? payment.bankImage,
          'bankName': payment.bankName,
          'bankReference': payment.bankReference,
        });
      }

      // 4. مديونية المورد
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
    }); // نهاية الـ transaction

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

    // 3. جلب المدفوعات المرتبطة بهذه الفاتورة (مع اسم الصندوق والنوع)
    final List<Map<String, dynamic>> rawPayments = await db.rawQuery('''
      SELECT pip.*, f.name as fundName, f.fundType
      FROM purchase_invoice_payments pip
      LEFT JOIN funds f ON pip.fundId = f.id
      WHERE pip.invoiceId = ?
    ''', [invoiceId]);

    // تحويل النتائج إلى خريطة قابلة للتعديل لإضافة الأيقونة برمجياً
    final paymentsData = rawPayments.map((p) {
      final map = Map<String, dynamic>.from(p);
      final String? type = p['fundType'];
      String icon = '💵'; // الافتراضي نقداً
      if (type == 'bank') icon = '🏦';
      if (type == 'transfer') icon = '📨';
      map['fundIcon'] = icon;
      return map;
    }).toList();

    // 4. دمج النتائج في خريطة واحدة
    final result = {
      'invoice': invoiceData.first,
      'items': itemsData,
      'payments': paymentsData,
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

  Future<List<Map<String, dynamic>>> getAllReturns({
    DateTime? startDate,
    DateTime? endDate,
    int? supplierId,
    int? warehouseId,
    String? searchQuery,
  }) async {
    final db = await _dbService.database;
    
    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    if (startDate != null) {
      whereClauses.add('pr.returnDate >= ?');
      whereArgs.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      final inclusiveEnd = endDate.add(const Duration(days: 1));
      whereClauses.add('pr.returnDate < ?');
      whereArgs.add(inclusiveEnd.toIso8601String());
    }
    if (supplierId != null) {
      whereClauses.add('pi.supplierId = ?');
      whereArgs.add(supplierId);
    }
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      if (int.tryParse(searchQuery) != null) {
        whereClauses.add('pr.originalInvoiceId = ?');
        whereArgs.add(int.parse(searchQuery));
      } else {
        whereClauses.add('pr.reason LIKE ?');
        whereArgs.add('%$searchQuery%');
      }
    }

    final whereStatement = whereClauses.isEmpty ? '' : 'WHERE ${whereClauses.join(' AND ')}';

    return await db.rawQuery('''
      SELECT 
        pr.*, 
        pr.totalValue as totalReturnedValue, 
        s.name as supplierName,
        pi.invoiceDate as originalInvoiceDate,
        'المخزن الرئيسي' as warehouseName
      FROM purchase_returns pr
      JOIN purchase_invoices pi ON pr.originalInvoiceId = pi.id
      LEFT JOIN suppliers s ON pi.supplierId = s.id
      $whereStatement
      ORDER BY pr.returnDate DESC
    ''', whereArgs);
  }
}