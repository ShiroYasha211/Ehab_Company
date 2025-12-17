// File: lib/features/reports/presentation/controllers/top_selling_products_controller.dart

import 'package:ehab_company_admin/features/sales/data/repositories/sales_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// enum لتحديد نوع الترتيب
enum TopSellingOrderBy { totalQuantity, totalRevenue }

class TopSellingProductsController extends GetxController {
  final SalesRepository _salesRepository = SalesRepository();

  // Observables for UI state
  final RxBool isLoading = false.obs;

  // Observables for date filters
  final Rx<DateTime> fromDate =
  Rx<DateTime>(DateTime(DateTime.now().year, DateTime.now().month, 1));
  final Rx<DateTime> toDate = Rx<DateTime>(DateTime.now());

  // Observable for sorting preference
  final Rx<TopSellingOrderBy> orderBy = TopSellingOrderBy.totalQuantity.obs;

  // Observable for report results
  final RxList<Map<String, dynamic>> topProducts =
      <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    // Generate the report for the default period on startup
    generateReport();

    // Automatically regenerate the report whenever a filter changes
    ever(fromDate, (_) => generateReport());
    ever(toDate, (_) => generateReport());
    ever(orderBy, (_) => generateReport());
  }

  /// The main function to generate the top-selling products report
  Future<void> generateReport() async {
    isLoading(true);
    try {
      // تحويل الـ enum إلى نص يفهمه الـ Repository
      final String orderByString = orderBy.value == TopSellingOrderBy.totalQuantity
          ? 'totalQuantity'
          : 'totalRevenue';

      final results = await _salesRepository.getTopSellingProducts(
        from: fromDate.value,
        to: toDate.value,
        orderBy: orderByString,
        limit: 15, // يمكن تغيير هذا الرقم لعرض أكثر أو أقل
      );

      topProducts.assignAll(results);
    } catch (e) {
      Get.snackbar('خطأ في التقرير', 'فشل في جلب أفضل المنتجات مبيعًا: $e',
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
