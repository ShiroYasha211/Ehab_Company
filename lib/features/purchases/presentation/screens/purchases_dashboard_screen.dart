// File: lib/features/purchases/presentation/screens/purchases_dashboard_screen.dart

import 'package:ehab_company_admin/features/purchases/presentation/screens/add_purchase_binding.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'add_purchase_invoice_screen.dart';
import 'list_purchases_screen.dart';

class PurchasesDashboardScreen extends StatelessWidget {
  const PurchasesDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المشتريات'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildDashboardItem(
            context: context,
            icon: Icons.add_shopping_cart_rounded,
            title: 'فاتورة شراء جديدة',
            subtitle: 'تسجيل فاتورة شراء جديدة وزيادة المخزون',
            onTap: () {
              Get.to(() => const AddPurchaseInvoiceScreen(),
              binding: AddPurchaseBinding());
            },
          ),
          _buildDashboardItem(
            context: context,
            icon: Icons.receipt_long_outlined,
            title: 'عرض كل الفواتير',
            subtitle: 'تصفح وبحث في أرشيف فواتير الشراء',
            onTap: () {
              Get.to(() => const ListPurchasesScreen());
              print('Navigate to List All Invoices');
            },
          ),
          _buildDashboardItem(
            context: context,
            icon: Icons.replay_circle_filled_rounded,
            title: 'مرتجعات المشتريات',
            subtitle: 'إدارة المنتجات المرتجعة للموردين',
            onTap: () {
              // TODO: Implement navigation to Purchase Returns Screen
              print('Navigate to Purchase Returns');
            },
            isAdvanced: true,
          ),
        ],
      ),
    );
  }

  /// ودجت مساعد لبناء كل عنصر في لوحة التحكم
  Widget _buildDashboardItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isAdvanced = false,
  }) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: isAdvanced
              ? theme.colorScheme.secondary.withOpacity(0.15)
              : theme.primaryColor.withOpacity(0.1),
          child: Icon(
            icon,
            size: 30,
            color: isAdvanced ? theme.colorScheme.secondary : theme.primaryColor,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.grey),
      ),
    );
  }
}
