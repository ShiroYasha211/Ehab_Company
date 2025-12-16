// File: lib/features/expenses/presentation/screens/expenses_dashboard_screen.dart

// --- 1. بداية التعديل: إضافة import جديد ---
import 'package:ehab_company_admin/features/expenses/presentation/screens/manage_expense_categories_screen.dart';
// --- نهاية التعديل ---
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'add_expense_screen.dart';
import 'expenses_binding.dart';
import 'expenses_reports_screen.dart';
import 'list_expenses_screen.dart';

class ExpensesDashboardScreen extends StatelessWidget {
  const ExpensesDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المصروفات'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildDashboardItem(
            context: context,
            icon: Icons.price_change_outlined,
            title: 'تسجيل مصروف جديد',
            subtitle: 'تسجيل المصروفات اليومية والنثرية.',
            onTap: () {
              Get.to(() => const AddExpenseScreen());
            },
          ),
          _buildDashboardItem(
            context: context,
            icon: Icons.list_alt_rounded,
            title: 'أرشيف المصروفات',
            subtitle: 'عرض كل المصروفات مع البحث والفلترة.',
            onTap: () {
              // لا حاجة للـ Binding هنا لأنه موجود في الـ Route الرئيسي
              Get.to(() => const ListExpensesScreen(),
              binding: ExpensesBinding());
            },
          ),
          _buildDashboardItem(
            context: context,
            icon: Icons.category_outlined,
            title: 'إدارة بنود المصروفات',
            subtitle: 'إضافة وتعديل بنود تصنيف المصروفات.',
            onTap: () {
              // --- 2. بداية التعديل: تفعيل الزر ---
              Get.to(() => const ManageExpenseCategoriesScreen(),
              binding: ExpensesBinding());
              // --- نهاية التعديل ---
            },
            isAdvanced: true,
          ),
          _buildDashboardItem(
            context: context,
            icon: Icons.bar_chart_rounded,
            title: 'تقارير المصروفات',
            subtitle: 'تحليل المصروفات حسب البنود والفترة.',
            onTap: () {
              Get.to(() => const ExpensesReportsScreen(),
              binding: ExpensesBinding());
            },
            isAdvanced: true,
          ),
        ],
      ),
    );
  }

  /// ودجت مساعد لبناء كل عنصر في لوحة التحكم (مطابق لتصميم الأقسام الأخرى)
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
