// File: lib/features/warehouses/data/repositories/settlement_repository.dart

import 'package:ehab_company_admin/core/database/database_service.dart';
import '../models/settlement_model.dart';

class SettlementRepository {
  final DatabaseService _dbService = DatabaseService();

  /// تنفيذ عملية التسوية اليدوية بالكامل كعملية ذرية
  Future<int> processSettlement({
    required int warehouseId,
    required double totalSales,
    required double totalReturned,
    required double totalCredit,
    required double amountPaid,
    required double deficit,
    required DateTime settlementDate,
    String? notes,
    String? paymentMethod,
    int? fundId,
    bool isStockCleared = false,
    bool isCreditToCustomers = false,
    required List<SettlementItemInput> items,
    List<CustomerCreditInput>? customerCredits,
  }) async {
    final db = await _dbService.database;
    int settlementId = -1;

    await db.transaction((txn) async {
      // 1. إدراج رأس التسوية
      settlementId = await txn.insert('settlements', {
        'warehouseId': warehouseId,
        'totalSales': totalSales,
        'totalReturned': totalReturned,
        'totalCredit': totalCredit,
        'amountPaid': amountPaid,
        'deficit': deficit,
        'settlementDate': settlementDate.toIso8601String(),
        'notes': notes,
        'paymentMethod': paymentMethod,
        'fundId': fundId,
        'isStockCleared': isStockCleared ? 1 : 0,
        'isCreditToCustomers': isCreditToCustomers ? 1 : 0,
        'createdAt': DateTime.now().toIso8601String(),
      });

      // 2. معالجة الأصناف (خصم المبيعات، معالجة المرتجع، تصفير العهدة، والتحصيل المالي التفصيلي)
      for (final item in items) {
        // إدراج سجل تفاصيل الصنف في التسوية (مع الحقول المالية الجديدة)
        await txn.insert('settlement_items', {
          'settlementId': settlementId,
          'productId': item.productId,
          'initialQty': item.initialQty,
          'soldQty': item.soldQty,
          'returnedQty': item.returnedQty,
          'unitId': item.unitId,
          'salePrice': item.salePrice,
          'cashAmount': item.cashAmount,
          'cashFundId': item.cashFundId,
          'bankAmount': item.bankAmount,
          'bankFundId': item.bankFundId,
          'bankDetails': item.bankDetails,
          'transferAmount': item.transferAmount,
          'transferFundId': item.transferFundId,
          'transferDetails': item.transferDetails,
          'creditAmount': item.creditAmount,
          'creditTarget': item.creditTarget,
          'customerId': item.customerId,
        });

        // أ. خصم الكمية من مخزن المندوب وتحديث المخزن الرئيسي (المنطق السابق لم يتغير)
        if (item.soldQty > 0) {
          await txn.rawUpdate(
            'UPDATE warehouse_stock SET quantity = quantity - ? WHERE warehouseId = ? AND productId = ?',
            [item.soldQtyInBaseUnit, warehouseId, item.productId],
          );
        }

        if (item.returnedQty > 0) {
          await txn.rawUpdate(
            'UPDATE warehouse_stock SET quantity = quantity - ? WHERE warehouseId = ? AND productId = ?',
            [item.returnedQtyInBaseUnit, warehouseId, item.productId],
          );
          await _updateWarehouseStock(txn, 1, item.productId, item.returnedQtyInBaseUnit);
          await txn.rawUpdate(
            'UPDATE products SET quantity = quantity + ? WHERE id = ?',
            [item.returnedQtyInBaseUnit, item.productId],
          );
        }

        if (isStockCleared) {
          double remaining = item.initialQtyInBaseUnit - item.soldQtyInBaseUnit - item.returnedQtyInBaseUnit;
          if (remaining > 0.001) {
            await txn.rawUpdate(
              'UPDATE warehouse_stock SET quantity = quantity - ? WHERE warehouseId = ? AND productId = ?',
              [remaining, warehouseId, item.productId],
            );
            await _updateWarehouseStock(txn, 1, item.productId, remaining);
            await txn.rawUpdate(
              'UPDATE products SET quantity = quantity + ? WHERE id = ?',
              [remaining, item.productId],
            );
          }
        }

        // ب. المعالجة المالية لكل صنف

        // 1. تحصيل نقدي (كاش)
        if (item.cashAmount > 0 && item.cashFundId != null) {
          await txn.insert('fund_transactions', {
            'fundId': item.cashFundId,
            'type': 'تحصيل نقدي (تسوية)',
            'amount': item.cashAmount,
            'description': 'تحصيل صنف ${item.productId} - تسوية $settlementId',
            'referenceId': settlementId,
            'transactionDate': settlementDate.toIso8601String(),
          });
          await txn.rawUpdate('UPDATE funds SET balance = balance + ? WHERE id = ?', [item.cashAmount, item.cashFundId]);
        }

        // 2. تحصيل بنكي
        if (item.bankAmount > 0 && item.bankFundId != null) {
          await txn.insert('fund_transactions', {
            'fundId': item.bankFundId,
            'type': 'تحصيل بنكي (تسوية)',
            'amount': item.bankAmount,
            'description': 'إيداع بنكي صنف ${item.productId} - $settlementId - ${item.bankDetails ?? ""}',
            'referenceId': settlementId,
            'transactionDate': settlementDate.toIso8601String(),
          });
          await txn.rawUpdate('UPDATE funds SET balance = balance + ? WHERE id = ?', [item.bankAmount, item.bankFundId]);
        }

        // 3. تحصيل حوالة
        if (item.transferAmount > 0 && item.transferFundId != null) {
          await txn.insert('fund_transactions', {
            'fundId': item.transferFundId,
            'type': 'تحصيل حوالة (تسوية)',
            'amount': item.transferAmount,
            'description': 'حوالة صنف ${item.productId} - $settlementId - ${item.transferDetails ?? ""}',
            'referenceId': settlementId,
            'transactionDate': settlementDate.toIso8601String(),
          });
          await txn.rawUpdate('UPDATE funds SET balance = balance + ? WHERE id = ?', [item.transferAmount, item.transferFundId]);
        }

        // 4. مبيعات آجلة
        if (item.creditAmount > 0) {
          if (item.creditTarget == 'customer' && item.customerId != null) {
            // تسجيل على العميل
            await txn.insert('customer_transactions', {
              'customerId': item.customerId,
              'type': 'مبيعات آجلة (تسوية)',
              'amount': item.creditAmount,
              'notes': 'تحميل مديونية صنف ${item.productId} من تسوية $settlementId',
              'transactionDate': settlementDate.toIso8601String(),
              'affectsFund': 0,
            });
            await txn.rawUpdate('UPDATE customers SET balance = balance + ? WHERE id = ?', [item.creditAmount, item.customerId]);
          } else {
            // تسجيل على المندوب (الافتراضي أو إذا تم اختيار المندوب)
            await txn.rawUpdate('UPDATE warehouses SET balance = balance + ? WHERE id = ?', [item.creditAmount, warehouseId]);
            await txn.insert('warehouse_transactions', {
              'warehouseId': warehouseId,
              'type': 'settlement_credit',
              'amount': item.creditAmount,
              'notes': 'مديونية آجلة صنف ${item.productId} من تسوية $settlementId',
              'transactionDate': settlementDate.toIso8601String(),
              'referenceId': settlementId,
            });
          }
        }
      }
    });

    return settlementId;
  }

  /// دالة مساعدة لتحديث رصيد مخزن معين (إضافة/تعديل)
  Future<void> _updateWarehouseStock(dynamic txn, int warehouseId, int productId, double qty) async {
    final existing = await txn.rawQuery(
      'SELECT id FROM warehouse_stock WHERE warehouseId = ? AND productId = ?',
      [warehouseId, productId],
    );

    if (existing.isEmpty) {
      await txn.insert('warehouse_stock', {
        'warehouseId': warehouseId,
        'productId': productId,
        'quantity': qty,
      });
    } else {
      await txn.rawUpdate(
        'UPDATE warehouse_stock SET quantity = quantity + ? WHERE warehouseId = ? AND productId = ?',
        [qty, warehouseId, productId],
      );
    }
  }

  /// جلب قائمة التسويات مع أسماء المخازن
  Future<List<Map<String, dynamic>>> getSettlements() async {
    final db = await _dbService.database;
    return await db.rawQuery('''
      SELECT s.*, w.name as warehouseName 
      FROM settlements s
      JOIN warehouses w ON s.warehouseId = w.id
      ORDER BY s.id DESC
    ''');
  }

  /// جلب حركات المندوب (كشف الحساب)
  Future<List<WarehouseTransactionModel>> getWarehouseTransactions(int warehouseId) async {
    final db = await _dbService.database;
    final result = await db.query(
      'warehouse_transactions',
      where: 'warehouseId = ?',
      whereArgs: [warehouseId],
      orderBy: 'transactionDate DESC',
    );
    return result.map((m) => WarehouseTransactionModel.fromMap(m)).toList();
  }
}

/// كلاسات مساعدة لمدخلات التسوية
class SettlementItemInput {
  final int productId;
  final double initialQty; // بالوحدة الأساسية
  final double initialQtyInBaseUnit;
  final double soldQty; // بالوحدة المختارة
  final double soldQtyInBaseUnit;
  final double returnedQty;
  final double returnedQtyInBaseUnit;
  final int? unitId;
  final double salePrice;

  // الحقول المالية الجديدة لكل صنف
  final double cashAmount;
  final int? cashFundId;
  final double bankAmount;
  final int? bankFundId;
  final String? bankDetails;
  final double transferAmount;
  final int? transferFundId;
  final String? transferDetails;
  final double creditAmount;
  final String? creditTarget; // 'rep' or 'customer'
  final int? customerId;

  SettlementItemInput({
    required this.productId,
    required this.initialQty,
    required this.initialQtyInBaseUnit,
    required this.soldQty,
    required this.soldQtyInBaseUnit,
    required this.returnedQty,
    required this.returnedQtyInBaseUnit,
    this.unitId,
    required this.salePrice,
    this.cashAmount = 0,
    this.cashFundId,
    this.bankAmount = 0,
    this.bankFundId,
    this.bankDetails,
    this.transferAmount = 0,
    this.transferFundId,
    this.transferDetails,
    this.creditAmount = 0,
    this.creditTarget,
    this.customerId,
  });
}

class CustomerCreditInput {
  final int customerId;
  final double amount;
  CustomerCreditInput({required this.customerId, required this.amount});
}
