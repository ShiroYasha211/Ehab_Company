// File: lib/features/sales/presentation/screens/sales_dashboard_screen.dart

// --- 1. بداية التعديل: إضافة imports جديدة ---
import 'package:ehab_company_admin/features/sales/presentation/screens/add_sales_invoice_binding.dart';
import 'package:ehab_company_admin/features/sales/presentation/screens/add_sales_invoice_screen.dart';
import 'package:ehab_company_admin/features/customers/presentation/screens/customers_dashboard_screen.dart';
// --- نهاية التعديل ---
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'list_sales_invoices_screen.dart';
import 'package:ehab_company_admin/features/financial_docs/presentation/screens/list_receipt_vouchers_screen.dart';

class SalesDashboardScreen extends StatelessWidget {
  const SalesDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المبيعات'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildDashboardItem(
            context: context,
            icon: Icons.point_of_sale_rounded,
            title: 'فاتورة مبيعات جديدة',
            subtitle: 'تسجيل فاتورة مبيعات جديدة وخصم المخزون',
            onTap: () {
              // --- 2. بداية التعديل: تفعيل الزر مع Binding ---
              Get.to(() => const AddSalesInvoiceScreen(),
                  binding: AddSalesInvoiceBinding());
              // --- نهاية التعديل ---
            },
          ),
          _buildDashboardItem(
            context: context,
            icon: Icons.inventory_outlined,
            title: 'عرض كل الفواتير',
            subtitle: 'تصفح وبحث في أرشيف فواتير المبيعات',
            onTap: () {

                Get.to(() => const ListSalesInvoicesScreen(),
                binding: AddSalesInvoiceBinding());
            },
          ),
          _buildDashboardItem(
            context: context,
            icon: Icons.assignment_return_rounded,
            title: 'إدارة المرتجعات',
            subtitle: 'سجل المرتجعات التفصيلي، الأسباب، والإحصائيات',
            isAdvanced: true,
            onTap: () {
               // سيتم توجيه المستخدم لشاشة المرتجعات الجديدة
               Get.toNamed('/sales/returns');
            },
          ),
          _buildDashboardItem(
            context: context,
            icon: Icons.download_done_rounded,
            title: 'أرشيف سندات القبض',
            subtitle: 'عرض كافة سندات التحصيل والقبض من العملاء',
            isAdvanced: true,
            onTap: () {
               Get.to(() => const ListReceiptVouchersScreen());
            },
          ),
          _buildDashboardItem(
            context: context,
            icon: Icons.people_outline_rounded,
            title: 'إدارة العملاء',
            subtitle: 'إضافة عملاء جدد، تتبع حساباتهم، وكشوفات الأرصدة',
            isAdvanced: true,
            onTap: () {
              Get.to(() => const CustomersDashboardScreen());
            },
          ),
        ],
      ),
    );
  }

  /// ودجت مساعد لبناء كل عنصر في لوحة التحكم (مطابق لتصميم المشتريات)
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
