// File: lib/features/activities/data/repositories/operation_repository.dart

import 'package:ehab_company_admin/core/database/database_service.dart';
import '../models/operation_model.dart';

class OperationRepository {
  final DatabaseService _dbService = DatabaseService();

  Future<List<OperationModel>> getUnifiedOperations({
    DateTime? from,
    DateTime? to,
    List<OperationType>? types,
    String? employeeName,
    double? minAmount,
    double? maxAmount,
  }) async {
    final db = await _dbService.database;
    
    // بناء استعلامات الـ UNION لكل جدول
    final List<String> queries = [];
    
    // 1. المبيعات
    queries.add('''
      SELECT id, invoiceDate as date, totalAmount as amount, 'sale' as category, issuedBy as userName, notes as details, 'sales_invoices' as referenceTable, id as referenceId 
      FROM sales_invoices
    ''');

    // 2. المشتريات
    queries.add('''
      SELECT id, invoiceDate as date, totalAmount as amount, 'purchase' as category, issuedBy as userName, notes as details, 'purchase_invoices' as referenceTable, id as referenceId 
      FROM purchase_invoices
    ''');

    // 3. المصروفات
    queries.add('''
      SELECT id, expenseDate as date, amount as amount, 'expense' as category, issuedBy as userName, notes as details, 'expenses' as referenceTable, id as referenceId 
      FROM expenses
    ''');

    // 4. التحويلات المخزنية
    queries.add('''
      SELECT id, transferDate as date, totalCostValue as amount, 'transfer' as category, NULL as userName, notes as details, 'inventory_transfers' as referenceTable, id as referenceId 
      FROM inventory_transfers
    ''');

    // دمج الاستعلامات
    String mainQuery = "SELECT * FROM (${queries.join(' UNION ALL ')}) AS combined_ops";
    
    // بناء شروط الفلترة
    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    if (from != null) {
      whereClauses.add('date >= ?');
      whereArgs.add(from.toIso8601String());
    }
    if (to != null) {
      final inclusiveTo = to.add(const Duration(days: 1));
      whereClauses.add('date < ?');
      whereArgs.add(inclusiveTo.toIso8601String());
    }
    if (types != null && types.isNotEmpty) {
      final typeNames = types.map((t) => t.name).toList();
      String placeholders = List.filled(typeNames.length, '?').join(',');
      whereClauses.add('category IN ($placeholders)');
      whereArgs.addAll(typeNames);
    }
    if (employeeName != null && employeeName.isNotEmpty) {
      whereClauses.add('userName = ?');
      whereArgs.add(employeeName);
    }
    if (minAmount != null) {
      whereClauses.add('amount >= ?');
      whereArgs.add(minAmount);
    }
    if (maxAmount != null) {
      whereClauses.add('amount <= ?');
      whereArgs.add(maxAmount);
    }

    if (whereClauses.isNotEmpty) {
      mainQuery += " WHERE ${whereClauses.join(' AND ')}";
    }

    mainQuery += " ORDER BY date DESC";

    final List<Map<String, dynamic>> maps = await db.rawQuery(mainQuery, whereArgs);
    return maps.map((map) => OperationModel.fromMap(map)).toList();
  }

  /// جلب قائمة بأسماء الموظفين الذين قاموا بعمليات (لأغراض الفلترة)
  Future<List<String>> getUniqueEmployees() async {
    final db = await _dbService.database;
    // جلب كل الأسماء الفريدة من كل جداول العمليات
    final result = await db.rawQuery('''
      SELECT DISTINCT name FROM (
        SELECT DISTINCT issuedBy as name FROM sales_invoices WHERE issuedBy IS NOT NULL
        UNION
        SELECT DISTINCT issuedBy as name FROM purchase_invoices WHERE issuedBy IS NOT NULL
        UNION
        SELECT DISTINCT issuedBy as name FROM expenses WHERE issuedBy IS NOT NULL
      ) AS all_employees ORDER BY name ASC
    ''');
    
    return result.map((row) => row['name'] as String).toList();
  }

  /// جلب التفاصيل الكاملة لعملية محددة
  Future<Map<String, dynamic>> getOperationFullDetails(OperationModel op) async {
    final db = await _dbService.database;
    final Map<String, dynamic> details = {
      'operation': op,
      'items': [],
      'relatedData': {},
    };

    if (op.type == OperationType.sale) {
      // جلب أصناف المبيعات
      details['items'] = await db.query(
        'sales_invoice_items',
        where: 'invoiceId = ?',
        whereArgs: [op.referenceId],
      );
      // جلب بيانات العميل (اختياري حسب الحاجة)
      // قد تكون مخزنة في الحقل userName أو نحتاج استعلام إضافي
    } else if (op.type == OperationType.purchase) {
      // جلب أصناف المشتريات
      details['items'] = await db.query(
        'purchase_invoice_items',
        where: 'invoiceId = ?',
        whereArgs: [op.referenceId],
      );
    } else if (op.type == OperationType.expense) {
      // جلب بيانات المصروف التفصيلية
      final List<Map<String, dynamic>> result = await db.rawQuery('''
        SELECT e.*, c.name as categoryName, f.name as fundName, s.name as supplierName
        FROM expenses e
        LEFT JOIN expense_categories c ON e.categoryId = c.id
        LEFT JOIN funds f ON e.fundId = f.id
        LEFT JOIN suppliers s ON e.supplierId = s.id
        WHERE e.id = ?
      ''', [op.referenceId]);
      
      if (result.isNotEmpty) {
        details['relatedData'] = result.first;
      }
    }

    return details;
  }
}
