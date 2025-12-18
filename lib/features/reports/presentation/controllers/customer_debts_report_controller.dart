// File: lib/features/reports/presentation/controllers/customer_debts_report_controller.dart

import 'package:ehab_company_admin/features/customers/data/models/customer_model.dart';
import 'package:ehab_company_admin/features/customers/data/repositories/customer_repository.dart';
import 'package:get/get.dart';

// --- بداية التعديل: إضافة خيار جديد ---
enum CustomerDebtSortOrder { byHighestDebt, byOldestDebt, byName }
// --- نهاية التعديل ---

class CustomerDebtsReportController extends GetxController {
  final CustomerRepository _customerRepository = CustomerRepository();

  // Observables for UI state
  final RxBool isLoading = true.obs;

  // Observables for report results
  final RxList<CustomerModel> indebtedCustomers = <CustomerModel>[].obs;
  final RxDouble totalDebtAmount = 0.0.obs;

  // Observable for sorting preference
  final Rx<CustomerDebtSortOrder> sortOrder =
      CustomerDebtSortOrder.byHighestDebt.obs;

  @override
  void onInit() {
    super.onInit();
    // Generate the report on startup
    generateReport();

    // Automatically regenerate the report whenever the sort order changes
    ever(sortOrder, (_) => generateReport());
  }

  /// The main function to generate the customer debts report
  Future<void> generateReport() async {
    isLoading(true);
    try {
      // --- بداية التعديل: تحديث منطق الترتيب ---
      String orderByString;
      switch (sortOrder.value) {
        case CustomerDebtSortOrder.byHighestDebt:
          orderByString = 'balance DESC';
          break;
        case CustomerDebtSortOrder.byName:
          orderByString = 'name ASC';
          break;
        case CustomerDebtSortOrder.byOldestDebt:
        // ASC تعني "تصاعدي"، أي أن التاريخ الأقدم (الأصغر) سيظهر أولاً
          orderByString = 'lastTransactionDate ASC';
          break;
      }
      // --- نهاية التعديل ---

      // Fetch all data in parallel for better performance
      final results = await Future.wait([
        _customerRepository.getIndebtedCustomers(orderBy: orderByString),
        _customerRepository.getTotalBalance(),
      ]);

      // Assign results to observables
      indebtedCustomers.assignAll(results[0] as List<CustomerModel>);
      totalDebtAmount.value = results[1] as double;
    } catch (e) {
      Get.snackbar('خطأ في التقرير', 'فشل في جلب ديون العملاء: $e');
    } finally {
      isLoading(false);
    }
  }
}
