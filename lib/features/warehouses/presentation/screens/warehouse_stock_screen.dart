// File: lib/features/warehouses/presentation/screens/warehouse_stock_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/warehouse_model.dart';
import '../controllers/warehouse_controller.dart';
import '../../../units/presentation/controllers/unit_controller.dart';

class WarehouseStockScreen extends StatelessWidget {
  final WarehouseModel warehouse;

  const WarehouseStockScreen({super.key, required this.warehouse});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WarehouseController>();
    final unitController = Get.find<UnitController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('أرصدة: ${warehouse.name}'),
      ),
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: controller.getWarehouseStock(warehouse.id!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final stock = snapshot.data ?? [];
            if (stock.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_outlined, size: 80, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text('لا توجد أرصدة في هذا المخزن',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('قم بإنشاء سند تحويل لإضافة بضاعة',
                        style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              );
            }

            // حساب الإجمالي
            double totalSaleValue = 0;
            double totalCostValue = 0;
            for (final item in stock) {
              final qty = (item['quantity'] as num).toDouble();
              totalSaleValue += qty * (item['salePrice'] as num).toDouble();
              totalCostValue += qty * (item['purchasePrice'] as num).toDouble();
            }

            return Column(
              children: [
                // ملخص القيمة
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.primaryColor.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      _buildSummary('عدد الأصناف', '${stock.length}', Colors.blue),
                      _buildSummary('قيمة البيع', totalSaleValue.toStringAsFixed(0), Colors.green),
                      _buildSummary('قيمة الشراء', totalCostValue.toStringAsFixed(0), Colors.orange),
                    ],
                  ),
                ),

                // القائمة
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: stock.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = stock[index];
                      final qty = (item['quantity'] as num).toDouble();
                      final salePrice = (item['salePrice'] as num).toDouble();
                      final isStopped = (item['isSalesStopped'] ?? 0) == 1;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              debugPrint('Product clicked: ${item['productName']}');
                              _showProductDetailSheet(context, item, theme, unitController);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Ink(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 45,
                                    height: 45,
                                    decoration: BoxDecoration(
                                      color: (qty > 0 ? Colors.green : Colors.red).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        qty.toInt().toString(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: qty > 0 ? Colors.green.shade700 : Colors.red.shade700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                item['productName'] ?? '',
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (isStopped) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: Colors.red,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Text('موقوف',
                                                    style: TextStyle(color: Colors.white, fontSize: 8)),
                                              ),
                                            ],
                                          ],
                                        ),
                                        if (item['productCode'] != null)
                                          Text(item['productCode'],
                                              style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                                        const SizedBox(height: 6),
                                        // عرض الكمية التفصيلية حسب الوحدات
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: theme.primaryColor.withOpacity(0.05),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: theme.primaryColor.withOpacity(0.1)),
                                          ),
                                          child: Text(
                                            unitController.formatSmartQuantity(item['unitId'], qty),
                                            style: TextStyle(
                                              fontSize: 12, 
                                              fontWeight: FontWeight.w500,
                                              color: theme.primaryColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${(qty * salePrice).toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: theme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showProductDetailSheet(BuildContext context, Map<String, dynamic> item, ThemeData theme, UnitController unitController) {
    final qty = (item['quantity'] as num).toDouble();
    final salePrice = (item['salePrice'] as num).toDouble();
    final purchasePrice = (item['purchasePrice'] as num).toDouble();
    final saleValue = qty * salePrice;
    final costValue = qty * purchasePrice;
    final profit = saleValue - costValue;

    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // مقبض السحب
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // الرأس (الاسم والكود)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.inventory_2_rounded, color: theme.primaryColor, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['productName'] ?? '',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'كود المنتج: ${item['productCode'] ?? 'بدون كود'}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                          if (item['category'] != null) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item['category'],
                                style: TextStyle(color: Colors.blue.shade700, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // تفصيل الكمية (بالأرقام والوحدات)
                const Text('تحليل الرصيد المتوفر', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('الكمية الإجمالية (بالوحدة الكبرى):', style: TextStyle(color: Colors.grey)),
                          Text('${qty.toStringAsFixed(2)} ${unitController.getUnitName(item['unitId'])}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.account_tree_outlined, size: 18, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              unitController.formatSmartQuantity(item['unitId'], qty),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                
                // البيانات المالية
                const Text('القيم المالية لهذه العهدة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    _buildValueCard('قيمة البيع', saleValue, Colors.green),
                    const SizedBox(width: 12),
                    _buildValueCard('قيمة التكلفة', costValue, Colors.orange),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade700, Colors.blue.shade500],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('هامش الربح المتوقع', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text('بناءً على الكمية الحالية', style: TextStyle(color: Colors.white54, fontSize: 10)),
                        ],
                      ),
                      Text(
                        '${profit.toStringAsFixed(2)} ريال',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                
                // زر الإغلاق
                SizedBox(
                  width: double.infinity,
                  height: 55, // زيادة الارتفاع لراحة النص العربي
                  child: ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'إغلاق التفاصيل', 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildValueCard(String label, double value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${value.toStringAsFixed(2)}',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color),
              ),
            ),
            const Text('ريال', style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
          ),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}
