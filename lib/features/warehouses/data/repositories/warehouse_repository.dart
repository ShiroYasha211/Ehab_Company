// File: lib/features/warehouses/data/repositories/warehouse_repository.dart

import 'package:ehab_company_admin/core/database/database_service.dart';
import '../models/warehouse_model.dart';

class WarehouseRepository {
  final DatabaseService _dbService = DatabaseService();

  /// جلب جميع المخازن
  Future<List<WarehouseModel>> getAllWarehouses() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'warehouses',
      orderBy: "CASE WHEN type = 'main' THEN 0 ELSE 1 END, createdAt DESC",
    );
    return maps.map((m) => WarehouseModel.fromMap(m)).toList();
  }

  /// جلب المخازن النشطة فقط
  Future<List<WarehouseModel>> getActiveWarehouses() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'warehouses',
      where: 'isActive = 1',
      orderBy: "CASE WHEN type = 'main' THEN 0 ELSE 1 END, createdAt DESC",
    );
    return maps.map((m) => WarehouseModel.fromMap(m)).toList();
  }

  /// جلب مخزن بالمعرف
  Future<WarehouseModel?> getWarehouseById(int id) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'warehouses',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return WarehouseModel.fromMap(maps.first);
  }

  /// إضافة مخزن جديد
  Future<int> addWarehouse(WarehouseModel warehouse) async {
    final db = await _dbService.database;
    return await db.insert('warehouses', warehouse.toMap());
  }

  /// تعديل مخزن
  Future<int> updateWarehouse(WarehouseModel warehouse) async {
    final db = await _dbService.database;
    return await db.update(
      'warehouses',
      warehouse.toMap(),
      where: 'id = ?',
      whereArgs: [warehouse.id],
    );
  }

  /// حذف مخزن (فقط الفرعي)
  Future<void> deleteWarehouse(int id) async {
    final db = await _dbService.database;

    // التحقق من أن المخزن ليس رئيسياً
    final warehouse = await getWarehouseById(id);
    if (warehouse != null && warehouse.isMain) {
      throw Exception('لا يمكن حذف المخزن الرئيسي');
    }

    // التحقق من عدم وجود أرصدة
    final stockResult = await db.rawQuery(
      'SELECT SUM(quantity) as total FROM warehouse_stock WHERE warehouseId = ? AND quantity > 0',
      [id],
    );
    final totalStock = (stockResult.first['total'] as num?)?.toDouble() ?? 0.0;
    if (totalStock > 0) {
      throw Exception('لا يمكن حذف المخزن، يوجد أرصدة بقيمة $totalStock. يرجى ترحيل البضاعة أولاً.');
    }

    await db.delete('warehouses', where: 'id = ?', whereArgs: [id]);
  }

  /// جلب أرصدة مخزن معين (المنتجات وكمياتها)
  Future<List<Map<String, dynamic>>> getWarehouseStock(int warehouseId) async {
    final db = await _dbService.database;
    return await db.rawQuery('''
      SELECT 
        ws.productId,
        ws.quantity,
        p.name as productName,
        p.code as productCode,
        p.salePrice,
        p.purchasePrice,
        p.unitId,
        p.imageUrl,
        p.category,
        p.isSalesStopped
      FROM warehouse_stock ws
      JOIN products p ON ws.productId = p.id
      WHERE ws.warehouseId = ? AND ws.quantity > 0
      ORDER BY p.name ASC
    ''', [warehouseId]);
  }

  /// جلب كمية منتج معين في مخزن معين
  Future<double> getProductStockInWarehouse(int warehouseId, int productId) async {
    final db = await _dbService.database;
    final result = await db.rawQuery(
      'SELECT quantity FROM warehouse_stock WHERE warehouseId = ? AND productId = ?',
      [warehouseId, productId],
    );
    if (result.isEmpty) return 0.0;
    return (result.first['quantity'] as num?)?.toDouble() ?? 0.0;
  }

  /// جلب تقرير قيمة مخزن معين
  Future<Map<String, dynamic>> getWarehouseValueReport(int warehouseId) async {
    final db = await _dbService.database;
    final result = await db.rawQuery('''
      SELECT 
        COUNT(ws.productId) as totalProducts,
        SUM(ws.quantity) as totalQuantity,
        SUM(ws.quantity * p.salePrice) as totalSaleValue,
        SUM(ws.quantity * p.purchasePrice) as totalPurchaseValue
      FROM warehouse_stock ws
      JOIN products p ON ws.productId = p.id
      WHERE ws.warehouseId = ? AND ws.quantity > 0
    ''', [warehouseId]);

    final row = result.first;
    return {
      'totalProducts': (row['totalProducts'] as int?) ?? 0,
      'totalQuantity': (row['totalQuantity'] as num?)?.toDouble() ?? 0.0,
      'totalSaleValue': (row['totalSaleValue'] as num?)?.toDouble() ?? 0.0,
      'totalPurchaseValue': (row['totalPurchaseValue'] as num?)?.toDouble() ?? 0.0,
    };
  }

  /// جلب المبيعات من مخزن معين خلال فترة
  Future<Map<String, double>> getWarehouseSales(int warehouseId, {DateTime? from, DateTime? to}) async {
    final db = await _dbService.database;
    
    String whereClause = "si.warehouseId = ? AND si.status != 'RETURNED'";
    List<dynamic> args = [warehouseId];
    
    if (from != null) {
      whereClause += ' AND si.invoiceDate >= ?';
      args.add(from.toIso8601String());
    }
    if (to != null) {
      final inclusiveTo = to.add(const Duration(days: 1));
      whereClause += ' AND si.invoiceDate < ?';
      args.add(inclusiveTo.toIso8601String());
    }

    final result = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(si.totalAmount), 0) as totalSales,
        COALESCE(SUM(si.paidAmount), 0) as totalCash,
        COALESCE(SUM(si.remainingAmount), 0) as totalCredit,
        COUNT(si.id) as invoiceCount
      FROM sales_invoices si
      WHERE $whereClause
    ''', args);

    final row = result.first;
    return {
      'totalSales': (row['totalSales'] as num?)?.toDouble() ?? 0.0,
      'totalCash': (row['totalCash'] as num?)?.toDouble() ?? 0.0,
      'totalCredit': (row['totalCredit'] as num?)?.toDouble() ?? 0.0,
      'invoiceCount': (row['invoiceCount'] as num?)?.toDouble() ?? 0.0,
    };
  }
}
