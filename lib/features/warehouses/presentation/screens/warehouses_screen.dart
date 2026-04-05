// File: lib/features/warehouses/presentation/screens/warehouses_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/warehouse_model.dart';
import '../controllers/warehouse_controller.dart';
import 'add_edit_warehouse_screen.dart';
import 'warehouse_stock_screen.dart';
import 'transfer_history_screen.dart';
import 'create_transfer_screen.dart';
import 'settlement_screen.dart';

class WarehousesScreen extends StatelessWidget {
  const WarehousesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WarehouseController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المخازن والعُهد'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'سجل التحويلات',
            onPressed: () => Get.to(() => const TransferHistoryScreen()),
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_rounded),
            tooltip: 'تسوية المندوبين',
            onPressed: () => Get.to(() => const SettlementScreen()),
          ),
        ],
      ),
      floatingActionButton: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton.small(
              heroTag: 'transfer',
              onPressed: () => Get.to(() => const CreateTransferScreen()),
              backgroundColor: Colors.orange,
              child: const Icon(Icons.swap_horiz_rounded, color: Colors.white),
            ),
            const SizedBox(height: 12),
            FloatingActionButton.extended(
              heroTag: 'addWarehouse',
              onPressed: () => Get.to(() => const AddEditWarehouseScreen()),
              label: const Text('إضافة مخزن فرعي'),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.warehouses.isEmpty) {
          return const Center(child: Text('لا توجد مخازن'));
        }

        return RefreshIndicator(
          onRefresh: controller.fetchAllWarehouses,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.warehouses.length,
            itemBuilder: (context, index) {
              final warehouse = controller.warehouses[index];
              return _buildWarehouseCard(context, warehouse, controller, theme);
            },
          ),
        );
      }),
    );
  }

  Widget _buildWarehouseCard(
    BuildContext context,
    WarehouseModel warehouse,
    WarehouseController controller,
    ThemeData theme,
  ) {
    final isMain = warehouse.isMain;
    final cardColor = isMain ? theme.primaryColor : Colors.orange;

    return FutureBuilder<Map<String, dynamic>>(
      future: controller.getWarehouseReport(warehouse.id!),
      builder: (context, snapshot) {
        final report = snapshot.data ?? {};
        final totalProducts = report['totalProducts'] ?? 0;
        final totalSaleValue = (report['totalSaleValue'] ?? 0.0) as double;
        final totalPurchaseValue = (report['totalPurchaseValue'] ?? 0.0) as double;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: cardColor.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // الهيدر مع الأيقونة والاسم
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor.withOpacity(0.05),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cardColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isMain ? Icons.warehouse_rounded : Icons.local_shipping_rounded,
                        color: cardColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                warehouse.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isMain ? Colors.blue.shade100 : Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isMain ? 'رئيسي' : 'فرعي',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isMain ? Colors.blue.shade700 : Colors.orange.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (warehouse.salesRepName != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'المندوب: ${warehouse.salesRepName}',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (!isMain)
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            Get.to(() => AddEditWarehouseScreen(warehouse: warehouse));
                          } else if (value == 'delete') {
                            Get.defaultDialog(
                              title: 'تأكيد الحذف',
                              middleText: 'هل أنت متأكد من حذف هذا المخزن؟',
                              textConfirm: 'حذف',
                              confirmTextColor: Colors.white,
                              onConfirm: () {
                                Get.back();
                                controller.deleteWarehouse(warehouse.id!);
                              },
                              textCancel: 'إلغاء',
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'edit', child: Text('تعديل')),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('حذف', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // الإحصائيات
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildStat('أصناف', totalProducts.toString(), Icons.inventory_2_outlined, Colors.blue),
                    _buildDivider(),
                    _buildStat('قيمة المبيع', totalSaleValue.toStringAsFixed(0), Icons.sell_outlined, Colors.green),
                    _buildDivider(),
                    _buildStat('قيمة الشراء', totalPurchaseValue.toStringAsFixed(0), Icons.shopping_cart_outlined, Colors.orange),
                  ],
                ),
              ),

              // أزرار الإجراءات
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Get.to(() => WarehouseStockScreen(warehouse: warehouse)),
                    icon: const Icon(Icons.list_alt_rounded),
                    label: const Text('عرض الأرصدة'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStat(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color),
            ),
          ),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.grey.shade200,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
