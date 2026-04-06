// File: lib/features/purchases/presentation/screens/purchases_dashboard_screen.dart

import 'package:ehab_company_admin/features/purchases/presentation/screens/add_purchase_binding.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'add_purchase_invoice_screen.dart';
import 'list_purchases_screen.dart';
import 'purchase_returns_list_screen.dart';
import 'package:ehab_company_admin/features/financial_docs/presentation/screens/list_payment_vouchers_screen.dart';
import 'package:ehab_company_admin/features/suppliers/presentation/screens/suppliers_dashboard_screen.dart';

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
            },
          ),
          _buildDashboardItem(
            context: context,
            icon: Icons.assignment_return_rounded,
            title: 'مركز إدارة المرتجعات',
            subtitle: 'تتبع وتحليل المشتريات المرتجعة وتقاريرها',
            onTap: () {
              Get.to(() => const PurchaseReturnsListScreen());
            },
            isAdvanced: true,
          ),
          _buildDashboardItem(
            context: context,
            icon: Icons.upload_file_rounded,
            title: 'أرشيف سندات الدفع',
            subtitle: 'عرض وتتبع كافة سندات الصرف للموردين',
            isAdvanced: true,
            onTap: () {
               Get.to(() => const ListPaymentVouchersScreen());
            },
          ),
          _buildDashboardItem(
            context: context,
            icon: Icons.local_shipping_rounded,
            title: 'إدارة الموردين',
            subtitle: 'بينات الموردين، حساباتهم، وتوريدات البضائع',
            isAdvanced: true,
            onTap: () {
               Get.to(() => const SuppliersDashboardScreen());
            },
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
