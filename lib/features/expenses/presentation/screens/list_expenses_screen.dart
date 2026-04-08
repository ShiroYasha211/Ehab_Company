// File: lib/features/expenses/presentation/screens/list_expenses_screen.dart

import 'package:ehab_company_admin/features/expenses/data/models/expense_model.dart';
import 'package:ehab_company_admin/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:flutter/material.dart' hide DateRangePickerDialog;
import 'package:ehab_company_admin/features/fund/presentation/widgets/date_range_picker_dialog.dart'; // سنعيد استخدام نفس الديالوج
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/services/printing/expense_pdf_service.dart';
import '../../../../core/services/settings_service.dart';

class ListExpensesScreen extends StatelessWidget {
  const ListExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currencySymbol =
        Get.find<SettingsService>().primaryCurrency.value.symbol;
    // يجب أن يكون Controller قد تم إنشاؤه في شاشة لوحة التحكم
    final ExpenseController controller = Get.find<ExpenseController>();
    final formatCurrency = intl.NumberFormat.currency(symbol: currencySymbol);

    return Scaffold(
      appBar: AppBar(
        title: const Text('أرشيف المصروفات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'طباعة تقرير المصروفات',
            onPressed: () {
              // عرض ديالوج اختيار فترة التقرير
              Get.dialog(
                DateRangePickerDialog(
                  onConfirm: (from, to) async {
                    // بعد أن يؤكد المستخدم، قم بإنشاء التقرير
                    try {
                      Get.dialog(
                        const Center(child: CircularProgressIndicator()),
                        barrierDismissible: false,
                      );

                      final reportData = await controller.expenseRepository
                          .getExpensesForReport(from: from, to: to);

                      if (Get.isDialogOpen!) Get.back(); // إغلاق مؤشر التحميل

                      await ExpensePdfService.printExpenseReport(
                        (reportData['expenses'] as List).cast<Map<String, dynamic>>(),
                        dateRange: '${intl.DateFormat('yyyy-MM-dd').format(from)} - ${intl.DateFormat('yyyy-MM-dd').format(to)}',
                      );
                    } catch (e) {
                      if (Get.isDialogOpen!)
                        Get.back(); // إغلاق مؤشر التحميل في حال حدوث خطأ
                      Get.snackbar('خطأ', 'فشل في إنشاء التقرير: $e');
                    }
                  },
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_alt_off_outlined),
            tooltip: 'مسح الفلاتر',
            onPressed: controller.clearFilters,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(130.0),
          child: _buildFilters(context, controller),
        ),
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.isTrue) {
            return const Center(child: CircularProgressIndicator());
          }

          // --- بداية الإصلاح: تحسين منطق عرض الرسائل ---

          // الحالة 1: القائمة المفلترة فارغة، ولكن القائمة الأصلية ليست فارغة
          // هذا يعني أن الفلتر هو السبب
          if (controller.filteredExpenses.isEmpty &&
              controller.expenses.isNotEmpty) {
            return const Center(
              child: Text(
                'لا توجد مصروفات تطابق الفلتر الحالي.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          // الحالة 2: كل القوائم فارغة
          // هذا يعني أنه لا توجد مصروفات مسجلة في النظام أصلًا
          if (controller.filteredExpenses.isEmpty) {
            return const Center(
              child: Text(
                'لم يتم تسجيل أي مصروفات بعد.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: controller.filteredExpenses.length,
            itemBuilder: (context, index) {
              final expense = controller.filteredExpenses[index];
              return _buildExpenseCard(expense, formatCurrency);
            },
          );
        }),
      ),
    );
  }

  Widget _buildFilters(BuildContext context, ExpenseController controller) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // فلتر البند
          Obx(
            () => DropdownButtonFormField<int?>(
              value: controller.filterByCategoryId.value,
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('كل البنود'),
                ),
                ...controller.categories.map((category) {
                  return DropdownMenuItem<int?>(
                    value: category.id,
                    child: Text(category.name),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                controller.filterByCategoryId.value = value;
              },
              decoration: InputDecoration(
                hintText: 'فلترة حسب البند',
                prefixIcon: const Icon(Icons.category_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // فلاتر التاريخ
          Row(
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
        ],
      ),
    );
  }

  Widget _buildDateField(
    BuildContext context,
    ExpenseController controller, {
    required bool isFromDate,
  }) {
    return Obx(() {
      final date = isFromDate
          ? controller.fromDate.value
          : controller.toDate.value;
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

  Widget _buildExpenseCard(
    ExpenseModel expense,
    intl.NumberFormat formatCurrency,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: ListTile(
        leading: CircleAvatar(child: Text(expense.id.toString())),
        title: Text(
          expense.categoryName ?? 'بند غير محدد',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${expense.notes ?? 'لا توجد ملاحظات'}\n${intl.DateFormat('yyyy-MM-dd').format(expense.expenseDate)}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (expense.deductFromFund && expense.fundName != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Text(
                      expense.fundName!,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (expense.supplierId != null && expense.supplierName != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.orange.shade100),
                    ),
                    child: Text(
                      'المورد: ${expense.supplierName!}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatCurrency.format(expense.amount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.red.shade700,
              ),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
