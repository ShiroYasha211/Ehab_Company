// File: lib/features/financial_docs/presentation/controllers/payment_vouchers_controller.dart

import 'package:ehab_company_admin/features/suppliers/data/models/supplier_model.dart';
import 'package:ehab_company_admin/features/suppliers/data/models/supplier_transaction_model.dart';
import 'package:ehab_company_admin/features/suppliers/data/repositories/supplier_repository.dart';
import 'package:ehab_company_admin/features/suppliers/presentation/controllers/supplier_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PaymentVouchersController extends GetxController {
  final SupplierRepository _repository = SupplierRepository();
  // نحتاج SupplierController لجلب قائمة الموردين للفلتر
  final SupplierController supplierController = Get.find<SupplierController>();

  // Observables for UI state
  final RxBool isLoading = true.obs;
  final RxList<SupplierTransactionModel> vouchers = <SupplierTransactionModel>[].obs;

  // Observables for date filters
  final Rx<DateTime?> fromDate = Rx<DateTime?>(null);
  final Rx<DateTime?> toDate = Rx<DateTime?>(null);

  // Observable for supplier filter
  final Rx<SupplierModel?> selectedSupplier = Rx<SupplierModel?>(null);

  @override
  void onInit() {
    super.onInit();
    // جلب البيانات عند بدء تشغيل الـ Controller
    fetchVouchers();

    // إعادة جلب البيانات تلقائيًا عند تغيير أي فلتر
    ever(fromDate, (_) => fetchVouchers());
    ever(toDate, (_) => fetchVouchers());
    ever(selectedSupplier, (_) => fetchVouchers());
  }

  /// The main function to fetch payment vouchers
  Future<void> fetchVouchers() async {
    isLoading(true);
    try {
      final voucherList = await _repository.getPaymentVouchers(
        supplierId: selectedSupplier.value?.id,
        from: fromDate.value,
        to: toDate.value,
      );
      vouchers.assignAll(voucherList);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في جلب سندات الدفع: $e');
    } finally {
      isLoading(false);
    }
  }

  /// دالة لمسح كل الفلاتر وإعادة جلب البيانات
  void clearFilters() {
    fromDate.value = null;
    toDate.value = null;
    selectedSupplier.value = null;
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
