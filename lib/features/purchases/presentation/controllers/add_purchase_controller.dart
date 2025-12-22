// File: lib/features/purchases/presentation/controllers/add_purchase_controller.dart

import 'package:ehab_company_admin/features/products/data/models/product_model.dart';
import 'package:ehab_company_admin/features/products/presentation/controllers/product_controller.dart';
import 'package:ehab_company_admin/features/purchases/data/repositories/purchase_repository.dart';
import 'package:ehab_company_admin/features/suppliers/data/models/supplier_model.dart';
import 'package:ehab_company_admin/features/suppliers/presentation/controllers/supplier_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import 'package:lottie/lottie.dart';

import '../../../../core/services/purchase_invoice_pdf_service.dart';


enum DiscountType { amount, percentage }

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
  final Rx<DiscountType> discountType = DiscountType.amount.obs;
  final RxDouble discountPercentage = 0.0.obs;

  // Text Editing Controllers
  final TextEditingController invoiceIdController = TextEditingController();
  final TextEditingController supplierInvoiceNumberController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController discountController = TextEditingController(
      text: '0.0');
  final TextEditingController taxController = TextEditingController(
      text: '0.0');
  final TextEditingController paidAmountController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController productSearchController = TextEditingController();

  // متغيرات محسوبة محدثة
  int get totalItemsCount =>
      invoiceItems.fold(0, (sum, item) => sum + item.quantity.toInt());

  double get subtotal =>
      invoiceItems.fold(0.0, (sum, item) => sum + item.subtotal);

  double get totalAfterDiscount => subtotal - discountValue.value;

  double get taxAmount => totalAfterDiscount * (taxPercentage.value / 100);

  double get grandTotal => totalAfterDiscount + taxAmount;

  double get remainingAmount => grandTotal - paidAmount.value;

  @override
  void onInit() {
    super.onInit();
    dateController.text =
        intl.DateFormat('yyyy-MM-dd').format(invoiceDate.value);
    discountController.addListener(updateTotals);
    taxController.addListener(updateTotals);
    paidAmountController.addListener(updateTotals);
  }

  Future<void> _loadNextInvoiceId() async {
    final lastId = await _purchaseRepository.getLastInvoiceId();
    invoiceIdController.text = (lastId == 0 ? 100 : lastId + 1).toString();
    discountController.addListener(updateTotals);
    taxController.addListener(updateTotals);
    paidAmountController.addListener(updateTotals);
  }

  // --- بداية التعديل: تعديل الدالة بالكامل ---
  void updateTotals() {
    // حساب الخصم بناءً على النوع المختار
    if (discountType.value == DiscountType.amount) {
      // إذا كان الخصم مبلغًا، القيمة هي ما في الحقل مباشرة
      discountValue.value = double.tryParse(discountController.text) ?? 0.0;
    } else {
      // إذا كان الخصم نسبة، قم بحساب القيمة
      discountPercentage.value =
          double.tryParse(discountController.text) ?? 0.0;
      discountValue.value = subtotal * (discountPercentage.value / 100);
    }

    // باقي الحسابات
    taxPercentage.value = double.tryParse(taxController.text) ?? 0.0;
    paidAmount.value = double.tryParse(paidAmountController.text) ?? 0.0;
  }

  // --- نهاية التعديل ---

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

  void addProductToInvoice(ProductModel product, double quantity,
      double price) {
    if (quantity <= 0) {
      Get.snackbar('خطأ', 'الكمية يجب أن تكون أكبر من صفر.');
      return;
    }
    final existingItem = invoiceItems.firstWhereOrNull((item) =>
    item.product.id == product.id);

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
  }

  void clearProductSearch() {
    productController.searchQuery.value = '';
  }

  void removeProductFromInvoice(int productId) {
    invoiceItems.removeWhere((item) => item.product.id == productId);
  }

  void updateItemQuantity(int productId, double newQuantity) {
    final item = invoiceItems.firstWhereOrNull((item) =>
    item.product.id == productId);
    if (item != null && newQuantity > 0) {
      item.quantity = newQuantity;
      invoiceItems.refresh();
    }
  }

  void updateItemPrice(int productId, double newPrice) {
    final item = invoiceItems.firstWhereOrNull((item) =>
    item.product.id == productId);
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
    final item = invoiceItems.firstWhereOrNull((i) =>
    i.product.id == productId);
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
      Get.snackbar(
          'خطأ', 'المبلغ المدفوع لا يمكن أن يكون أكبر من الإجمالي النهائي.');
      return;
    }
    if (remainingAmount > 0) {
      Get.defaultDialog(
        title: "تأكيد الفاتورة الآجلة",
        middleText: "المبلغ المدفوع أقل من الإجمالي. سيتم تسجيل المبلغ المتبقي (${remainingAmount
            .toStringAsFixed(2)} ريال) كدين للمورد. هل تريد المتابعة؟",
        textConfirm: "نعم، متابعة",
        confirmTextColor: Colors.white,
        onConfirm: () {
          // عند التأكيد، أغلق الديالوج ونفذ الحفظ
          Get.back();
          _performSave();
        },
        textCancel: "إلغاء",
      );
    } else {
      // إذا تم دفع المبلغ بالكامل، قم بالحفظ مباشرة
      _performSave();
    }
  }

  /// دالة مساعدة لتنفيذ عملية الحفظ الفعلية بعد التحقق
  Future<void> _performSave() async {
    try {
      isSaving(true); // إغلاق شاشة المراجعة (BottomSheet)
      if (Get.isBottomSheetOpen ?? false) {
        Get.back();
      }

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

      // تحديث البيانات في الخلفية
      await supplierController.fetchAllSuppliers();
      await productController.fetchAllProducts();
      isSaving(false);

      // إظهار ديالوج النجاح
      _showSuccessDialog(invoiceId);
    } catch (e) {
      isSaving(false);
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      Get.snackbar('فشل الحفظ', errorMessage,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 5));
    }
  }

  /// دالة عرض ديالوج النجاح
  void _showSuccessDialog(int invoiceId) async {
    // إغلاق شاشة إنشاء الفاتورة الحالية
    Get.back();

    // جلب بياناتالفاتورة التي تم حفظها للتو
    final invoiceDetails =
    await _purchaseRepository.getInvoiceDetailsById(invoiceId);
    final supplierName = selectedSupplier.value?.name ?? '';
    final total = grandTotal;

    Get.dialog(
      barrierDismissible: false,
      AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 150,
              height: 150,
              child: Lottie.asset(
                'assets/animations/success_animation.json',
                repeat: false,
              ),
            ),
            const Text(
              'تمت العملية بنجاح',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSuccessInfoRow('رقم الفاتورة:', '#$invoiceId'),
            _buildSuccessInfoRow('المورد:', supplierName),
            _buildSuccessInfoRow(
                'الإجمالي:', '${total.toStringAsFixed(2)} ريال'),
            const Divider(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.print_outlined),
              label: const Text('طباعة الفاتورة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Get.theme.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 45),
              ),
              onPressed: () {
                if (invoiceDetails != null) {
                  PurchaseInvoicePdfService.printInvoice(invoiceDetails);
                }
              },
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('فاتورة جديدة'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 45),
              ),
              onPressed: () {
                if (Get.isDialogOpen ?? false) Get.back();
                Get.back();
                Get.toNamed('/add_purchase_invoice');
              },
            ),
            const SizedBox(height: 10),
            TextButton(
              child: const Text('العودة للوحة التحكم',
                  style: TextStyle(color: Colors.grey)),
              onPressed: () {
                if (Get.isDialogOpen ?? false) Get.back();
                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// دالة مساعدة لبناء صفوف المعلومات في ديالوج النجاح
  Widget _buildSuccessInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],),
    );
  }

// --- نهاية التعديل ---

  @override
  void onClose() {
    discountController.removeListener(updateTotals);
    taxController.removeListener(updateTotals);
    paidAmountController.removeListener(updateTotals);
    invoiceIdController.dispose();
    supplierInvoiceNumberController.dispose();
    dateController.dispose();
    discountController.dispose();
    taxController.dispose();
    paidAmountController.dispose();
    notesController.dispose();
    productSearchController.dispose();
    super.onClose();
  }
}
