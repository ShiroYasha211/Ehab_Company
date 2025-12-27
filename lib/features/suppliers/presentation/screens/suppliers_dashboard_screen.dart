// File: lib/features/suppliers/presentation/screens/suppliers_dashboard_screen.dart

import 'package:ehab_company_admin/features/suppliers/presentation/screens/list_suppliers_screen.dart';
import 'package:ehab_company_admin/features/suppliers/presentation/screens/suppliers_reports_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/supplier_controller.dart';
import 'add_edit_supplier_screen.dart';
import 'add_supplier_payment_screen.dart';

class SuppliersDashboardScreen extends StatelessWidget {
  const SuppliersDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(SupplierController());
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الموردين'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildDashboardItem(
            context: context,
            icon: Icons.person_add_alt_1_outlined,
            title: 'إضافة مورد جديد',
            subtitle: 'إدخال بيانات مورد جديد في النظام',
            onTap: () {
              Get.put(SupplierController());
              Get.to(() => const AddEditSupplierScreen());
            },
          ),
          _buildDashboardItem(
            context: context,
            icon: Icons.playlist_add_check_circle_outlined,
            title: 'عرض كل الموردين',
            subtitle: 'تصفح، بحث، وتعديل الموردين الحاليين',
            onTap: () {
              Get.to(() => const ListSuppliersScreen());
            },
          ),
          _buildDashboardItem(
            context: context,
            icon: Icons.account_balance_wallet_outlined,
            title: 'الأرصدة الافتتاحية والمدفوعات',
            subtitle: 'تسجيل الأرصدة السابقة أو دفعات نقدية للموردين',
            onTap: () {
              Get.to(() => const AddSupplierPaymentScreen());
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
