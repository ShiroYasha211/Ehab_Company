// File: lib/features/warehouses/presentation/screens/transfer_history_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import '../controllers/inventory_transfer_controller.dart';
import 'transfer_detail_screen.dart';

class TransferHistoryScreen extends StatelessWidget {
  const TransferHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<InventoryTransferController>()) {
      Get.put(InventoryTransferController());
    }
    final controller = Get.find<InventoryTransferController>();
    controller.fetchAllTransfers();

    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل التحويلات المخزنية'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.transfers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.swap_horiz_rounded, size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text('لا توجد تحويلات بعد',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.transfers.length,
          itemBuilder: (context, index) {
            final transfer = controller.transfers[index];
            final dateStr = intl.DateFormat('yyyy/MM/dd - hh:mm a', 'ar')
                .format(transfer.transferDate);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '#${transfer.id}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ),
                title: Row(
                  children: [
                    Flexible(
                      child: Text(
                        transfer.sourceWarehouseName ?? 'مصدر',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.arrow_forward, size: 16, color: Colors.grey.shade500),
                    ),
                    Flexible(
                      child: Text(
                        transfer.destinationWarehouseName ?? 'وجهة',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.orange.shade700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(dateStr, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      transfer.totalValue.toStringAsFixed(0),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                        fontSize: 15,
                      ),
                    ),
                    const Text('قيمة العهدة', style: TextStyle(fontSize: 10)),
                  ],
                ),
                onTap: () => Get.to(() => TransferDetailScreen(transferId: transfer.id!)),
              ),
            );
          },
        );
      }),
    );
  }
}
