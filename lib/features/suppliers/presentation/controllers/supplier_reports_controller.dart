// File: lib/features/suppliers/presentation/controllers/supplier_reports_controller.dart

import 'package:ehab_company_admin/features/suppliers/data/repositories/supplier_transactions_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SupplierReportsController extends GetxController {
  final SupplierTransactionsRepository _repository = SupplierTransactionsRepository();

  final TextEditingController searchController = TextEditingController();
  final RxBool isLoading = false.obs;
  final Rx<Map<String, dynamic>?> foundTransaction = Rx<Map<String, dynamic>?>(null);
  final RxBool noResultFound = false.obs;

  /// دالة البحث عن السند
  Future<void> searchForTransaction() async {
    if (searchController.text.trim().isEmpty) {
      Get.snackbar('خطأ', 'الرجاء إدخال رقم السند للبحث');
      return;
    }

    final int? transactionId = int.tryParse(searchController.text.trim());
    if (transactionId == null) {
      Get.snackbar('خطأ', 'الرجاء إدخال رقم صحيح');
      return;
    }

    try {
      isLoading(true);
      noResultFound(false); // إعادة تعيين حالة "لم يتم العثور"
      final result = await _repository.getTransactionById(transactionId);

      if (result != null) {
        foundTransaction.value = result;
      } else {
        foundTransaction.value = null;
        noResultFound(true); // تفعيل حالة "لم يتم العثور"
      }
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ أثناء البحث: $e');
    } finally {
      isLoading(false);
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
