// File: lib/features/purchases/presentation/controllers/list_purchases_controller.dart

import 'package:ehab_company_admin/features/purchases/data/models/purchase_invoice_summary_model.dart';
import 'package:ehab_company_admin/features/purchases/data/repositories/purchase_repository.dart';
import 'package:ehab_company_admin/features/suppliers/data/models/supplier_model.dart';
import 'package:ehab_company_admin/features/suppliers/presentation/controllers/supplier_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// --- 1. بداية التعديل: إضافة حالة "مرتجعة" ---
enum InvoiceFilterStatus { all, paid, due, returned }
// --- نهاية التعديل ---

class ListPurchasesController extends GetxController {
  final PurchaseRepository _repository = PurchaseRepository();
  final SupplierController supplierController = Get.find<SupplierController>();

  final RxList<PurchaseInvoiceSummaryModel> invoices = <PurchaseInvoiceSummaryModel>[].obs;
  final RxBool isLoading = true.obs;

  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;

  final Rx<SupplierModel?> selectedSupplier = Rx<SupplierModel?>(null);
  final Rx<InvoiceFilterStatus> selectedStatus = InvoiceFilterStatus.all.obs;

  @override
  void onInit() {
    super.onInit();
    debounce(searchQuery, (_) => applyFilters(), time: const Duration(milliseconds: 500));
    ever(selectedSupplier, (_) => applyFilters());
    ever(selectedStatus, (_) => applyFilters());

    applyFilters();
  }

  Future<void> applyFilters() async {
    try {
      isLoading(true);

      int? invoiceId = int.tryParse(searchQuery.value.trim());
      int? supplierId = selectedSupplier.value?.id;

      // --- 2. بداية التعديل: تمرير الحالة الجديدة ---
      String? status;
      switch (selectedStatus.value) {
        case InvoiceFilterStatus.paid:
          status = 'paid';
          break;
        case InvoiceFilterStatus.due:
          status = 'due';
          break;
        case InvoiceFilterStatus.returned:
          status = 'RETURNED'; // يجب أن تطابق القيمة في قاعدة البيانات
          break;
        case InvoiceFilterStatus.all:
          status = null;
          break;
      }
      // --- نهاية التعديل ---

      final invoiceList = await _repository.getAllInvoices(
        invoiceId: invoiceId,
        supplierId: supplierId,
        status: status,
      );

      invoices.assignAll(invoiceList);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في جلب الفواتير: $e');
    } finally {
      isLoading(false);
    }
  }

  void clearFilters() {
    searchController.clear();
    searchQuery.value = '';
    selectedSupplier.value = null;
    selectedStatus.value = InvoiceFilterStatus.all;
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
