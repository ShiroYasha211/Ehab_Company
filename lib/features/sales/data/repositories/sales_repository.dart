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
    required String? issuedBy, // الموظف الذي أصدر الفاتورة
    int warehouseId = 1,
    List<Map<String, dynamic>>? payments, // قائمة المدفوعات التفصيلية
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
        'remainingAmount': remainingAmount,
        'notes': notes,
        'warehouseId': warehouseId,
        'issuedBy': issuedBy,
      });

      // 2. إضافة الأصناف وتحديث المخزون
      for (final item in items) {
        // حساب معامل التحويل بين وحدة البيع ووحدة المنتج الأساسية
        double conversionFactor = 1.0;
        String unitName = '';

        if (item.selectedUnitId != null) {
          int? currentUnitId = item.product.unitId; // الوحدة الكبيرة (المخزن بها)
          int targetUnitId = item.selectedUnitId!;   // الوحدة التي تم البيع بها
          
          if (currentUnitId != targetUnitId) {
            // نبحث عن المسار من وحدة المنتج الكبرى (مثلاً كرتون) هبوطاً إلى وحدة البيع (مثلاً باكت)
            int? tempId = currentUnitId; 
            while (tempId != null && tempId != targetUnitId) {
              final unitDataList = await txn.query('units', where: 'id = ?', whereArgs: [tempId]);
              if (unitDataList.isEmpty) break;
              
              final unitData = unitDataList.first;
              double factor = (unitData['conversionFactor'] as num).toDouble();
              
              // نضرب في المعامل للانتقال للمستوى الأصغر
              conversionFactor *= factor;
              tempId = unitData['childUnitId'] as int?;
            }
          }
          
          final unitData = (await txn.query('units', where: 'id = ?', whereArgs: [targetUnitId])).first;
          unitName = unitData['name'] as String;
        }

        // الكمية التي سيتم خصمها من المخزون (بحسب الوحدة الأساسية للمنتج التي يتم التخزين بها، وهي غالباً الكرتون)
        // قسمة الكمية الإجمالية (بيع + مجاناً) على معامل التحويل (مثال: خصم (6 بواكت + 1 باكت مجاني) / 6 = 1.16 كرتون يخصم من المخزون)
        double quantityToDeduct = (item.quantity + item.freeQuantity) / conversionFactor;

        // التحقق من توفر الكمية في المخزن المحدد
        final stockResult = await txn.rawQuery(
          'SELECT quantity FROM warehouse_stock WHERE warehouseId = ? AND productId = ?',
          [warehouseId, item.product.id],
        );
        final double currentQuantity = stockResult.isEmpty
            ? 0.0
            : (stockResult.first['quantity'] as num).toDouble();
        
        if (currentQuantity < (quantityToDeduct - 0.0001)) { // السماح بهامش خطأ بسيط للفاصلة العائمة
          throw Exception('الكمية غير متوفرة في المخزن للمنتج: ${item.product.name}');
        }

        // حساب سعر الشراء (التكلفة) للوحدة التي تم البيع بها
        // إذا كان سعر الكرتون 120 والكرتون يحتوي 6 بواكت، فسعر الباكت 120 / 6 = 20
        double purchasePricePerUnit = item.product.purchasePrice / conversionFactor;

        // إضافة الصنف إلى تفاصيل الفاتورة
        await txn.insert('sales_invoice_items', {
          'invoiceId': invoiceId,
          'productId': item.product.id,
          'productName': item.product.name,
          'quantity': item.quantity,
          'freeQuantity': item.freeQuantity,
          'unit': unitName,
          'unitId': item.selectedUnitId,
          'salePrice': item.salePrice,
          'purchasePrice': purchasePricePerUnit,
          'totalPrice': item.subtotal,
        });

        // خصم الكمية من المخزن المحدد (warehouse_stock)
        await txn.rawUpdate(
          'UPDATE warehouse_stock SET quantity = quantity - ? WHERE warehouseId = ? AND productId = ?',
          [quantityToDeduct, warehouseId, item.product.id],
        );

        // تحديث الكمية الإجمالية في جدول المنتجات أيضاً (للتوافق)
        await txn.rawUpdate(
          'UPDATE products SET quantity = quantity - ? WHERE id = ?',
          [quantityToDeduct, item.product.id],
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
        // يتم الآن تسجيل الحركات وتحديث الأرصدة لكل دفعة بشكل مستقل (انظر حلقة المدفوعات أدناه)
      }

      // 5. إضافة تفاصيل طرق الدفع (جديد الإصدار 24)
      if (payments != null && payments.isNotEmpty) {
        for (var payment in payments) {
          await txn.insert('sales_invoice_payments', {
            'invoiceId': invoiceId,
            'method': payment['method'],
            'amount': payment['amount'],
            'transferNumber': payment['transferNumber'],
            'senderName': payment['senderName'],
            'transferCompany': payment['transferCompany'],
            'transferImage': payment['transferImage'],
            'bankName': payment['bankName'],
            'bankReference': payment['bankReference'],
            'bankImage': payment['bankImage'],
            'fundId': payment['fundId'], // تخزين معرف الصندوق (جديد)
            'notes': payment['notes'],
            'createdAt': payment['createdAt'] ?? DateTime.now().toIso8601String(),
          });

          // 6. تسجيل حركة الصندوق وتحديث الرصيد لكل دفعة بشكل مستقل (جديد الإصدار 25)
          final int? fundId = payment['fundId'] as int?;
          final double amount = (payment['amount'] as num?)?.toDouble() ?? 0.0;

          if (fundId != null && amount > 0) {
            String methodDesc = 'نقد';
            if (payment['method'] == 'transfer') methodDesc = 'حوالة';
            else if (payment['method'] == 'bank') methodDesc = 'بنك';

            // تسجيل الحركة في الصندوق المختار بكافة التفاصيل (جديد الإصدار 26)
            await txn.insert('fund_transactions', {
              'fundId': fundId,
              'type': 'DEPOSIT',
              'amount': amount,
              'description': 'دفعة مبيعات ($methodDesc) - فاتورة رقم: $invoiceId',
              'referenceId': invoiceId,
              'transactionDate': DateTime.now().toIso8601String(),
              // بيانات إضافية للتوثيق المحاسبي
              'transferNumber': payment['transferNumber'],
              'senderName': payment['senderName'],
              'transferCompany': payment['transferCompany'],
              'attachmentPath': payment['transferImage'] ?? payment['bankImage'], // استخدام الصورة المتوفرة
              'bankName': payment['bankName'],
              'bankReference': payment['bankReference'],
              'notes': payment['notes'],
            });

            // تحديث رصيد الصندوق المختار
            await txn.rawUpdate(
              'UPDATE funds SET balance = balance + ? WHERE id = ?',
              [amount, fundId],
            );
          }
        }
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
    // حساب المجموع النهائي لـ (الكمية المباعة * سعر الشراء المخزن وقت البيع)
    final result = await db.rawQuery('''
      SELECT SUM(sii.quantity * sii.purchasePrice) as totalCOGS
      FROM sales_invoice_items sii
      JOIN sales_invoices si ON sii.invoiceId = si.id
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

  Future<List<Map<String, dynamic>>> getAllReturns({
    DateTime? startDate,
    DateTime? endDate,
    int? customerId,
    int? warehouseId,
    String? searchQuery,
  }) async {
    final db = await _dbService.database;
    
    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    if (startDate != null) {
      whereClauses.add('sr.returnDate >= ?');
      whereArgs.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      // إضافة يوم واحد لتشمل تاريخ النهاية بالكامل
      final inclusiveEnd = endDate.add(const Duration(days: 1));
      whereClauses.add('sr.returnDate < ?');
      whereArgs.add(inclusiveEnd.toIso8601String());
    }
    if (customerId != null) {
      whereClauses.add('si.customerId = ?');
      whereArgs.add(customerId);
    }
    if (warehouseId != null) {
      whereClauses.add('si.warehouseId = ?');
      whereArgs.add(warehouseId);
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      if (int.tryParse(searchQuery) != null) {
        whereClauses.add('sr.originalInvoiceId = ?');
        whereArgs.add(int.parse(searchQuery));
      } else {
        whereClauses.add('sr.reason LIKE ?');
        whereArgs.add('%$searchQuery%');
      }
    }

    final whereStatement = whereClauses.isEmpty ? '' : 'WHERE ${whereClauses.join(' AND ')}';

    return await db.rawQuery('''
      SELECT 
        sr.*, 
        c.name as customerName,
        si.invoiceDate as originalInvoiceDate,
        w.name as warehouseName
      FROM sales_returns sr
      JOIN sales_invoices si ON sr.originalInvoiceId = si.id
      LEFT JOIN customers c ON si.customerId = c.id
      LEFT JOIN warehouses w ON si.warehouseId = w.id
      $whereStatement
      ORDER BY sr.returnDate DESC
    ''', whereArgs);
  }
}