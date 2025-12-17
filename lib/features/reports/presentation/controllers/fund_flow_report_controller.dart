// File: lib/features/reports/presentation/controllers/fund_flow_report_controller.dart

import 'package:ehab_company_admin/features/fund/data/repositories/fund_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FundFlowReportController extends GetxController {
  final FundRepository _fundRepository = FundRepository();

  // Observables for UI state
  final RxBool isLoading = false.obs;

// Observables for date filters
// Set default dates to cover the current month
  final Rx<DateTime> fromDate =
  Rx<DateTime>(DateTime(DateTime.now().year, DateTime.now().month, 1));
  final Rx<DateTime> toDate = Rx<DateTime>(DateTime.now());

  // Observables for report results
  final RxDouble totalDeposits = 0.0.obs;
  final RxDouble totalWithdrawals = 0.0.obs;

  // Calculated property for net flow
  double get netFlow => totalDeposits.value - totalWithdrawals.value;

  @override
  void onInit() {
    super.onInit();
    // Generate the report for the default period on startup
        generateReport();

        // Automatically regenerate the report whenever the date range changes
        ever(fromDate, (_) => generateReport());
        ever(toDate, (_) => generateReport());
      }

      /// The main function to generate the fund flow report
  Future<void> generateReport() async {
    isLoading(true);
    try {
      final summary = await _fundRepository.getFundFlowSummary(
          from: fromDate.value, to: toDate.value);

      totalDeposits.value = summary['totalDeposits'] ?? 0.0;
      totalWithdrawals.value = summary['totalWithdrawals'] ?? 0.0;
    } catch (e) {
      Get.snackbar('خطأ في التقرير', 'فشل في حساب حركة الصندوق: $e',
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
      }
      else {
        toDate.value = pickedDate;
      }
    }
  }
}



