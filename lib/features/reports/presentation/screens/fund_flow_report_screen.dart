// File: lib/features/reports/presentation/screens/fund_flow_report_screen.dart

import 'package:ehab_company_admin/features/reports/presentation/controllers/fund_flow_report_controller.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;

class FundFlowReportScreen extends StatelessWidget {
  const FundFlowReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FundFlowReportController controller =
    Get.put(FundFlowReportController());
    final formatCurrency =
    intl.NumberFormat.currency(locale: 'ar_SA', symbol: ' ريال');

    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير حركة الصندوق'),
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
              // 1. بطاقة صافي التدفق النقدي
              _buildNetFlowCard(controller.netFlow, formatCurrency),
              const SizedBox(height: 24),

              // 2. الرسم البياني للمقارنة
              Text('مقارنة الوارد بالصادر',
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
      BuildContext context, FundFlowReportController controller) {
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
  Widget _buildDateField(BuildContext context, FundFlowReportController controller,
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

  /// ودجت بناء بطاقة صافي التدفق النقدي
  Widget _buildNetFlowCard(double netFlow, intl.NumberFormat formatCurrency) {
    final bool isPositive = netFlow >= 0;
    final color = isPositive ? Colors.green.shade700 : Colors.red.shade700;

    return Card(
      elevation: 4,
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            children: [
              Text(
                'صافي التدفق النقدي',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                formatCurrency.format(netFlow),
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
  BarChartData _buildBarChartData(
      BuildContext context, FundFlowReportController controller) {
    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      barGroups: [
        // 1. شريط إجمالي الوارد
        BarChartGroupData(x: 0, barRods: [
          BarChartRodData(
              toY: controller.totalDeposits.value,
              color: Colors.green.shade400,
              width: 40,
              borderRadius: BorderRadius.circular(4))
        ]),
        // 2. شريط إجمالي الصادر
        BarChartGroupData(x: 1, barRods: [
          BarChartRodData(
              toY: controller.totalWithdrawals.value,
              color: Colors.red.shade400,
              width: 40,
              borderRadius: BorderRadius.circular(4))
        ]),
      ],
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              String text = '';
              if (value == 0) text = 'الوارد';
              if (value == 1) text = 'الصادر';
              return Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(text,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
              );
            },
            reservedSize: 30,
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
      FundFlowReportController controller, intl.NumberFormat formatCurrency) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            _buildDetailRow(
                'إجمالي الوارد (توريد)',
                formatCurrency.format(controller.totalDeposits.value),
                Colors.green.shade800),
            _buildDetailRow(
                'إجمالي الصادر (سحب)',
                formatCurrency.format(controller.totalWithdrawals.value),
                Colors.red.shade700),
            const Divider(thickness: 2),
            _buildDetailRow(
              'صافي التدفق النقدي',
              formatCurrency.format(controller.netFlow),
              controller.netFlow >= 0
                  ? Colors.green.shade900
                  : Colors.red.shade900,
              isBold: true,
              isLarge: true,
            ),
          ],
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
