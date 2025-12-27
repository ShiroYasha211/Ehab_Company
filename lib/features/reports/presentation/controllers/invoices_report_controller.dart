import 'package:ehab_company_admin/features/reports/data/models/invoice_report_model.dart';
import 'package:ehab_company_admin/features/reports/data/repositories/reports_repository.dart';
import 'package:flutter/material.dart';import 'package:get/get.dart';

class InvoicesReportController extends GetxController {
  final ReportsRepository _repository = ReportsRepository();

  // --- 1. بداية التعديل: متغيرات جديدة للتحكم بالصفحات ---
  late PageController pageController;
  final RxInt currentPageIndex = 0.obs;
  // --- نهاية التعديل ---

  // ------- متغيرات الحالة -------
  final RxBool isLoading = true.obs;
  // --- 2. بداية التعديل: فصل قائمة الفواتير ---
  final RxList<InvoiceReportModel> salesInvoices = <InvoiceReportModel>[].obs;
  final RxList<InvoiceReportModel> purchaseInvoices = <InvoiceReportModel>[].obs;
  // --- نهاية التعديل ---

  // ------- متغيرات الفلاتر -------
  final Rx<DateTime?> fromDate = Rx<DateTime?>(null);
  final Rx<DateTime?> toDate = Rx<DateTime?>(null);
  // --- 3. بداية التعديل: فلتر النوع لم يعد مطلوبًا هنا ---
  // final Rx<InvoiceTypeFilter> invoiceTypeFilter = InvoiceTypeFilter.all.obs; // <-- حذف هذا السطر
  // --- نهاية التعديل ---
  final Rx<PaymentStatusFilter> paymentStatusFilter = PaymentStatusFilter.all.obs;

  // ------- متغيرات الملخصات المحسوبة -------
  final RxDouble totalSales = 0.0.obs;
  final RxDouble totalPurchases = 0.0.obs;
  final RxInt salesCount = 0.obs;
  final RxInt purchasesCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    // --- 4. بداية التعديل: تهيئة PageController ---
    pageController = PageController();
    // --- نهاية التعديل ---

    // جلب البيانات عند بدء التشغيل
    fetchReportData();

    // ربط الفلاتر بالتحديث التلقائي
    ever(fromDate, (_) => fetchReportData());
    ever(toDate, (_) => fetchReportData());
    ever(paymentStatusFilter, (_) => fetchReportData());
  }

  // --- 5. بداية الإضافة: دالة للتنقل بين الصفحات ---
  void changePage(int index) {
    if (currentPageIndex.value == index) return;
    currentPageIndex.value = index;
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
  // --- نهاية الإضافة ---

  @override
  void onClose() {
    // --- 6. بداية الإضافة: التخلص من PageController ---
    pageController.dispose();
    // --- نهاية الإضافة ---
    super.onClose();
  }

  /// الدالة الرئيسية لجلب وتحديث بيانات التقرير
  Future<void> fetchReportData() async {
    try {
      isLoading(true);
      final result = await _repository.getInvoicesReport(
        fromDate: fromDate.value,
        toDate: toDate.value,
        // --- 7. بداية التعديل: جلب كل الأنواع دائمًا ---
        type: InvoiceTypeFilter.all, // <-- الآن نجلب كل الأنواع دائمًا
        // --- نهاية التعديل ---
        status: paymentStatusFilter.value,
      );
      // حساب الملخصات وتوزيع البيانات على القوائم الصحيحة
      _calculateAndDistributeSummaries(result);
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء تحميل بيانات التقرير: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading(false);
    }
  }

  /// دالة لحساب الإجماليات وتوزيع الفواتير على القوائم
  void _calculateAndDistributeSummaries(List<InvoiceReportModel> data) {
    double salesSum = 0;
    double purchasesSum = 0;
    List<InvoiceReportModel> tempSales = [];
    List<InvoiceReportModel> tempPurchases = [];

    for (var invoice in data) {
      if (invoice.invoiceType == 'SALE') {
        salesSum += invoice.totalAmount;
        tempSales.add(invoice);
      } else if (invoice.invoiceType == 'PURCHASE') {
        purchasesSum += invoice.totalAmount;
        tempPurchases.add(invoice);
      }
    }

    // تحديث قيم الملخصات
    totalSales.value = salesSum;
    totalPurchases.value = purchasesSum;
    salesCount.value = tempSales.length;
    purchasesCount.value = tempPurchases.length;

    // تحديث قوائم الفواتير
    salesInvoices.assignAll(tempSales);
    purchaseInvoices.assignAll(tempPurchases);
  }

  /// دالة لمسح كل الفلاتر
  void clearFilters() {
    fromDate.value = null;
    toDate.value = null;
    paymentStatusFilter.value = PaymentStatusFilter.all;
    // fetchReportData() سيتم استدعاؤها تلقائيًا بفضل ever()
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
