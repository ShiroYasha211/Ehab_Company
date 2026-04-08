import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/custody_model.dart';
import '../../data/models/warehouse_model.dart';
import '../controllers/settlement_controller.dart';
import '../controllers/warehouse_controller.dart';
import 'add_edit_warehouse_screen.dart';
import 'create_transfer_screen.dart';
import 'manual_settlement_screen.dart';
import 'transfer_history_screen.dart';
import 'warehouse_detail_screen.dart';

class WarehousesScreen extends StatelessWidget {
  const WarehousesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WarehouseController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المخازن والعهد'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'سجل التسليمات',
            onPressed: () => Get.to(() => const TransferHistoryScreen()),
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
              label: const Text('إضافة مندوب'),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final mainWarehouse = controller.mainWarehouse;
        final reps = controller.repWarehouses;
        final bottomPadding = MediaQuery.of(context).padding.bottom + 140;

        return SafeArea(
          bottom: true,
          child: RefreshIndicator(
            onRefresh: controller.fetchAllWarehouses,
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
              children: [
                if (mainWarehouse != null) ...[
                  _buildMainWarehouseCard(controller, mainWarehouse, theme),
                  const SizedBox(height: 20),
                ],
                Text(
                  'العهد الميدانية',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (reps.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Center(
                      child: Text('لا يوجد مندوبون مسجلون حالياً'),
                    ),
                  )
                else
                  ...reps.map(
                    (warehouse) => _buildRepCard(
                      controller: controller,
                      warehouse: warehouse,
                      theme: theme,
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildMainWarehouseCard(
    WarehouseController controller,
    WarehouseModel warehouse,
    ThemeData theme,
  ) {
    return FutureBuilder<Map<String, dynamic>>(
      future: controller.getWarehouseReport(warehouse.id!),
      builder: (context, snapshot) {
        final report = snapshot.data ?? const {};
        final totalProducts = report['totalProducts'] ?? 0;
        final totalQuantity = (report['totalQuantity'] ?? 0.0) as double;
        final totalSaleValue = (report['totalSaleValue'] ?? 0.0) as double;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.primaryColor, theme.primaryColor.withBlue(200)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'المخزن الرئيسي',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildMainStat('أصناف', totalProducts.toString()),
                  _buildMainStat('كمية', totalQuantity.toStringAsFixed(0)),
                  _buildMainStat('قيمة', totalSaleValue.toStringAsFixed(0)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainStat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
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

  Widget _buildRepCard({
    required WarehouseController controller,
    required WarehouseModel warehouse,
    required ThemeData theme,
  }) {
    return FutureBuilder<WarehouseDashboardModel>(
      future: controller.getWarehouseDashboard(warehouse.id!),
      builder: (context, snapshot) {
        final dashboard = snapshot.data;
        final currentQty = dashboard?.currentQty ?? 0.0;
        final currentValue = dashboard?.currentValue ?? 0.0;
        final productCount = dashboard?.productCount ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.orange.withOpacity(0.12),
                      child: Text(
                        (warehouse.salesRepName?.isNotEmpty ?? false)
                            ? warehouse.salesRepName!.substring(0, 1)
                            : 'م',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            warehouse.salesRepName ?? warehouse.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            warehouse.salesRepPhone?.isNotEmpty == true
                                ? warehouse.salesRepPhone!
                                : 'بدون هاتف مسجل',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          Get.to(
                            () => AddEditWarehouseScreen(warehouse: warehouse),
                          );
                        } else if (value == 'delete') {
                          Get.defaultDialog(
                            title: 'حذف المندوب',
                            middleText:
                                'لن يتم حذف المندوب إذا كانت عليه عهدة أو مديونية قائمة.',
                            textConfirm: 'حذف',
                            textCancel: 'إلغاء',
                            confirmTextColor: Colors.white,
                            onConfirm: () {
                              Get.back();
                              controller.deleteWarehouse(warehouse.id!);
                            },
                          );
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('تعديل')),
                        PopupMenuItem(value: 'delete', child: Text('حذف')),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildRepStat(
                      'الأصناف الحالية',
                      productCount.toString(),
                      Icons.inventory_2_outlined,
                      Colors.blue,
                    ),
                    _buildRepStat(
                      'كمية العهدة',
                      currentQty.toStringAsFixed(0),
                      Icons.shopping_bag_outlined,
                      Colors.orange,
                    ),
                    _buildRepStat(
                      'قيمة العهدة',
                      currentValue.toStringAsFixed(0),
                      Icons.payments_outlined,
                      Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: warehouse.balance > 0
                        ? Colors.red.shade50
                        : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'المديونية الحالية',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        warehouse.balance.toStringAsFixed(2),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: warehouse.balance > 0
                              ? Colors.red.shade700
                              : Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Get.to(
                          () => WarehouseDetailScreen(warehouse: warehouse),
                        ),
                        icon: const Icon(Icons.dashboard_customize_outlined),
                        label: const Text('تفاصيل'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final settlementController =
                              Get.isRegistered<SettlementController>()
                              ? Get.find<SettlementController>()
                              : Get.put(SettlementController());
                          settlementController.selectWarehouse(warehouse);
                          Get.to(() => const ManualSettlementScreen());
                        },
                        icon: const Icon(Icons.assignment_turned_in_outlined),
                        label: const Text('تسوية'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRepStat(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
