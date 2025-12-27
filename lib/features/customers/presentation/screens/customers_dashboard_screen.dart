// File: lib/features/customers/presentation/screens/customers_dashboard_screen.dart

import 'package:ehab_company_admin/features/customers/presentation/controllers/customer_controller.dart';
import 'package:ehab_company_admin/features/customers/presentation/screens/add_edit_customer_screen.dart';
// --- 1. بداية التعديل: إضافة import جديد ---
import 'package:ehab_company_admin/features/customers/presentation/screens/add_customer_payment_screen.dart';
// --- نهاية التعديل ---
import 'package:ehab_company_admin/features/customers/presentation/screens/list_customers_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomersDashboardScreen extends StatelessWidget {
  const CustomersDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(CustomerController());
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة العملاء'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildDashboardItem(
            context: context,
            icon: Icons.person_add_alt_1_outlined,
            title: 'إضافة عميل جديد',
            subtitle: 'تسجيل عميل جديد في النظام',
            onTap: () {
              Get.to(() => const AddEditCustomerScreen());
            },
          ),
          _buildDashboardItem(
            context: context,
            icon: Icons.people_outline,
            title: 'عرض كل العملاء',
            subtitle: 'تصفح وبحث في قائمة العملاء وأرصدتهم',
            onTap: () {
              Get.to(() => const ListCustomersScreen());
            },
          ),
          _buildDashboardItem(
            context: context,
            icon: Icons.request_quote_outlined,
            title: 'سندات القبض',
            subtitle: 'تسجيل الدفعات المستلمة من العملاء',
            onTap: () {
              // --- 2. بداية التعديل: تفعيل الزر ---
              Get.to(() => const AddCustomerPaymentScreen());
              // --- نهاية التعديل ---
            },
            isAdvanced: true,
          ),
        ],
      ),
    );
  }

  /// ودجت مساعد لبناء كل عنصر في لوحة التحكم (مطابق لتصميم الموردين)
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
