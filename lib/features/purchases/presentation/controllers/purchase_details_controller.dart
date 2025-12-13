// File: lib/features/purchases/presentation/controllers/purchase_details_controller.dart
import 'package:ehab_company_admin/features/purchases/data/repositories/purchase_repository.dart';
import 'package:ehab_company_admin/features/suppliers/presentation/controllers/supplier_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../home/presentation/controllers/home_controller.dart';
import 'list_purchases_controller.dart';

class PurchaseDetailsController extends GetxController {
  final int invoiceId;
  final PurchaseRepository _repository = PurchaseRepository();

  final RxBool isLoading = true.obs;
  final RxBool isAddingPayment = false.obs; // <-- متغير جديد لتتبع حالة الدفع
  final RxBool isReturningInvoice = false.obs; // <-- بداية الإضافة
  final Rx<Map<String, dynamic>?> invoiceDetails = Rx<Map<String, dynamic>?>(
      null);

  PurchaseDetailsController(this.invoiceId);

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
        Get.snackbar('خطأ', 'لم يتم العثور على الفاتورة المطلوبة.');
      }
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في جلب تفاصيل الفاتورة: $e');
      isLoading(false);
    } finally {
      isLoading(false);
    }
  }

  Future<void> addPayment(double paymentAmount) async {
    if (paymentAmount <= 0) {
      Get.snackbar('خطأ', 'الرجاء إدخال مبلغ صحيح.');
      return;
    }

    try {
      isAddingPayment(true);

      final int supplierId = invoiceDetails.value!['invoice']['supplierId'];

      await _repository.addPaymentToInvoice(
        invoiceId: invoiceId,
        supplierId: supplierId,
        paymentAmount: paymentAmount,
      );
      await fetchInvoiceDetails(); // تحديث تفاصيل الفاتورة الحالية
      Get.find<ListPurchasesController>().applyFilters();
      Get.find<SupplierController>().fetchAllSuppliers();
      // TODO: Fetch fund balance

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
  // --- بداية الإضافة: دالة إرجاع الفاتورة ---
  Future<void> returnInvoice({
    required String reason,
    required bool receivePayment,
  }) async {
    if (invoiceDetails.value == null) return;

    try {
      isReturningInvoice(true);      final invoiceData = invoiceDetails.value!['invoice'];
      final double totalValue = invoiceData['totalAmount'];

      await _repository.returnPurchaseInvoice(
        originalInvoiceId: invoiceId,
        reason: reason,
        receivePayment: receivePayment,
      );

      // تحديث كل البيانات في الخلفية
      await fetchInvoiceDetails(); // تحديث بيانات هذه الفاتورة (لتغيير حالتها)
      Get.find<ListPurchasesController>().applyFilters(); // تحديث قائمة الفواتير
      Get.find<SupplierController>().fetchAllSuppliers(); // تحديث أرصدة الموردين
      Get.find<HomeController>().refreshStats(); // تحديث إحصائيات الشاشة الرئيسية

      isReturningInvoice(false);
      Get.back(); // إغلاق ديالوج التأكيد

      Get.snackbar(
        'نجاح',
        'تم إرجاع الفاتورة بنجاح.',
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
// --- نهاية الإضافة ---

}
