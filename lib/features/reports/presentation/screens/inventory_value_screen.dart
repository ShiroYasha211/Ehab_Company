// File: lib/features/reports/presentation/screens/inventory_value_screen.dart

import 'package:ehab_company_admin/features/products/presentation/controllers/product_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;

class InventoryValueScreen extends StatelessWidget {
  const InventoryValueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // استخدم Get.find لأنه يفترض أن ProductController مهيأ بالفعل
    // إذا لم يكن كذلك، سنحتاج إلى تعديل الـ Binding
    final ProductController controller = Get.find<ProductController>();
    final formatCurrency =
    intl.NumberFormat.currency(locale: 'ar_SA', symbol: ' ريال');

    // استدعاء دالة الحساب عند بناء الشاشة
    controller.getInventoryValue();

    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير قيمة المخزون'),
      ),
      body: RefreshIndicator(
        onRefresh: controller.getInventoryValue,
        child: Center(
          child: Obx(() {
            if (controller.isCalculatingValue.isTrue) {
              return const CircularProgressIndicator();
            }
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // 1. البطاقة الرئيسية: قيمة المخزون بسعر الشراء
                _buildValueCard(
                  title: 'قيمة المخزون الحالية',
                  subtitle: '(بسعر الشراء)',
                  value: formatCurrency.format(controller.totalPurchaseValue.value),
                  icon: Icons.inventory_2_outlined,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 24),
                // 2. البطاقة الثانوية: القيمة المتوقعة بسعر البيع
                _buildValueCard(
                  title: 'القيمة المتوقعة للمخزون',
                  subtitle: '(بسعر البيع)',
                  value: formatCurrency.format(controller.totalSaleValue.value),
                  icon: Icons.trending_up_rounded,
                  color: Colors.green.shade700,
                  isSecondary: true,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  /// ودجت مساعد لبناء بطاقة عرض القيمة
  Widget _buildValueCard({
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
    required Color color,
    bool isSecondary = false,
  }) {
    return Card(
      elevation: isSecondary ? 2 : 6,
      color: isSecondary ? Get.theme.cardColor : color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: isSecondary ? color.withOpacity(0.1) : Colors.white24,
              child: Icon(icon,
                  size: 32, color: isSecondary ? color : Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isSecondary ? Get.theme.textTheme.bodyLarge?.color : Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: isSecondary ? Colors.grey.shade600 : Colors.white70,
              ),
            ),
            const Divider(height: 32),
            Text(
              value,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: isSecondary ? color : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
