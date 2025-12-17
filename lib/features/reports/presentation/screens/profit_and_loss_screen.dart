// File: lib/features/reports/presentation/screens/profit_and_loss_screen.dart

import 'package:ehab_company_admin/features/reports/presentation/controllers/profit_and_loss_controller.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;

class ProfitAndLossScreen extends StatelessWidget {
  const ProfitAndLossScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ProfitAndLossController controller = Get.put(ProfitAndLossController());
    final formatCurrency =
    intl.NumberFormat.currency(locale: 'ar_SA', symbol: ' ريال');

    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير الأرباح والخسائر'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70.0),
          child: _buildFilters(context, controller),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.isTrue) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: controller.generateReport,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 1. بطاقة صافي الربح (الأهم)
              _buildNetProfitCard(controller.netProfit, formatCurrency),
              const SizedBox(height: 24),

              // 2. الرسم البياني للمقارنة
              Text('مقارنة الإيرادات بالتكاليف',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: BarChart(
                  _buildBarChartData(context, controller),
                  swapAnimationDuration: const Duration(milliseconds: 250),
                ),
              ),
              const Divider(height: 32),

              // 3. القائمة التفصيلية للأرقام
              _buildFinancialDetailsList(controller, formatCurrency),
            ],
          ),
        );
      }),
    );
  }

  /// ودجت بناء فلاتر التاريخ
  Widget _buildFilters(
      BuildContext context, ProfitAndLossController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: _buildDateField(context, controller, isFromDate: true),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildDateField(context, controller, isFromDate: false),
          ),
        ],
      ),
    );
  }

  /// ودجت بناء حقل التاريخ
  Widget _buildDateField(BuildContext context, ProfitAndLossController controller,
      {required bool isFromDate}) {
    return Obx(() {
      final date = isFromDate ? controller.fromDate.value : controller.toDate.value;
      return TextFormField(
        readOnly: true,
        controller: TextEditingController(
          text: intl.DateFormat('yyyy-MM-dd', 'en').format(date),
        ),
        onTap: () => controller.selectDate(context, isFromDate: isFromDate),
        decoration: InputDecoration(
          labelText: isFromDate ? 'من تاريخ' : 'إلى تاريخ',
          prefixIcon: const Icon(Icons.calendar_today_outlined),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          isDense: true,
        ),
      );
    });
  }

  /// ودجت بناء بطاقة صافي الربح
  Widget _buildNetProfitCard(double netProfit, intl.NumberFormat formatCurrency) {
    final bool isProfit = netProfit >= 0;
    final color = isProfit ? Colors.green.shade700 : Colors.red.shade700;

    return Card(
      elevation: 4,
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            children: [
              Text(
                isProfit ? 'صافي الربح' : 'صافي الخسارة',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                formatCurrency.format(netProfit.abs()), // عرض القيمة المطلقة
                style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ودجت بناء الرسم البياني الشريطي
  /// ودجت بناء الرسم البياني الشريطي
  BarChartData _buildBarChartData(
      BuildContext context, ProfitAndLossController controller) {
    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      // --- بداية التعديل: إضافة الشريط الثالث ---
      barGroups: [
        // 1. شريط الإيرادات
        BarChartGroupData(x: 0, barRods: [
          BarChartRodData(
              toY: controller.totalSales.value,
              color: Colors.blue.shade400,
              width: 25, // تقليل العرض قليلاً لإفساح المجال
              borderRadius: BorderRadius.circular(4))
        ]),
        // 2. شريط تكلفة البضاعة المباعة
        BarChartGroupData(x: 1, barRods: [
          BarChartRodData(
              toY: controller.costOfGoodsSold.value,
              color: Colors.orange.shade400,
              width: 25,
              borderRadius: BorderRadius.circular(4))
        ]),
        // 3. شريط المصروفات
        BarChartGroupData(x: 2, barRods: [
          BarChartRodData(
              toY: controller.totalExpenses.value,
              color: Colors.red.shade400,
              width: 25,
              borderRadius: BorderRadius.circular(4))
        ]),
      ],
      // --- نهاية التعديل ---
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              String text = '';
              // --- بداية التعديل: تحديث عناوين المحور السفلي ---
              if (value == 0) text = 'الإيرادات';
              if (value == 1) text = 'تكلفة البضاعة';
              if (value == 2) text = 'المصروفات';
              // --- نهاية التعديل ---
              return Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(text,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12)), // تصغير الخط قليلاً
              );
            },
            reservedSize: 30, // زيادة المساحة المحجوزة للعناوين
          ),
        ),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      gridData: const FlGridData(show: false),
    );
  }


  /// ودجت بناء القائمة التفصيلية للأرقام
  Widget _buildFinancialDetailsList(
      ProfitAndLossController controller, intl.NumberFormat formatCurrency) {
    return SafeArea(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              _buildDetailRow('(+) إجمالي إيرادات المبيعات',
                  formatCurrency.format(controller.totalSales.value), Colors.green),
              _buildDetailRow('(-) تكلفة البضاعة المباعة',
                  formatCurrency.format(controller.costOfGoodsSold.value), Colors.red),
              const Divider(),
              _buildDetailRow('= الربح الإجمالي',
                  formatCurrency.format(controller.grossProfit), Colors.black, isBold: true),
              const Divider(),
              _buildDetailRow('(-) إجمالي المصروفات',
                  formatCurrency.format(controller.totalExpenses.value), Colors.red),
              const Divider(thickness: 2),
              _buildDetailRow('= صافي الربح / الخسارة',
                  formatCurrency.format(controller.netProfit),
                  controller.netProfit >= 0 ? Colors.green.shade800 : Colors.red.shade800,
                  isBold: true, isLarge: true),
            ],
          ),
        ),
      ),
    );
  }

  /// ودجت مساعد لبناء كل صف في القائمة التفصيلية
  Widget _buildDetailRow(String label, String value, Color color,
      {bool isBold = false, bool isLarge = false}) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontSize: 16)),
      trailing: Text(
        value,
        style: TextStyle(
          color: color,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          fontSize: isLarge ? 18 : 16,
        ),
      ),
      dense: true,
    );
  }
}
