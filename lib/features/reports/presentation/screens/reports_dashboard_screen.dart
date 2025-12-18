// File: lib/features/reports/presentation/screens/reports_dashboard_screen.dart

import 'package:ehab_company_admin/features/reports/presentation/screens/profit_and_loss_screen.dart';
import 'package:ehab_company_admin/features/reports/presentation/screens/reports_binding.dart';
import 'package:ehab_company_admin/features/reports/presentation/screens/top_selling_products_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'customer_debts_report_screen.dart';
import 'fund_flow_report_screen.dart';
import 'inventory_value_screen.dart';

class ReportsDashboardScreen extends StatelessWidget {
  const ReportsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مركز التقارير'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader(context, 'التقارير المالية'),
          _buildDashboardItem(
            context: context,
            icon: Icons.monetization_on_outlined,
            title: 'تقرير الأرباح والخسائر',
            subtitle: 'عرض صافي الربح بناءً على المبيعات والتكاليف والمصروفات.',
            onTap: () {
               Get.to(() => const ProfitAndLossScreen());
            },
          ),
          _buildDashboardItem(
            context: context,
            icon: Icons.swap_horiz_rounded,
            title: 'تقرير حركة الصندوق',
            subtitle: 'تحليل السيولة النقدية الداخلة والخارجة.',
            onTap: () {
            Get.to(() => const FundFlowReportScreen());
            },
          ),
          const SizedBox(height: 20),
          _buildSectionHeader(context, 'تقارير المبيعات والعملاء'),
          _buildDashboardItem(
            context: context,
            icon: Icons.trending_up_rounded,
            title: 'أفضل المنتجات مبيعًا',
            subtitle: 'عرض المنتجات الأكثر مبيعًا أو الأعلى تحقيقًا للإيراد.',
            onTap: () {
               Get.to(() => const TopSellingProductsScreen());
            },
            isAdvanced: true,
          ),
          _buildDashboardItem(
            context: context,
            icon: Icons.people_alt_outlined,
            title: 'تقرير ديون العملاء',
            subtitle: 'عرض قائمة بالعملاء الذين عليهم أرصدة مستحقة.',
            onTap: () {
               Get.to(() => const CustomerDebtsReportScreen(),
               binding: ReportsBinding());
            },
            isAdvanced: true,
          ),
          const SizedBox(height: 20),
          _buildSectionHeader(context, 'تقارير المخزون'),
          _buildDashboardItem(context: context,
            icon: Icons.inventory_2_outlined,
            title: 'تقرير قيمة المخزون',
            subtitle: 'حساب القيمة الإجمالية للمخزون الحالي بسعر الشراء.',
            onTap: () {
               Get.to(() => const InventoryValueScreen());
            },
            isAdvanced: true,
          ),
        ],
      ),
    );
  }

  // ودجت مساعد لعرض عنوان القسم
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
      child: Text(
        title,
        style: Theme
            .of(context)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.bold, color: Theme
            .of(context)
            .primaryColor),
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
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 12),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: isAdvanced
              ? theme.colorScheme.secondary.withOpacity(0.15)
              : theme.primaryColor.withOpacity(0.1),
          child: Icon(
            icon,
            size: 30,
            color: isAdvanced ? theme.colorScheme.secondary : theme
                .primaryColor,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        trailing: const Icon(
            Icons.arrow_forward_ios_rounded, size: 18, color: Colors.grey),
      ),
    );
  }
}