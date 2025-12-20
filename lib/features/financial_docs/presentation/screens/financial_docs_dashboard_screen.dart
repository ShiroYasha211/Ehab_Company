// File: lib/features/financial_docs/presentation/screens/financial_docs_dashboard_screen.dart

import 'package:ehab_company_admin/features/purchases/presentation/screens/list_purchases_screen.dart';
import 'package:ehab_company_admin/features/sales/presentation/screens/list_sales_invoices_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'list_payment_vouchers_screen.dart';
import 'list_receipt_vouchers_screen.dart';

class FinancialDocsDashboardScreen extends StatelessWidget {
  const FinancialDocsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الفواتير والسندات'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildDashboardItem(
            context: context,
            icon: Icons.receipt_long_outlined,
            title: 'فواتير المشتريات',
            subtitle: 'عرض وبحث في أرشيف فواتير المشتريات.',
            onTap: () {
              // إعادة استخدام الشاشة الموجودة بالفعل
              Get.to(() => const ListPurchasesScreen());
            },
          ),
          _buildDashboardItem(
            context: context,
            icon: Icons.point_of_sale_outlined,
            title: 'فواتير المبيعات',
            subtitle: 'عرض وبحث في أرشيف فواتير المبيعات.',
            onTap: () {
              // إعادة استخدام الشاشة الموجودة بالفعل
              Get.to(() => const ListSalesInvoicesScreen());
            },
          ),
          _buildDashboardItem(
            context: context,
            icon: Icons.upload_file_rounded,
            title: 'سندات الدفع',
            subtitle: 'عرض كل سندات الدفع للموردين.',
            onTap: () {
            Get.to(() => const ListPaymentVouchersScreen());
            },
            isAdvanced: true,
          ),
          _buildDashboardItem(
            context: context,
            icon: Icons.download_done_rounded,
            title: 'سندات القبض',
            subtitle: 'عرض كل سندات القبض من العملاء.',
            onTap: () {
               Get.to(() => const ListReceiptVouchersScreen());
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
