import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import 'package:ehab_company_admin/features/units/presentation/controllers/unit_controller.dart';
import 'package:ehab_company_admin/features/warehouses/data/models/custody_model.dart';
import 'package:ehab_company_admin/features/warehouses/data/models/inventory_transfer_model.dart';
import 'package:ehab_company_admin/features/warehouses/data/models/settlement_model.dart';
import 'package:ehab_company_admin/features/warehouses/data/models/warehouse_model.dart';
import 'package:ehab_company_admin/features/warehouses/data/repositories/custody_repository.dart';
import 'package:ehab_company_admin/features/warehouses/data/repositories/inventory_transfer_repository.dart';
import 'package:ehab_company_admin/features/warehouses/presentation/controllers/inventory_transfer_controller.dart';
import 'package:ehab_company_admin/features/warehouses/presentation/controllers/warehouse_controller.dart';
import 'settlement_detail_screen.dart';
import 'transfer_detail_screen.dart';

class WarehouseDetailScreen extends StatelessWidget {
  final WarehouseModel warehouse;

  const WarehouseDetailScreen({super.key, required this.warehouse});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final warehouseController = Get.find<WarehouseController>();
    final unitController = Get.find<UnitController>();
    final custodyRepository = CustodyRepository();
    final transferRepository = InventoryTransferRepository();

    if (!Get.isRegistered<InventoryTransferController>()) {
      Get.put(InventoryTransferController());
    }

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(warehouse.salesRepName ?? warehouse.name),
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            dividerColor: Colors.transparent,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
            tabs: [
              Tab(text: 'العهدة الحالية'),
              Tab(text: 'سندات التسليم'),
              Tab(text: 'التسويات'),
              Tab(text: 'الحركة المالية'),
            ],
          ),
        ),
        body: Column(
          children: [
            FutureBuilder<WarehouseDashboardModel>(
              future: warehouseController.getWarehouseDashboard(warehouse.id!),
              builder: (context, snapshot) {
                final data = snapshot.data;
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.primaryColor,
                        theme.primaryColor.withBlue(160),
                      ],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildHeaderStat(
                        'قيمة العهدة',
                        data?.currentValue ?? 0.0,
                      ),
                      _buildHeaderStat('مديونية', warehouse.balance),
                      _buildHeaderStat(
                        'الأصناف',
                        (data?.productCount ?? 0).toDouble(),
                        digits: 0,
                      ),
                    ],
                  ),
                );
              },
            ),
            Expanded(
              child: TabBarView(
                children: [
                  FutureBuilder<List<CustodyProductSummary>>(
                    future: warehouseController.getCurrentCustodyProducts(
                      warehouse.id!,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final products =
                          snapshot.data ?? const <CustodyProductSummary>[];
                      if (products.isEmpty) {
                        return const Center(
                          child: Text('لا توجد عهدة جارية على هذا المندوب.'),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: products.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = products[index];
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: theme.primaryColor
                                      .withOpacity(0.1),
                                  child: Text(
                                    item.quantity.toStringAsFixed(0),
                                    style: TextStyle(
                                      color: theme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.productName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (item.productCode != null)
                                        Text(
                                          item.productCode!,
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 11,
                                          ),
                                        ),
                                      const SizedBox(height: 4),
                                      Text(
                                        unitController.formatSmartQuantity(
                                          item.unitId,
                                          item.quantity,
                                        ),
                                        style: TextStyle(
                                          color: theme.primaryColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      item.currentValue.toStringAsFixed(2),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'دفعات: ${item.layerCount}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  FutureBuilder<List<InventoryTransferModel>>(
                    future: transferRepository.getAllTransfers(
                      warehouseId: warehouse.id,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final transfers =
                          snapshot.data ?? const <InventoryTransferModel>[];
                      if (transfers.isEmpty) {
                        return const Center(
                          child: Text('لا توجد سندات تسليم مسجلة.'),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: transfers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final transfer = transfers[index];
                          return ListTile(
                            tileColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: Text('سند #${transfer.id}'),
                            subtitle: Text(
                              intl.DateFormat(
                                'yyyy/MM/dd - hh:mm a',
                                'ar',
                              ).format(transfer.transferDate),
                            ),
                            trailing: Text(
                              transfer.totalValue.toStringAsFixed(2),
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onTap: () => Get.to(
                              () => TransferDetailScreen(
                                transferId: transfer.id!,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  FutureBuilder<List<CustodySettlementModel>>(
                    future: custodyRepository.getWarehouseSettlements(
                      warehouse.id!,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final settlements =
                          snapshot.data ?? const <CustodySettlementModel>[];
                      if (settlements.isEmpty) {
                        return const Center(
                          child: Text('لا توجد تسويات مسجلة.'),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: settlements.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final settlement = settlements[index];
                          return ListTile(
                            tileColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: Text('تسوية #${settlement.id}'),
                            subtitle: Text(
                              'مباع: ${settlement.totalSoldValue.toStringAsFixed(2)} | مستلم: ${settlement.receivedAmount.toStringAsFixed(2)}',
                            ),
                            trailing: Text(
                              settlement.settlementDifference.toStringAsFixed(
                                2,
                              ),
                              style: TextStyle(
                                color: settlement.settlementDifference > 0
                                    ? Colors.red.shade700
                                    : Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onTap: () => Get.to(
                              () => SettlementDetailScreen(
                                settlement: settlement,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  FutureBuilder<List<WarehouseTransactionModel>>(
                    future: custodyRepository.getWarehouseTransactions(
                      warehouse.id!,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final transactions =
                          snapshot.data ?? const <WarehouseTransactionModel>[];
                      if (transactions.isEmpty) {
                        return const Center(
                          child: Text('لا توجد حركة مالية على هذا المندوب.'),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: transactions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final tx = transactions[index];
                          final bool isDebt = tx.amount >= 0;
                          return ListTile(
                            tileColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: Text(
                              tx.type == 'custody_settlement'
                                  ? 'أثر تسوية عهدة'
                                  : tx.type,
                            ),
                            subtitle: Text(
                              intl.DateFormat(
                                'yyyy/MM/dd - hh:mm a',
                                'ar',
                              ).format(tx.transactionDate),
                            ),
                            trailing: Text(
                              tx.amount.toStringAsFixed(2),
                              style: TextStyle(
                                color: isDebt
                                    ? Colors.red.shade700
                                    : Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStat(String label, double value, {int digits = 2}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value.toStringAsFixed(digits),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  void _showSettlementItems(
    CustodySettlementModel settlement,
    CustodyRepository repository,
  ) {
    Get.bottomSheet(
      FutureBuilder<List<CustodySettlementItemModel>>(
        future: repository.getSettlementItems(settlement.id!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final items = snapshot.data ?? const <CustodySettlementItemModel>[];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تفاصيل التسوية #${settlement.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.6,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(item.productName),
                          subtitle: Text(
                            'مباع: ${item.soldQty.toStringAsFixed(2)} | مرتجع: ${item.returnedQty.toStringAsFixed(2)} | متبقٍ: ${item.remainingQty.toStringAsFixed(2)}',
                          ),
                          trailing: Text(item.soldValue.toStringAsFixed(2)),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }
}
