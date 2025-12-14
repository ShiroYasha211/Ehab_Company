// File: lib/features/sales/presentation/controllers/add_sales_invoice_controller.dart

import 'package:ehab_company_admin/features/customers/data/models/customer_model.dart';
import 'package:ehab_company_admin/features/customers/presentation/controllers/customer_controller.dart';
import 'package:ehab_company_admin/features/products/data/models/product_model.dart';
import 'package:ehab_company_admin/features/products/presentation/controllers/product_controller.dart';
import 'package:ehab_company_admin/features/sales/data/repositories/sales_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;

/// كلاس مساعد لتخزين بيانات المنتج داخل فاتورة المبيعات
class SalesInvoiceItem {
  final ProductModel product;
  double quantity;
  double salePrice; // سعر البيع بدلاً من الشراء

  SalesInvoiceItem({
    required this.product,
    this.quantity = 1.0,
    required this.salePrice,
  });

  double get subtotal => quantity * salePrice;
}

class AddSalesInvoiceController extends GetxController {
  // جلب الـ Controllers والـ Repositories
  final CustomerController customerController = Get.find<CustomerController>(); // استخدام CustomerController
  final ProductController productController = Get.find<ProductController>();
  final SalesRepository _salesRepository = SalesRepository(); // استخدام SalesRepository

  final RxBool isSaving = false.obs;

  // متغيرات الفاتورة
  final Rx<CustomerModel?> selectedCustomer = Rx<CustomerModel?>(null); // استخدام CustomerModel
  final Rx<DateTime> invoiceDate = Rx<DateTime>(DateTime.now());
  final RxList<SalesInvoiceItem> invoiceItems = <SalesInvoiceItem>[].obs;

  // متغيرات مالية
  final RxDouble discountValue = 0.0.obs;
  final RxDouble taxPercentage = 0.0.obs;
  final RxDouble paidAmount = 0.0.obs;

  // Text Editing Controllers
  final TextEditingController invoiceIdController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController discountController = TextEditingController(text: '0.0');
  final TextEditingController taxController = TextEditingController(text: '0.0');
  final TextEditingController paidAmountController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  // متغيرات محسوبة
  int get totalItemsCount => invoiceItems.fold(0, (sum, item) => sum + item.quantity.toInt());
  double get subtotal => invoiceItems.fold(0.0, (sum, item) => sum + item.subtotal);
  double get totalAfterDiscount => subtotal - discountValue.value;
  double get taxAmount => totalAfterDiscount * (taxPercentage.value / 100);
  double get grandTotal => totalAfterDiscount + taxAmount;
  double get remainingAmount => grandTotal - paidAmount.value;

  @override
  void onInit() {
    super.onInit();
    dateController.text = intl.DateFormat('yyyy-MM-dd').format(invoiceDate.value);
    // _loadNextInvoiceId(); // سيتم تعديل هذه الدالة لاحقًا لتناسب فواتير المبيعات
  }

  // Future<void> _loadNextInvoiceId() async {
  //   // final lastId = await _salesRepository.getLastInvoiceId();
  //   // invoiceIdController.text = (lastId == 0 ? 10001 : lastId + 1).toString();
  // }

  void preparePaymentDialog() {
    paidAmountController.text = '0.0';
    // ربط الـ listeners
    discountController.addListener(() => discountValue.value = double.tryParse(discountController.text) ?? 0.0);
    taxController.addListener(() => taxPercentage.value = double.tryParse(taxController.text) ?? 0.0);
    paidAmountController.addListener(() => paidAmount.value = double.tryParse(paidAmountController.text) ?? 0.0);
  }

  Future<void> selectInvoiceDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: invoiceDate.value,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      locale: const Locale('ar'),
    );
    if (picked != null && picked != invoiceDate.value) {
      invoiceDate.value = picked;
      dateController.text = intl.DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  void addProductToInvoice(ProductModel product, double quantity) {
    if (quantity <= 0) {
      Get.snackbar('خطأ', 'الكمية يجب أن تكون أكبر من صفر.');
      return;
    }
    // التحقق من توفر الكمية في المخزون
    if (quantity > product.quantity) {
      Get.snackbar('خطأ في الكمية', 'الكمية المطلوبة (${quantity}) أكبر من المتوفرة في المخزون (${product.quantity})');
      return;
    }

    final existingItem = invoiceItems.firstWhereOrNull((item) => item.product.id == product.id);

    if (existingItem != null) {
      // التحقق من أن الكمية الجديدة لا تتجاوز المتوفر
      if (existingItem.quantity + quantity > product.quantity) {
        Get.snackbar('خطأ في الكمية', 'إجمالي الكمية المطلوبة يتجاوز المتوفر في المخزون.');
        return;
      }
      existingItem.quantity += quantity;
      invoiceItems.refresh();
    } else {
      invoiceItems.add(SalesInvoiceItem(
        product: product,
        quantity: quantity,
        salePrice: product.salePrice, // استخدام سعر البيع الافتراضي
      ));
    }
    Get.back();
  }

  void clearProductSearch() {
    productController.searchQuery.value = '';
  }

  void removeProductFromInvoice(int productId) {
    invoiceItems.removeWhere((item) => item.product.id == productId);
  }

  void updateItemQuantity(int productId, double newQuantity) {
    final item = invoiceItems.firstWhereOrNull((item) => item.product.id == productId);
    if (item != null && newQuantity > 0) {
      // التحقق من أن الكمية الجديدة لا تتجاوز المتوفر
      if (newQuantity > item.product.quantity) {
        Get.snackbar('خطأ في الكمية', 'الكمية الجديدة أكبر من المتوفرة في المخزون.');
        return;
      }
      item.quantity = newQuantity;
      invoiceItems.refresh();
    }
  }

  void updateItemPrice(int productId, double newPrice) {
    final item = invoiceItems.firstWhereOrNull((item) => item.product.id == productId);
    if (item != null && newPrice >= 0) {
      item.salePrice = newPrice; // تحديث سعر البيع
      invoiceItems.refresh();
    }
  }

  Future<void> saveSalesInvoice() async {
    // التحقق من اختيار عميل
    if (selectedCustomer.value == null) {
      Get.snackbar('خطأ', 'الرجاء اختيار عميل أولاً.');
      return;
    }
    if (invoiceItems.isEmpty) {
      Get.snackbar('خطأ', 'يجب إضافة صنف واحد على الأقل إلى الفاتورة.');
      return;
    }
    if (paidAmount.value > grandTotal) {
      Get.snackbar('خطأ', 'المبلغ المقبوض لا يمكن أن يكون أكبر من الإجمالي النهائي.');
      return;
    }

    try {
      isSaving(true);

      final invoiceId = await _salesRepository.createSalesInvoice(
        customerId: selectedCustomer.value!.id,
        invoiceDate: invoiceDate.value,
        totalAmount: grandTotal,
        discountAmount: discountValue.value,
        paidAmount: paidAmount.value,
        remainingAmount: remainingAmount,
        notes: notesController.text,
        items: invoiceItems,
      );

      // تحديث البيانات بعد الحفظ
      await customerController.fetchAllCustomers(); // تحديث قائمة العملاء
      await productController.fetchAllProducts(); // تحديث كميات المنتجات

      isSaving(false);

      // إغلاق ديالوج الدفع والشاشة الحالية
      if (Get.isDialogOpen ?? false) Get.back();
      Get.back();

      Get.snackbar(
        'نجاح',
        'تم حفظ فاتورة المبيعات بنجاح. رقم الفاتورة: $invoiceId',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

    } catch (e) {
      isSaving(false);
      if (Get.isDialogOpen ?? false) Get.back();
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      Get.snackbar('فشل الحفظ', errorMessage, backgroundColor: Colors.red, colorText: Colors.white, duration: const Duration(seconds: 5));
    }
  }

  @override
  void onClose() {
    invoiceIdController.dispose();
    dateController.dispose();
    discountController.dispose();
    taxController.dispose();
    paidAmountController.dispose();
    notesController.dispose();
    super.onClose();
  }
}
