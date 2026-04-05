// File: lib/features/warehouses/data/repositories/inventory_transfer_repository.dart

import 'package:ehab_company_admin/core/database/database_service.dart';
import '../models/inventory_transfer_model.dart';

class InventoryTransferRepository {
  final DatabaseService _dbService = DatabaseService();

  /// إنشاء سند تحويل مخزني (عهدة) كعملية ذرية واحدة
  Future<int> createTransfer({
    required int sourceWarehouseId,
    required int destinationWarehouseId,
    required DateTime transferDate,
    required String? notes,
    required List<TransferItemInput> items,
  }) async {
    final db = await _dbService.database;
    int transferId = -1;

    await db.transaction((txn) async {
      // حساب الإجماليات
      double totalSaleValue = 0;
      double totalCostValue = 0;
      for (final item in items) {
        totalSaleValue += item.quantity * item.salePrice;
        totalCostValue += item.quantity * item.purchasePrice;
      }

      // 1. إنشاء سند التحويل
      transferId = await txn.insert('inventory_transfers', {
        'sourceWarehouseId': sourceWarehouseId,
        'destinationWarehouseId': destinationWarehouseId,
        'transferDate': transferDate.toIso8601String(),
        'totalValue': totalSaleValue,
        'totalCostValue': totalCostValue,
        'status': 'COMPLETED',
        'notes': notes,
        'createdAt': DateTime.now().toIso8601String(),
      });

      // 2. إضافة تفاصيل الأصناف والتحديث المخزني
      for (final item in items) {
        // التحقق من توفر الكمية في المخزن المصدر
        final stockResult = await txn.rawQuery(
          'SELECT quantity FROM warehouse_stock WHERE warehouseId = ? AND productId = ?',
          [sourceWarehouseId, item.productId],
        );
        
        final currentStock = stockResult.isEmpty 
            ? 0.0 
            : (stockResult.first['quantity'] as num).toDouble();
        
        if (currentStock < item.quantityInBaseUnit) {
          throw Exception(
            'الكمية غير متوفرة في المخزن المصدر للمنتج: ${item.productName}. '
            'المتوفر: ${currentStock.toStringAsFixed(2)}, المطلوب: ${item.quantityInBaseUnit.toStringAsFixed(2)} كرتون/أساسي'
          );
        }

        // إضافة تفاصيل الصنف بالوحدات المختارة للمستخدم
        await txn.insert('inventory_transfer_items', {
          'transferId': transferId,
          'productId': item.productId,
          'productName': item.productName,
          'quantity': item.quantity,
          'unitId': item.unitId,
          'salePrice': item.salePrice,
          'purchasePrice': item.purchasePrice,
          'totalSaleValue': item.quantity * item.salePrice,
          'totalCostValue': item.quantity * item.purchasePrice,
        });

        // خصم من المخزن المصدر (بالوحدة الأساسية)
        await txn.rawUpdate(
          'UPDATE warehouse_stock SET quantity = quantity - ? WHERE warehouseId = ? AND productId = ?',
          [item.quantityInBaseUnit, sourceWarehouseId, item.productId],
        );

        // --- ميزة المزامنة: تحديث جدول المنتجات الرئيسي إذا كان المصدر هو المخزن الرئيسي (ID=1) ---
        if (sourceWarehouseId == 1) {
          await txn.rawUpdate(
            'UPDATE products SET quantity = quantity - ? WHERE id = ?',
            [item.quantityInBaseUnit, item.productId],
          );
        }

        // إضافة إلى المخزن الوجهة (upsert) (بالوحدة الأساسية)
        final destStock = await txn.rawQuery(
          'SELECT id FROM warehouse_stock WHERE warehouseId = ? AND productId = ?',
          [destinationWarehouseId, item.productId],
        );

        if (destStock.isEmpty) {
          await txn.insert('warehouse_stock', {
            'warehouseId': destinationWarehouseId,
            'productId': item.productId,
            'quantity': item.quantityInBaseUnit,
          });
        } else {
          await txn.rawUpdate(
            'UPDATE warehouse_stock SET quantity = quantity + ? WHERE warehouseId = ? AND productId = ?',
            [item.quantityInBaseUnit, destinationWarehouseId, item.productId],
          );
        }

        // --- ميزة المزامنة: تحديث جدول المنتجات الرئيسي إذا كانت الوجهة هي المخزن الرئيسي (ID=1) ---
        if (destinationWarehouseId == 1) {
          await txn.rawUpdate(
            'UPDATE products SET quantity = quantity + ? WHERE id = ?',
            [item.quantityInBaseUnit, item.productId],
          );
        }
      }
    });

    return transferId;
  }

  /// جلب جميع سندات التحويل
  Future<List<InventoryTransferModel>> getAllTransfers({int? warehouseId}) async {
    final db = await _dbService.database;

    String whereClause = '';
    List<dynamic> args = [];

    if (warehouseId != null) {
      whereClause = 'WHERE it.sourceWarehouseId = ? OR it.destinationWarehouseId = ?';
      args = [warehouseId, warehouseId];
    }

    final result = await db.rawQuery('''
      SELECT 
        it.*,
        sw.name as sourceWarehouseName,
        dw.name as destinationWarehouseName
      FROM inventory_transfers it
      LEFT JOIN warehouses sw ON it.sourceWarehouseId = sw.id
      LEFT JOIN warehouses dw ON it.destinationWarehouseId = dw.id
      $whereClause
      ORDER BY it.id DESC
    ''', args);

    return result.map((m) => InventoryTransferModel.fromMap(m)).toList();
  }

  /// جلب تفاصيل سند تحويل
  Future<List<InventoryTransferItemModel>> getTransferItems(int transferId) async {
    final db = await _dbService.database;
    final result = await db.query(
      'inventory_transfer_items',
      where: 'transferId = ?',
      whereArgs: [transferId],
    );
    return result.map((m) => InventoryTransferItemModel.fromMap(m)).toList();
  }

  /// جلب سند تحويل بالمعرف
  Future<InventoryTransferModel?> getTransferById(int id) async {
    final db = await _dbService.database;
    final result = await db.rawQuery('''
      SELECT 
        it.*,
        sw.name as sourceWarehouseName,
        dw.name as destinationWarehouseName
      FROM inventory_transfers it
      LEFT JOIN warehouses sw ON it.sourceWarehouseId = sw.id
      LEFT JOIN warehouses dw ON it.destinationWarehouseId = dw.id
      WHERE it.id = ?
    ''', [id]);
    if (result.isEmpty) return null;
    return InventoryTransferModel.fromMap(result.first);
  }

  /// جلب إجمالي العُهد المُصرفة لمخزن معين خلال فترة
  Future<Map<String, double>> getTotalTransfersToWarehouse(
    int warehouseId, {
    DateTime? from,
    DateTime? to,
  }) async {
    final db = await _dbService.database;
    
    String whereClause = "destinationWarehouseId = ? AND status = 'COMPLETED'";
    List<dynamic> args = [warehouseId];

    if (from != null) {
      whereClause += ' AND transferDate >= ?';
      args.add(from.toIso8601String());
    }
    if (to != null) {
      final inclusiveTo = to.add(const Duration(days: 1));
      whereClause += ' AND transferDate < ?';
      args.add(inclusiveTo.toIso8601String());
    }

    final result = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(totalValue), 0) as totalSaleValue,
        COALESCE(SUM(totalCostValue), 0) as totalCostValue,
        COUNT(id) as transferCount
      FROM inventory_transfers 
      WHERE $whereClause
    ''', args);

    final row = result.first;
    return {
      'totalSaleValue': (row['totalSaleValue'] as num?)?.toDouble() ?? 0.0,
      'totalCostValue': (row['totalCostValue'] as num?)?.toDouble() ?? 0.0,
      'transferCount': (row['transferCount'] as num?)?.toDouble() ?? 0.0,
    };
  }
}

/// كلاس مساعد لإدخال بيانات الصنف عند إنشاء سند تحويل
class TransferItemInput {
  final int productId;
  final String productName;
  final double quantity;
  final double quantityInBaseUnit;
  final int? unitId;
  final double salePrice;
  final double purchasePrice;

  TransferItemInput({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.quantityInBaseUnit,
    this.unitId,
    required this.salePrice,
    required this.purchasePrice,
  });
}
