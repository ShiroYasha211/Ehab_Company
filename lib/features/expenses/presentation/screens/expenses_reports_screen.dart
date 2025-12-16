// File: lib/features/expenses/presentation/screens/expenses_reports_screen.dart

import 'package:ehab_company_admin/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;

class ExpensesReportsScreen extends StatefulWidget {
  const ExpensesReportsScreen({super.key});

  @override
  State<ExpensesReportsScreen> createState() => _ExpensesReportsScreenState();
}

class _ExpensesReportsScreenState extends State<ExpensesReportsScreen> {
  // قائمة من الألوان لاستخدامها في الرسم البياني
  final List<Color> _chartColors = [
    Colors.blue.shade400,
    Colors.red.shade400,
    Colors.green.shade400,
    Colors.orange.shade400,
    Colors.purple.shade400,
    Colors.teal.shade400,
    Colors.pink.shade300,
    Colors.indigo.shade400,
  ];

  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final ExpenseController controller = Get.find<ExpenseController>();
    final formatCurrency =
    intl.NumberFormat.currency(locale: 'ar_SA', symbol: ' ريال');

    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير المصروفات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_off_outlined),
            tooltip: 'مسح الفلاتر',
            onPressed: controller.clearFilters,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70.0),
          child: _buildFilters(context, controller),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.isTrue) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.reportDataMap.isEmpty) {
          return const Center(
            child: Text('لا توجد مصروفات لعرضها في التقرير.',
                style: TextStyle(color: Colors.grey, fontSize: 16)),
          );
        }

        final reportDataList = controller.reportDataMap.values.toList();
        reportDataList.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. الرسم البياني الدائري
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          touchedIndex = -1;
                          return;
                        }
                        touchedIndex =
                            pieTouchResponse.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: List.generate(reportDataList.length, (index) {
                    final reportData = reportDataList[index];
                    final isTouched = index == touchedIndex;
                    final fontSize = isTouched ? 16.0 : 14.0;
                    final radius = isTouched ? 60.0 : 50.0;
                    final color = _chartColors[index % _chartColors.length];

                    return PieChartSectionData(
                      color: color,
                      value: reportData.totalAmount,
                      title: '${reportData.percentage.toStringAsFixed(1)}%',
                      radius: radius,
                      titleStyle: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }),
                ),
              ),
            ),
            const Divider(height: 30),

            // 2. القائمة التفصيلية
            Text('ملخص المصروفات (الإجمالي: ${formatCurrency.format(controller.totalReportAmount)})',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            ...List.generate(reportDataList.length, (index) {
              final reportData = reportDataList[index];
              final color = _chartColors[index % _chartColors.length];
              return _buildReportListItem(reportData, color, formatCurrency);
            }),
          ],
        );
      }),
    );
  }

  Widget _buildFilters(BuildContext context, ExpenseController controller) {
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

  Widget _buildDateField(BuildContext context, ExpenseController controller,
      {required bool isFromDate}) {
    return Obx(() {
      final date = isFromDate ? controller.fromDate.value : controller.toDate.value;
      return TextFormField(
        readOnly: true,
        controller: TextEditingController(
          text: date == null ? '' : intl.DateFormat('yyyy-MM-dd').format(date),
        ),
        onTap: () async {
          final DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: date ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2101),
            locale: const Locale('ar'),
          );
          if (pickedDate != null) {
            if (isFromDate) {
              controller.fromDate.value = pickedDate;
            } else {
              controller.toDate.value = pickedDate;
            }
          }
        },
        decoration: InputDecoration(
          labelText: isFromDate ? 'من تاريخ' : 'إلى تاريخ',
          prefixIcon: const Icon(Icons.calendar_today_outlined),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          isDense: true,
        ),
      );
    });
  }

  Widget _buildReportListItem(ReportData reportData, Color color,
      intl.NumberFormat formatCurrency) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(width: 10, height: 40, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                reportData.categoryName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatCurrency.format(reportData.totalAmount),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '${reportData.percentage.toStringAsFixed(1)}% من الإجمالي',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
