import 'package:ehab_company_admin/core/database/database_service.dart';
import 'package:ehab_company_admin/core/services/auth_service.dart';
import 'package:ehab_company_admin/features/warehouses/data/models/custody_model.dart';
import 'package:ehab_company_admin/features/warehouses/data/models/settlement_model.dart';
import 'package:get/get.dart';

class CustodySettlementInput {
  final int productId;
  final double soldQty;
  final double returnedQty;

  const CustodySettlementInput({
    required this.productId,
    required this.soldQty,
    required this.returnedQty,
  });
}

class CustodySettlementResult {
  final int settlementId;
  final double totalSoldValue;
  final double receivedAmount;
  final double settlementDifference;
  final double previousBalance;
  final double newBalance;

  const CustodySettlementResult({
    required this.settlementId,
    required this.totalSoldValue,
    required this.receivedAmount,
    required this.settlementDifference,
    required this.previousBalance,
    required this.newBalance,
  });
}

class DebtPaymentResult {
  final double paidAmount;
  final double previousBalance;
  final double newBalance;

  const DebtPaymentResult({
    required this.paidAmount,
    required this.previousBalance,
    required this.newBalance,
  });
}

class CustodyRepository {
  final DatabaseService _dbService = DatabaseService();

  Future<List<CustodyProductSummary>> getCurrentCustodyProducts(
    int warehouseId,
  ) async {
    final db = await _dbService.database;
    final result = await db.rawQuery(
      '''
      SELECT
        iti.productId,
        p.name as productName,
        p.code as productCode,
        p.unitId,
        p.allowedUnits,
        SUM(iti.remainingQuantityInBaseUnit) as quantity,
        SUM(iti.remainingQuantityInBaseUnit * iti.salePricePerBaseUnit) as currentValue,
        COUNT(iti.id) as layerCount
      FROM inventory_transfer_items iti
      JOIN inventory_transfers it ON iti.transferId = it.id
      JOIN products p ON iti.productId = p.id
      WHERE it.destinationWarehouseId = ?
        AND it.status = 'COMPLETED'
        AND iti.remainingQuantityInBaseUnit > 0.0001
      GROUP BY iti.productId, p.name, p.code, p.unitId, p.allowedUnits
      ORDER BY p.name ASC
    ''',
      [warehouseId],
    );

    return result.map(CustodyProductSummary.fromMap).toList();
  }

  Future<List<CustodyLayerModel>> getCurrentCustodyLayers(
    int warehouseId, {
    int? productId,
  }) async {
    final db = await _dbService.database;
    final args = <dynamic>[warehouseId];
    final buffer = StringBuffer('''
      SELECT
        iti.id as transferItemId,
        iti.transferId,
        iti.productId,
        iti.productName,
        p.code as productCode,
        p.unitId,
        iti.remainingQuantityInBaseUnit as remainingQty,
        iti.salePricePerBaseUnit,
        it.transferDate
      FROM inventory_transfer_items iti
      JOIN inventory_transfers it ON iti.transferId = it.id
      JOIN products p ON iti.productId = p.id
      WHERE it.destinationWarehouseId = ?
        AND it.status = 'COMPLETED'
        AND iti.remainingQuantityInBaseUnit > 0.0001
    ''');

    if (productId != null) {
      buffer.write(' AND iti.productId = ?');
      args.add(productId);
    }

    buffer.write(' ORDER BY it.transferDate ASC, iti.id ASC');
    final result = await db.rawQuery(buffer.toString(), args);
    return result.map(CustodyLayerModel.fromMap).toList();
  }

  Future<WarehouseDashboardModel> getWarehouseDashboard(int warehouseId) async {
    final db = await _dbService.database;

    final currentResult = await db.rawQuery(
      '''
      SELECT
        COUNT(DISTINCT iti.productId) as productCount,
        COALESCE(SUM(iti.remainingQuantityInBaseUnit), 0) as currentQty,
        COALESCE(SUM(iti.remainingQuantityInBaseUnit * iti.salePricePerBaseUnit), 0) as currentValue
      FROM inventory_transfer_items iti
      JOIN inventory_transfers it ON iti.transferId = it.id
      WHERE it.destinationWarehouseId = ?
        AND it.status = 'COMPLETED'
        AND iti.remainingQuantityInBaseUnit > 0.0001
    ''',
      [warehouseId],
    );

    final lastTransferResult = await db.rawQuery(
      '''
      SELECT MAX(transferDate) as lastTransferDate
      FROM inventory_transfers
      WHERE destinationWarehouseId = ? AND status = 'COMPLETED'
    ''',
      [warehouseId],
    );

    final lastSettlementResult = await db.rawQuery(
      '''
      SELECT MAX(settlementDate) as lastSettlementDate
      FROM custody_settlements
      WHERE warehouseId = ?
    ''',
      [warehouseId],
    );

    final currentRow = currentResult.first;
    final String? lastTransferDate =
        lastTransferResult.first['lastTransferDate'] as String?;
    final String? lastSettlementDate =
        lastSettlementResult.first['lastSettlementDate'] as String?;

    return WarehouseDashboardModel(
      warehouseId: warehouseId,
      currentQty: (currentRow['currentQty'] as num?)?.toDouble() ?? 0.0,
      currentValue: (currentRow['currentValue'] as num?)?.toDouble() ?? 0.0,
      productCount: (currentRow['productCount'] as num?)?.toInt() ?? 0,
      lastTransferDate: lastTransferDate != null
          ? DateTime.parse(lastTransferDate)
          : null,
      lastSettlementDate: lastSettlementDate != null
          ? DateTime.parse(lastSettlementDate)
          : null,
    );
  }

  Future<List<CustodySettlementModel>> getWarehouseSettlements(
    int warehouseId,
  ) async {
    final db = await _dbService.database;
    final result = await db.rawQuery(
      '''
      SELECT
        cs.*,
        w.name as warehouseName
      FROM custody_settlements cs
      JOIN warehouses w ON cs.warehouseId = w.id
      WHERE cs.warehouseId = ?
      ORDER BY cs.settlementDate DESC, cs.id DESC
    ''',
      [warehouseId],
    );

    return result.map(CustodySettlementModel.fromMap).toList();
  }

  Future<List<CustodySettlementItemModel>> getSettlementItems(
    int settlementId,
  ) async {
    final db = await _dbService.database;
    final result = await db.query(
      'custody_settlement_items',
      where: 'settlementId = ?',
      whereArgs: [settlementId],
      orderBy: 'id ASC',
    );

    return result.map(CustodySettlementItemModel.fromMap).toList();
  }

  Future<List<WarehouseTransactionModel>> getWarehouseTransactions(
    int warehouseId,
  ) async {
    final db = await _dbService.database;
    final result = await db.query(
      'warehouse_transactions',
      where: 'warehouseId = ?',
      whereArgs: [warehouseId],
      orderBy: 'transactionDate DESC, id DESC',
    );
    return result.map(WarehouseTransactionModel.fromMap).toList();
  }

  Future<CustodySettlementResult> processManualSettlement({
    required int warehouseId,
    required List<CustodySettlementInput> items,
    required double receivedAmount,
    String? paymentMethod,
    int? fundId,
    String? notes,
    DateTime? settlementDate,
  }) async {
    final db = await _dbService.database;
    final effectiveDate = settlementDate ?? DateTime.now();
    int settlementId = -1;

    await db.transaction((txn) async {
      if (receivedAmount > 0 && fundId == null) {
        throw Exception(
          'يجب اختيار الصندوق أو الحساب المالي عند تسجيل مبلغ مستلم.',
        );
      }

      final warehouseRows = await txn.query(
        'warehouses',
        columns: ['balance'],
        where: 'id = ?',
        whereArgs: [warehouseId],
        limit: 1,
      );
      if (warehouseRows.isEmpty) {
        throw Exception('المندوب المحدد غير موجود.');
      }

      final double previousBalance =
          (warehouseRows.first['balance'] as num?)?.toDouble() ?? 0.0;

      final plannedLayerUpdates = <Map<String, dynamic>>[];
      final plannedSettlementItems = <Map<String, dynamic>>[];
      final returnedByProduct = <int, double>{};
      final touchedProductIds = <int>{};
      double totalSoldValue = 0.0;

      for (final item in items) {
        if (item.soldQty < 0 || item.returnedQty < 0) {
          throw Exception('لا يمكن قبول قيم سالبة داخل التسوية.');
        }
        if (item.soldQty == 0 && item.returnedQty == 0) {
          continue;
        }

        final layers = await txn.rawQuery(
          '''
          SELECT
            iti.id as transferItemId,
            iti.transferId,
            iti.productId,
            iti.productName,
            iti.remainingQuantityInBaseUnit as remainingQty,
            iti.salePricePerBaseUnit,
            it.transferDate
          FROM inventory_transfer_items iti
          JOIN inventory_transfers it ON iti.transferId = it.id
          WHERE it.destinationWarehouseId = ?
            AND it.status = 'COMPLETED'
            AND iti.productId = ?
            AND iti.remainingQuantityInBaseUnit > 0.0001
          ORDER BY it.transferDate ASC, iti.id ASC
        ''',
          [warehouseId, item.productId],
        );

        final double availableQty = layers.fold<double>(
          0.0,
          (sum, row) =>
              sum + ((row['remainingQty'] as num?)?.toDouble() ?? 0.0),
        );
        final double requestedQty = item.soldQty + item.returnedQty;
        if (requestedQty > availableQty + 0.0001) {
          throw Exception('الكمية المدخلة تتجاوز العهدة الحالية لأحد الأصناف.');
        }

        double remainingSold = item.soldQty;
        double remainingReturned = item.returnedQty;

        for (final layer in layers) {
          if (remainingSold <= 0.0001 && remainingReturned <= 0.0001) {
            break;
          }

          final double layerQty =
              (layer['remainingQty'] as num?)?.toDouble() ?? 0.0;
          final double soldFromLayer = remainingSold > 0
              ? (remainingSold > layerQty ? layerQty : remainingSold)
              : 0.0;
          final double qtyAfterSold = layerQty - soldFromLayer;
          final double returnedFromLayer = remainingReturned > 0
              ? (remainingReturned > qtyAfterSold
                    ? qtyAfterSold
                    : remainingReturned)
              : 0.0;
          final double consumed = soldFromLayer + returnedFromLayer;

          if (consumed <= 0.0001) {
            continue;
          }

          final double remainingQty = layerQty - consumed;
          final double layerSalePrice =
              (layer['salePricePerBaseUnit'] as num?)?.toDouble() ?? 0.0;
          final double soldValue = soldFromLayer * layerSalePrice;
          totalSoldValue += soldValue;

          plannedLayerUpdates.add({
            'transferItemId': layer['transferItemId'],
            'remainingQty': remainingQty,
          });
          plannedSettlementItems.add({
            'transferItemId': layer['transferItemId'],
            'transferId': layer['transferId'],
            'productId': layer['productId'],
            'productName': layer['productName'],
            'availableQty': layerQty,
            'soldQty': soldFromLayer,
            'returnedQty': returnedFromLayer,
            'remainingQty': remainingQty,
            'salePricePerBaseUnit': layerSalePrice,
            'soldValue': soldValue,
            'transferDate': layer['transferDate'],
          });

          if (returnedFromLayer > 0) {
            returnedByProduct.update(
              item.productId,
              (value) => value + returnedFromLayer,
              ifAbsent: () => returnedFromLayer,
            );
          }

          touchedProductIds.add(item.productId);

          remainingSold -= soldFromLayer;
          remainingReturned -= returnedFromLayer;
        }
      }

      final double settlementDifference = totalSoldValue - receivedAmount;
      final double newBalance = previousBalance + settlementDifference;

      settlementId = await txn.insert('custody_settlements', {
        'warehouseId': warehouseId,
        'totalSoldValue': totalSoldValue,
        'receivedAmount': receivedAmount,
        'settlementDifference': settlementDifference,
        'previousBalance': previousBalance,
        'newBalance': newBalance,
        'paymentMethod': paymentMethod,
        'fundId': fundId,
        'notes': notes,
        'settlementDate': effectiveDate.toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
      });

      for (final update in plannedLayerUpdates) {
        await txn.rawUpdate(
          '''
          UPDATE inventory_transfer_items
          SET remainingQuantityInBaseUnit = ?
          WHERE id = ?
          ''',
          [update['remainingQty'], update['transferItemId']],
        );
      }

      for (final item in plannedSettlementItems) {
        await txn.insert('custody_settlement_items', {
          'settlementId': settlementId,
          'transferItemId': item['transferItemId'],
          'transferId': item['transferId'],
          'productId': item['productId'],
          'productName': item['productName'],
          'availableQty': item['availableQty'],
          'soldQty': item['soldQty'],
          'returnedQty': item['returnedQty'],
          'remainingQty': item['remainingQty'],
          'salePricePerBaseUnit': item['salePricePerBaseUnit'],
          'soldValue': item['soldValue'],
          'transferDate': item['transferDate'],
        });
      }

      for (final productId in touchedProductIds) {
        final repStockResult = await txn.rawQuery(
          '''
          SELECT COALESCE(SUM(iti.remainingQuantityInBaseUnit), 0) as quantity
          FROM inventory_transfer_items iti
          JOIN inventory_transfers it ON iti.transferId = it.id
          WHERE it.destinationWarehouseId = ?
            AND it.status = 'COMPLETED'
            AND iti.productId = ?
            AND iti.remainingQuantityInBaseUnit > 0.0001
        ''',
          [warehouseId, productId],
        );
        final double currentRepQty =
            (repStockResult.first['quantity'] as num?)?.toDouble() ?? 0.0;

        final existingRepStock = await txn.rawQuery(
          'SELECT id FROM warehouse_stock WHERE warehouseId = ? AND productId = ?',
          [warehouseId, productId],
        );

        if (existingRepStock.isEmpty) {
          await txn.insert('warehouse_stock', {
            'warehouseId': warehouseId,
            'productId': productId,
            'quantity': currentRepQty,
          });
        } else {
          await txn.rawUpdate(
            '''
            UPDATE warehouse_stock
            SET quantity = ?
            WHERE warehouseId = ? AND productId = ?
            ''',
            [currentRepQty, warehouseId, productId],
          );
        }
      }

      for (final entry in returnedByProduct.entries) {
        final existingStock = await txn.rawQuery(
          'SELECT id FROM warehouse_stock WHERE warehouseId = 1 AND productId = ?',
          [entry.key],
        );

        if (existingStock.isEmpty) {
          await txn.insert('warehouse_stock', {
            'warehouseId': 1,
            'productId': entry.key,
            'quantity': entry.value,
          });
        } else {
          await txn.rawUpdate(
            '''
            UPDATE warehouse_stock
            SET quantity = quantity + ?
            WHERE warehouseId = 1 AND productId = ?
            ''',
            [entry.value, entry.key],
          );
        }

        await txn.rawUpdate(
          'UPDATE products SET quantity = quantity + ? WHERE id = ?',
          [entry.value, entry.key],
        );
      }

      await txn.rawUpdate('UPDATE warehouses SET balance = ? WHERE id = ?', [
        newBalance,
        warehouseId,
      ]);

      await txn.insert('warehouse_transactions', {
        'warehouseId': warehouseId,
        'type': 'custody_settlement',
        'amount': settlementDifference,
        'notes':
            'تسوية عهدة رقم $settlementId. مبيعات: ${totalSoldValue.toStringAsFixed(2)} - مستلم: ${receivedAmount.toStringAsFixed(2)}',
        'transactionDate': effectiveDate.toIso8601String(),
        'referenceId': settlementId,
      });

      if (receivedAmount > 0 && fundId != null) {
        final fundResult = await txn.query(
          'funds',
          columns: ['balance'],
          where: 'id = ?',
          whereArgs: [fundId],
          limit: 1,
        );
        if (fundResult.isEmpty) {
          throw Exception('الصندوق أو الحساب المالي المحدد غير موجود.');
        }

        final double currentBalance =
            (fundResult.first['balance'] as num?)?.toDouble() ?? 0.0;
        final double newFundBalance = currentBalance + receivedAmount;
        final authService = Get.find<AuthService>();
        final user = authService.currentUser.value;

        await txn.insert('fund_transactions', {
          'fundId': fundId,
          'type': 'تحصيل عهدة',
          'amount': receivedAmount,
          'description': 'تحصيل من تسوية عهدة رقم: $settlementId',
          'referenceId': settlementId,
          'transactionDate': effectiveDate.toIso8601String(),
          'userId': user?.id,
          'userName': user?.name,
          'balanceAfter': newFundBalance,
          'notes': notes,
        });
        await txn.rawUpdate(
          'UPDATE funds SET balance = balance + ? WHERE id = ?',
          [receivedAmount, fundId],
        );
      }
    });

    final db2 = await _dbService.database;
    final resultRows = await db2.query(
      'custody_settlements',
      where: 'id = ?',
      whereArgs: [settlementId],
      limit: 1,
    );
    final row = resultRows.first;

    return CustodySettlementResult(
      settlementId: settlementId,
      totalSoldValue: (row['totalSoldValue'] as num?)?.toDouble() ?? 0.0,
      receivedAmount: (row['receivedAmount'] as num?)?.toDouble() ?? 0.0,
      settlementDifference:
          (row['settlementDifference'] as num?)?.toDouble() ?? 0.0,
      previousBalance: (row['previousBalance'] as num?)?.toDouble() ?? 0.0,
      newBalance: (row['newBalance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Future<DebtPaymentResult> collectDebtPayment({
    required int warehouseId,
    required double amount,
    required int fundId,
    required String paymentMethod,
    bool isPayout = false,
    String? transferNumber,
    String? senderName,
    String? receiverName,
    String? transferCompany,
    String? referenceType,
    String? bankName,
    String? bankReference,
    String? notes,
    DateTime? paymentDate,
  }) async {
    if (amount <= 0) {
      throw Exception('يجب أن يكون مبلغ السداد أكبر من صفر.');
    }

    final db = await _dbService.database;
    final effectiveDate = paymentDate ?? DateTime.now();

    double previousBalance = 0.0;
    double newBalance = 0.0;

    await db.transaction((txn) async {
      final warehouseRows = await txn.query(
        'warehouses',
        columns: ['balance', 'name'],
        where: 'id = ?',
        whereArgs: [warehouseId],
        limit: 1,
      );

      if (warehouseRows.isEmpty) {
        throw Exception('المندوب المحدد غير موجود.');
      }

      previousBalance =
          (warehouseRows.first['balance'] as num?)?.toDouble() ?? 0.0;

      if (!isPayout) {
        if (previousBalance <= 0.0001) {
          throw Exception('لا توجد مديونية قائمة على هذا المندوب.');
        }
        if (amount > previousBalance + 0.0001) {
          throw Exception(
            'مبلغ السداد أكبر من المديونية الحالية (${previousBalance.toStringAsFixed(2)}).',
          );
        }
      } else {
        if (previousBalance >= -0.0001) {
          throw Exception('لا يوجد رصيد دائن للمندوب لدى الشركة.');
        }
        if (amount > previousBalance.abs() + 0.0001) {
          throw Exception(
            'مبلغ السداد أكبر من الرصيد الدائن الحالي (${previousBalance.abs().toStringAsFixed(2)}).',
          );
        }
      }

      final fundRows = await txn.query(
        'funds',
        columns: ['balance'],
        where: 'id = ?',
        whereArgs: [fundId],
        limit: 1,
      );

      if (fundRows.isEmpty) {
        throw Exception('الصندوق أو الحساب المالي المحدد غير موجود.');
      }

      final authService = Get.find<AuthService>();
      final user = authService.currentUser.value;
      final currentFundBalance =
          (fundRows.first['balance'] as num?)?.toDouble() ?? 0.0;
      if (isPayout && currentFundBalance + 0.0001 < amount) {
        throw Exception(
          'رصيد الصندوق/الحساب غير كافٍ لإتمام السداد. المتاح: ${currentFundBalance.toStringAsFixed(2)}',
        );
      }
      final newFundBalance = isPayout
          ? currentFundBalance - amount
          : currentFundBalance + amount;
      newBalance = isPayout
          ? previousBalance + amount
          : previousBalance - amount;

      await txn.rawUpdate('UPDATE warehouses SET balance = ? WHERE id = ?', [
        newBalance,
        warehouseId,
      ]);

      final txId = await txn.insert('warehouse_transactions', {
        'warehouseId': warehouseId,
        'type': isPayout ? 'debt_payout' : 'debt_payment',
        'amount': isPayout ? amount : -amount,
        'notes':
            '${isPayout ? 'سداد للمندوب' : 'تحصيل من المندوب'} بمبلغ ${amount.toStringAsFixed(2)}. ${notes ?? ''}'
                .trim(),
        'transactionDate': effectiveDate.toIso8601String(),
      });

      await txn.insert('fund_transactions', {
        'fundId': fundId,
        'type': isPayout ? 'سداد مديونية مندوب' : 'تحصيل مديونية مندوب',
        'amount': amount,
        'description':
            '${isPayout ? 'سداد للمندوب' : 'تحصيل من المندوب'} رقم الحركة: $txId',
        'referenceId': txId,
        'transactionDate': effectiveDate.toIso8601String(),
        'userId': user?.id,
        'userName': user?.name,
        'balanceAfter': newFundBalance,
        'transferNumber': transferNumber,
        'senderName': senderName,
        'receiverName': receiverName,
        'transferCompany': transferCompany,
        'referenceType': referenceType ?? paymentMethod.toUpperCase(),
        'bankName': bankName,
        'bankReference': bankReference,
        'notes': notes,
      });

      await txn.rawUpdate(
        'UPDATE funds SET balance = balance ${isPayout ? '-' : '+'} ? WHERE id = ?',
        [amount, fundId],
      );
    });

    return DebtPaymentResult(
      paidAmount: amount,
      previousBalance: previousBalance,
      newBalance: newBalance,
    );
  }
}
