// File: lib/features/reports/presentation/controllers/profit_and_loss_controller.dart

import 'package:ehab_company_admin/features/expenses/data/repositories/expense_repository.dart';
import 'package:ehab_company_admin/features/sales/data/repositories/sales_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfitAndLossController extends GetxController {
  final SalesRepository _salesRepository = SalesRepository();
  final ExpenseRepository _expenseRepository = ExpenseRepository();

  // Observables for UI state
  final RxBool isLoading = false.obs;

  // Observables for date filters
  // Set default dates to cover the current month
  final Rx<DateTime> fromDate =
  Rx<DateTime>(DateTime(DateTime.now().year, DateTime.now().month, 1));
  final Rx<DateTime> toDate = Rx<DateTime>(DateTime.now());

  // Observables for report results
  final RxDouble totalSales = 0.0.obs;
  final RxDouble costOfGoodsSold = 0.0.obs;
  final RxDouble totalExpenses = 0.0.obs;

  // Calculated property for gross profit
  double get grossProfit => totalSales.value - costOfGoodsSold.value;

  // Calculated property for net profit
  double get netProfit => grossProfit - totalExpenses.value;

  @override
  void onInit() {
    super.onInit();
    // Generate the report for the default period (current month) on startup
    generateReport();

    // Automatically regenerate the report whenever the date range changes
    ever(fromDate, (_) => generateReport());
    ever(toDate, (_) => generateReport());
  }

  /// The main function to generate the profit and loss report
  Future<void> generateReport() async {
    isLoading(true);
    try {
      // Fetch all data in parallel for better performance
      final results = await Future.wait([
        _salesRepository.getTotalSalesRevenue(
            from: fromDate.value, to: toDate.value),
        _salesRepository.getCostOfGoodsSold(
            from: fromDate.value, to: toDate.value),
        _expenseRepository.getTotalExpenses(
            from: fromDate.value, to: toDate.value),
      ]);

      // Assign results to observables
      totalSales.value = results[0];
      costOfGoodsSold.value = results[1];
      totalExpenses.value = results[2];
    } catch (e) {
      Get.snackbar('خطأ في التقرير', 'فشل في حساب الأرباح والخسائر: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading(false);
    }
  }

  /// Function to show a date picker and update the state
  Future<void> selectDate(BuildContext context, {required bool isFromDate}) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: isFromDate ? fromDate.value : toDate.value,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      locale: const Locale('ar'),
    );
    if (pickedDate != null) {
      if (isFromDate) {
        fromDate.value = pickedDate;
      } else {
        toDate.value = pickedDate;
      }
    }
  }
}
