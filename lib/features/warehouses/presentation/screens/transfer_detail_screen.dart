// File: lib/features/warehouses/presentation/screens/transfer_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import '../../data/models/inventory_transfer_model.dart';
import '../controllers/inventory_transfer_controller.dart';

class TransferDetailScreen extends StatelessWidget {
  final int transferId;

  const TransferDetailScreen({super.key, required this.transferId});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<InventoryTransferController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('سند تحويل #$transferId'),
      ),
      body: FutureBuilder(
        future: Future.wait([
          controller.getTransferById(transferId),
          controller.getTransferItems(transferId),
        ]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final transfer = snapshot.data?[0] as InventoryTransferModel?;
          final items = snapshot.data?[1] as List<InventoryTransferItemModel>? ?? [];

          if (transfer == null) {
            return const Center(child: Text('لم يتم العثور على السند'));
          }

          final dateStr = intl.DateFormat('yyyy/MM/dd - hh:mm a', 'ar')
              .format(transfer.transferDate);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // بطاقة المعلومات الرئيسية
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.shade400,
                      Colors.orange.shade700,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('سند تحويل #$transferId',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(transfer.status == 'COMPLETED' ? 'مكتمل' : 'مرتجع',
                              style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.white70, size: 14),
                        const SizedBox(width: 6),
                        Text(dateStr, style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 12),
                    // من -> إلى
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              const Text('من', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(transfer.sourceWarehouseName ?? '-',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward, color: Colors.white54),
                        Expanded(
                          child: Column(
                            children: [
                              const Text('إلى', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(transfer.destinationWarehouseName ?? '-',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // القيم
              Row(
                children: [
                  Expanded(
                    child: _buildValueCard('قيمة العهدة (بيع)', transfer.totalValue, Colors.green),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildValueCard('التكلفة (شراء)', transfer.totalCostValue, Colors.orange),
                  ),
                ],
              ),

              if (transfer.notes != null && transfer.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.note, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(child: Text(transfer.notes!)),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),
              const Text('تفاصيل الأصناف',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),

              // قائمة الأصناف
              ...items.map((item) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          item.quantity.toInt().toString(),
                          style: TextStyle(fontWeight: FontWeight.bold, color: theme.primaryColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            'بيع: ${item.salePrice.toStringAsFixed(2)} | شراء: ${item.purchasePrice.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(item.totalSaleValue.toStringAsFixed(0),
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                        Text(item.totalCostValue.toStringAsFixed(0),
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      ],
                    ),
                  ],
                ),
              )),
            ],
          );
        },
      ),
    );
  }

  Widget _buildValueCard(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value.toStringAsFixed(2),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: color),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}
