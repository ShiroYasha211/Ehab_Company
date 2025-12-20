// File: lib/features/financial_docs/presentation/controllers/receipt_vouchers_controller.dart

import 'package:ehab_company_admin/features/customers/data/models/customer_model.dart';
import 'package:ehab_company_admin/features/customers/data/models/customer_transaction_model.dart';
import 'package:ehab_company_admin/features/customers/data/repositories/customer_repository.dart';
import 'package:ehab_company_admin/features/customers/presentation/controllers/customer_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ReceiptVouchersController extends GetxController {
  final CustomerRepository _repository = CustomerRepository();

  // نحتاج CustomerController لجلب قائمة العملاء للفلتر
  final CustomerController customerController = Get.find<CustomerController>();

  // Observables for UI state
  final RxBool isLoading = true.obs;
  final RxList<CustomerTransactionModel> vouchers = <CustomerTransactionModel>[].obs;

  // Observables for date filters
  final Rx<DateTime?> fromDate = Rx<DateTime?>(null);
  final Rx<DateTime?> toDate = Rx<DateTime?>(null);

  // Observable for customer filter
  final Rx<CustomerModel?> selectedCustomer = Rx<CustomerModel?>(null);

  @override
  void onInit() {
    super.onInit();
    // جلب البيانات عند بدء تشغيل الـ Controller
    fetchVouchers();

    // إعادة جلب البيانات تلقائيًا عند تغيير أي فلتر
    ever(fromDate, (_) => fetchVouchers());
    ever(toDate, (_) => fetchVouchers());
    ever(selectedCustomer, (_) => fetchVouchers());
  }

  /// The main function to fetch receipt vouchers
  Future<void> fetchVouchers() async {
    isLoading(true);
    try {
      final voucherList = await _repository.getReceiptVouchers(
        customerId: selectedCustomer.value?.id,
        from: fromDate.value,
        to: toDate.value,
      );
      vouchers.assignAll(voucherList);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في جلب سندات القبض: $e');
    } finally {
      isLoading(false);
    }
  }

  /// دالة لمسح كل الفلاتر وإعادة جلب البيانات
  void clearFilters() {
    fromDate.value = null;
    toDate.value = null;
    selectedCustomer.value = null;
    // fetchVouchers() سيتم استدعاؤها تلقائيًا بفضل ever()
  }

  /// دالة لإظهار DatePicker وتحديث التاريخ
  Future<void> selectDate(BuildContext context, {required bool isFromDate}) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: (isFromDate ? fromDate.value : toDate.value) ?? DateTime.now(),
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
