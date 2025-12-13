// File: lib/features/purchases/presentation/controllers/add_purchase_controller.dart

import 'package:ehab_company_admin/features/products/data/models/product_model.dart';
import 'package:ehab_company_admin/features/products/presentation/controllers/product_controller.dart';
import 'package:ehab_company_admin/features/purchases/data/repositories/purchase_repository.dart';
import 'package:ehab_company_admin/features/suppliers/data/models/supplier_model.dart';
import 'package:ehab_company_admin/features/suppliers/presentation/controllers/supplier_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;

import '../../../home/presentation/controllers/home_controller.dart';

/// كلاس مساعد لتخزين بيانات المنتج داخل الفاتورة
class InvoiceItem {
  final ProductModel product;
  double quantity;
  double purchasePrice;
  double? newSalePrice;

  InvoiceItem({
    required this.product,
    this.quantity = 1.0,
    required this.purchasePrice,
    this.newSalePrice,
  });

  double get subtotal => quantity * purchasePrice;
}

class AddPurchaseController extends GetxController {
  // جلب الـ Controllers والـ Repositories
  final SupplierController supplierController = Get.find<SupplierController>();
  final ProductController productController = Get.find<ProductController>();
  final PurchaseRepository _purchaseRepository = PurchaseRepository();

  final RxBool isSaving = false.obs;

  // متغيرات الفاتورة
  final Rx<SupplierModel?> selectedSupplier = Rx<SupplierModel?>(null);
  final Rx<DateTime> invoiceDate = Rx<DateTime>(DateTime.now());
  final RxList<InvoiceItem> invoiceItems = <InvoiceItem>[].obs;
  final RxBool shouldDeductFromFund = true.obs; // مفعل افتراضيًا

  // متغيرات مالية جديدة
  final RxDouble discountValue = 0.0.obs;
  final RxDouble taxPercentage = 0.0.obs;
  final RxDouble paidAmount = 0.0.obs;

  // Text Editing Controllers
  final TextEditingController invoiceIdController = TextEditingController();
  final TextEditingController supplierInvoiceNumberController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController discountController = TextEditingController(text: '0.0');
  final TextEditingController taxController = TextEditingController(text: '0.0');
  final TextEditingController paidAmountController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  // متغيرات محسوبة محدثة
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
    _loadNextInvoiceId();
  }

  Future<void> _loadNextInvoiceId() async {
    final lastId = await _purchaseRepository.getLastInvoiceId();
    invoiceIdController.text = (lastId == 0 ? 100 : lastId + 1).toString();
  }

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

  void addProductToInvoice(ProductModel product, double quantity, double price) {
    if (quantity <= 0) {
      Get.snackbar('خطأ', 'الكمية يجب أن تكون أكبر من صفر.');
      return;
    }
    final existingItem = invoiceItems.firstWhereOrNull((item) => item.product.id == product.id);

    if (existingItem != null) {
      existingItem.quantity += quantity;
      existingItem.purchasePrice = price;
      invoiceItems.refresh();
    } else {
      invoiceItems.add(InvoiceItem(
        product: product,
        quantity: quantity,
        purchasePrice: price,
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
      item.quantity = newQuantity;
      invoiceItems.refresh();
    }
  }

  void updateItemPrice(int productId, double newPrice) {
    final item = invoiceItems.firstWhereOrNull((item) => item.product.id == productId);
    if (item != null && newPrice >= 0) {
      item.purchasePrice = newPrice;
      invoiceItems.refresh();
    }
  }

  void updateInvoiceItem({
    required int productId,
    required double newQuantity,
    required double newPurchasePrice,
    double? newSalePrice,
  }) {
    final item = invoiceItems.firstWhereOrNull((i) => i.product.id == productId);
    if (item != null) {
      if (newQuantity > 0) item.quantity = newQuantity;
      if (newPurchasePrice >= 0) item.purchasePrice = newPurchasePrice;
      if (newSalePrice != null && newSalePrice >= 0) {
        item.newSalePrice = newSalePrice;
      }
      invoiceItems.refresh();
    }
  }

  Future<void> savePurchaseInvoice() async {
    if (selectedSupplier.value == null) {
      Get.snackbar('خطأ', 'الرجاء اختيار مورد أولاً.');
      return;
    }
    if (invoiceItems.isEmpty) {
      Get.snackbar('خطأ', 'يجب إضافة صنف واحد على الأقل إلى الفاتورة.');
      return;
    }
    if (paidAmount.value > grandTotal) {
      Get.snackbar('خطأ', 'المبلغ المدفوع لا يمكن أن يكون أكبر من الإجمالي النهائي.');
      return;
    }

    try {
      isSaving(true);

      final invoiceId = await _purchaseRepository.createPurchaseInvoice(
        supplierId: selectedSupplier.value!.id,
        supplierInvoiceNumber: supplierInvoiceNumberController.text,
        invoiceDate: invoiceDate.value,
        totalAmount: grandTotal,
        discountAmount: discountValue.value,
        paidAmount: paidAmount.value,
        remainingAmount: remainingAmount,
        notes: notesController.text,
        items: invoiceItems,
        deductFromFund: shouldDeductFromFund.value,
      );
      await supplierController.fetchAllSuppliers();
      await productController.fetchAllProducts();
      // 2. أوقف مؤشر التحميل
      isSaving(false);
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      Get.back();

      Get.snackbar(
        'نجاح',
        'تم حفظ فاتورة الشراء بنجاح. رقم الفاتورة: $invoiceId',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      // --- نهاية الحل --
    } catch (e) {
      isSaving(false);
      // في حالة الخطأ، أغلق ديالوج الدفع ليرى المستخدم الخطأ
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      Get.snackbar('فشل الحفظ', errorMessage,backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 5));
    }
  }

  @override
  void onClose() {
    invoiceIdController.dispose();
    supplierInvoiceNumberController.dispose();
    dateController.dispose();
    discountController.dispose();
    taxController.dispose();
    paidAmountController.dispose();
    notesController.dispose();
    super.onClose();
  }
}
