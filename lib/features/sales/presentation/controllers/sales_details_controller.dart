// File: lib/features/sales/presentation/controllers/sales_details_controller.dart

import 'package:ehab_company_admin/features/customers/presentation/controllers/customer_controller.dart';
import 'package:ehab_company_admin/features/sales/data/repositories/sales_details_repository.dart';
import 'package:ehab_company_admin/features/sales/presentation/controllers/list_sales_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../home/presentation/controllers/home_controller.dart';

class SalesDetailsController extends GetxController {
  final int invoiceId;
  final SalesDetailsRepository _repository = SalesDetailsRepository();

  final RxBool isLoading = true.obs;
  final Rx<Map<String, dynamic>?> invoiceDetails = Rx<Map<String, dynamic>?>(null);
  final RxBool isReturningInvoice = false.obs; // <-- إضافة جديدة

  // --- 1. بداية التعديل: إضافة متغير حالة الدفع ---
  final RxBool isAddingPayment = false.obs;
  // --- نهاية التعديل ---

  SalesDetailsController(this.invoiceId);

  @override
  void onInit() {
    super.onInit();
    fetchInvoiceDetails();
  }

  Future<void> fetchInvoiceDetails() async {
    try {
      isLoading(true);
      final details = await _repository.getInvoiceDetailsById(invoiceId);
      if (details != null) {
        invoiceDetails.value = details;
      } else {
        Get.snackbar('خطأ', 'لم يتم العثور على فاتورة المبيعات المطلوبة.');
      }
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في جلب تفاصيل الفاتورة: $e');
    } finally {
      isLoading(false);
    }
  }

  // --- 2. بداية التعديل: إضافة دالة تسجيل الدفعة ---
  Future<void> addPayment(double paymentAmount) async {
    if (paymentAmount <= 0) {
      Get.snackbar('خطأ', 'الرجاء إدخال مبلغ صحيح.');
      return;
    }

    try {
      isAddingPayment(true);

      final int customerId = invoiceDetails.value!['invoice']['customerId'];

      await _repository.addPaymentToSalesInvoice(
        invoiceId: invoiceId,
        customerId: customerId,
        paymentAmount: paymentAmount,
      );

      // تحديث البيانات بعد نجاح الدفعة
      await fetchInvoiceDetails(); // تحديث تفاصيل الفاتورة الحالية

      // تحديث القوائم الرئيسية في الخلفية
      Get.find<ListSalesController>().applyFilters();
      Get.find<CustomerController>().fetchAllCustomers();
      Get.find<HomeController>().refreshStats(); // تحديث إحصائيات الشاشة الرئيسية

      isAddingPayment(false);
      Get.back(); // إغلاق الديالوج

      Get.snackbar(
        'نجاح',
        'تم تسجيل الدفعة بنجاح.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

    } catch (e) {
      isAddingPayment(false);
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      Get.snackbar('فشل العملية', errorMessage,
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
  Future<void> returnInvoice({
    required String reason, // السبب حاليًا غير مستخدم في قاعدة البيانات، يمكن إضافته لاحقًا
    required bool returnPayment,
  }) async {
    if (invoiceDetails.value == null) return;

    try {
      isReturningInvoice(true);

      await _repository.returnSalesInvoice(
        originalInvoiceId: invoiceId,
        reason: reason,
        returnPaymentToFund: returnPayment,
      );

      // تحديث كل البيانات في الخلفية
      await fetchInvoiceDetails();
      Get.find<ListSalesController>().applyFilters();
      if(invoiceDetails.value!['invoice']['customerId'] != null) {
        Get.find<CustomerController>().fetchAllCustomers();
      }
      Get.find<HomeController>().refreshStats();

      isReturningInvoice(false);
      Get.back(); // إغلاق ديالوج التأكيد

      Get.snackbar(
        'نجاح',
        'تم إرجاع فاتورة المبيعات بنجاح.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      isReturningInvoice(false);
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      Get.snackbar('فشل الإرجاع', errorMessage,
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
// --- نهاية التعديل ---
}
