// File: lib/features/sales/presentation/controllers/list_sales_controller.dart

import 'package:ehab_company_admin/features/customers/data/models/customer_model.dart';
import 'package:ehab_company_admin/features/customers/presentation/controllers/customer_controller.dart';
import 'package:ehab_company_admin/features/sales/data/models/sales_invoice_summary_model.dart';
import 'package:ehab_company_admin/features/sales/data/repositories/sales_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// استخدام نفس الـ enum لأنه يمثل حالات عامة للفواتير
enum InvoiceFilterStatus { all, paid, due, returned }

class ListSalesController extends GetxController {
  final SalesRepository _repository = SalesRepository();
  // استخدام CustomerController بدلاً من SupplierController
  final CustomerController customerController = Get.find<CustomerController>();

  final RxList<SalesInvoiceSummaryModel> invoices = <SalesInvoiceSummaryModel>[].obs;
  final RxBool isLoading = true.obs;

  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;

  // استخدام CustomerModel بدلاً من SupplierModel
  final Rx<CustomerModel?> selectedCustomer = Rx<CustomerModel?>(null);
  final Rx<InvoiceFilterStatus> selectedStatus = InvoiceFilterStatus.all.obs;

  @override
  void onInit() {
    super.onInit();
    debounce(searchQuery, (_) => applyFilters(), time: const Duration(milliseconds: 500));
    ever(selectedCustomer, (_) => applyFilters());
    ever(selectedStatus, (_) => applyFilters());

    applyFilters();
  }

  Future<void> applyFilters() async {
    try {
      isLoading(true);

      int? invoiceId = int.tryParse(searchQuery.value.trim());
      // استخدام customerId بدلاً من supplierId
      int? customerId = selectedCustomer.value?.id;

      String? status;
      switch (selectedStatus.value) {
        case InvoiceFilterStatus.paid:
          status = 'paid';
          break;
        case InvoiceFilterStatus.due:
          status = 'due';
          break;
        case InvoiceFilterStatus.returned:
          status = 'RETURNED';
          break;
        case InvoiceFilterStatus.all:
          status = null;
          break;
      }

      final invoiceList = await _repository.getAllInvoices(
        invoiceId: invoiceId,
        customerId: customerId, // استخدام customerId
        status: status,
      );

      invoices.assignAll(invoiceList);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في جلب فواتير المبيعات: $e');
    } finally {
      isLoading(false);
    }
  }

  void clearFilters() {
    searchController.clear();
    searchQuery.value = '';
    selectedCustomer.value = null;
    selectedStatus.value = InvoiceFilterStatus.all;
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
