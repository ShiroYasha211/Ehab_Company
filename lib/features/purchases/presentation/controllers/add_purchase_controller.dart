// File: lib/features/purchases/presentation/controllers/add_purchase_controller.dart

import 'package:ehab_company_admin/features/categories/presentation/controllers/category_controller.dart';
import 'package:ehab_company_admin/features/products/data/models/product_model.dart';
import 'package:ehab_company_admin/features/products/presentation/controllers/product_controller.dart';
import 'package:ehab_company_admin/features/purchases/data/repositories/purchase_repository.dart';
import 'package:ehab_company_admin/features/suppliers/data/models/supplier_model.dart';
import 'package:ehab_company_admin/features/suppliers/presentation/controllers/supplier_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ehab_company_admin/features/units/presentation/controllers/unit_controller.dart';
import 'package:intl/intl.dart' as intl;
import 'package:lottie/lottie.dart';
import 'package:ehab_company_admin/features/purchases/data/models/purchase_invoice_item.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/services/purchase_invoice_pdf_service.dart';
import '../../../../core/services/settings_service.dart';
import 'package:ehab_company_admin/features/fund/presentation/controllers/fund_controller.dart';
import '../../../../core/services/auth_service.dart';
import 'package:ehab_company_admin/features/purchases/data/models/purchase_invoice_payment_model.dart';
import '../../../../features/activities/data/models/activity_model.dart';
import '../../../../features/activities/presentation/controllers/activity_controller.dart';

enum DiscountType { amount, percentage }
enum PaymentMethod { cash, transfer, bank }
enum PaymentMode { cash, credit, split }

/// كلاس مساعد لإدارة بيانات كل دفعة في الواجهة (مطابق للمبيعات)
class PaymentEntry {
  final Rx<PaymentMethod> method = PaymentMethod.cash.obs;
  final TextEditingController amountController = TextEditingController(text: '0.0');
  
  // بيانات الحوالة
  final TextEditingController transferNoController = TextEditingController();
  final TextEditingController senderNameController = TextEditingController();
  final TextEditingController transferCompanyController = TextEditingController();
  final RxnString transferImagePath = RxnString();
  
  // بيانات البنك
  final TextEditingController bankNameController = TextEditingController();
  final TextEditingController bankReferenceController = TextEditingController();
  final RxnString bankImagePath = RxnString();
  
  final TextEditingController notesController = TextEditingController();
  final RxnInt fundId = RxnInt(null);

  PaymentEntry({double amount = 0.0, PaymentMethod initialMethod = PaymentMethod.cash}) {
    method.value = initialMethod;
    amountController.text = amount.toStringAsFixed(2);
    // تصفير الصندوق المختار عند تغيير نوع الدفع لمنع أخطاء الـ Dropdown
    ever(method, (_) => fundId.value = null);
  }

  void dispose() {
    amountController.dispose();
    transferNoController.dispose();
    senderNameController.dispose();
    transferCompanyController.dispose();
    bankNameController.dispose();
    bankReferenceController.dispose();
    notesController.dispose();
  }
}

class AddPurchaseController extends GetxController {
  final SupplierController supplierController = Get.find<SupplierController>();
  final ProductController productController = Get.find<ProductController>();
  final CategoryController categoryController = Get.find<CategoryController>();
  final PurchaseRepository _purchaseRepository = PurchaseRepository();
  final FundController fundController = Get.find<FundController>();
  final ActivityController _activityController = Get.find<ActivityController>();

  final RxBool isSaving = false.obs;
  final RxnString selectedSearchCategory = RxnString();

  final Rx<SupplierModel?> selectedSupplier = Rx<SupplierModel?>(null);
  final Rx<DateTime> invoiceDate = Rx<DateTime>(DateTime.now());
  final RxList<PurchaseInvoiceItem> invoiceItems = <PurchaseInvoiceItem>[].obs;
  final RxBool shouldDeductFromFund = true.obs;

  final RxDouble discountValue = 0.0.obs;
  final RxDouble taxPercentage = 0.0.obs;
  final RxDouble paidAmount = 0.0.obs;
  final Rx<DiscountType> discountType = DiscountType.amount.obs;
  final RxDouble discountPercentage = 0.0.obs;

  final RxBool isLocalCurrencyPayment = false.obs;
  final Rx<PaymentMode> paymentMode = PaymentMode.cash.obs;
  final RxList<PaymentEntry> paymentEntries = <PaymentEntry>[].obs;

  final TextEditingController invoiceIdController = TextEditingController();
  final TextEditingController supplierInvoiceNumberController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController discountController = TextEditingController(text: '0.0');
  final TextEditingController taxController = TextEditingController(text: '0.0');
  final TextEditingController paidAmountController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final productSearchController = TextEditingController();

  double get subtotal => invoiceItems.fold(0.0, (sum, item) => sum + item.subtotal);
  double get totalAfterDiscount => subtotal - discountValue.value;
  int get totalItemsCount => invoiceItems.fold(0, (sum, item) => sum + item.quantity.toInt());
  double get taxAmount => totalAfterDiscount * (taxPercentage.value / 100);
  double get grandTotal => totalAfterDiscount + taxAmount;
  double get remainingAmount => grandTotal - (paidAmount.value / (isLocalCurrencyPayment.value ? Get.find<SettingsService>().exchangeRate.value : 1.0));

  void removeProductFromInvoice(int productId) {
    invoiceItems.removeWhere((item) => item.product.id == productId);
    updateTotals();
  }

  @override
  void onInit() {
    super.onInit();
    dateController.text = intl.DateFormat('yyyy-MM-dd').format(invoiceDate.value);
    discountController.addListener(updateTotals);
    taxController.addListener(updateTotals);
    paidAmountController.addListener(updateTotals);
    _initializeDefaultPayment();
  }

  void _initializeDefaultPayment() {
    if (paymentEntries.isEmpty) {
      paymentEntries.add(PaymentEntry(amount: 0.0));
      paymentEntries[0].amountController.addListener(_syncTotalPaidFromEntries);
    }
  }

  void _syncTotalPaidFromEntries() {
    if (isSaving.value) return;
    double total = paymentEntries.fold(0.0, (sum, entry) => sum + (double.tryParse(entry.amountController.text) ?? 0.0));
    paidAmountController.text = total.toStringAsFixed(2);
    paidAmount.value = total;
  }

  void togglePaymentCurrency(bool isLocal) {
    if (isLocalCurrencyPayment.value == isLocal) return;
    final settings = Get.find<SettingsService>();
    final double currentVal = double.tryParse(paidAmountController.text) ?? 0.0;

    if (currentVal > 0) {
      double convertedVal = isLocal ? (currentVal * settings.exchangeRate.value) : (currentVal / settings.exchangeRate.value);
      paidAmountController.text = convertedVal.toStringAsFixed(2);
    }
    isLocalCurrencyPayment.value = isLocal;
    if (paymentMode.value == PaymentMode.cash) updateTotals();
  }

  void updateTotals() {
    if (discountType.value == DiscountType.amount) {
      discountValue.value = double.tryParse(discountController.text) ?? 0.0;
    } else {
      discountPercentage.value = double.tryParse(discountController.text) ?? 0.0;
      discountValue.value = subtotal * (discountPercentage.value / 100);
    }

    if (paymentMode.value == PaymentMode.cash) {
      double targetAmount = grandTotal;
      if (isLocalCurrencyPayment.value) targetAmount = grandTotal * Get.find<SettingsService>().exchangeRate.value;
      paidAmountController.text = targetAmount.toStringAsFixed(2);
      if (paymentEntries.length == 1) {
        paymentEntries[0].amountController.text = targetAmount.toStringAsFixed(2);
        paymentEntries[0].method.value = PaymentMethod.cash;
      }
    } else if (paymentMode.value == PaymentMode.credit) {
      paidAmountController.text = '0.0';
      if (paymentEntries.isNotEmpty) paymentEntries[0].amountController.text = '0.0';
    }

    taxPercentage.value = double.tryParse(taxController.text) ?? 0.0;
    paidAmount.value = double.tryParse(paidAmountController.text) ?? 0.0;
  }

  void setPaymentMode(PaymentMode mode) {
    if (isClosed) return;
    paymentMode.value = mode;
    if (mode == PaymentMode.cash || mode == PaymentMode.credit) _resetPaymentEntries();
    updateTotals();
  }

  void _resetPaymentEntries() {
    for (var entry in paymentEntries) entry.dispose();
    paymentEntries.clear();
    _initializeDefaultPayment();
  }

  void addPaymentEntry() {
    final newEntry = PaymentEntry(amount: 0.0);
    newEntry.amountController.addListener(_syncTotalPaidFromEntries);
    paymentEntries.add(newEntry);
  }

  void removePaymentEntry(int index) {
    if (paymentEntries.length > 1) {
      paymentEntries[index].dispose();
      paymentEntries.removeAt(index);
      _syncTotalPaidFromEntries();
    }
  }

  Future<void> pickEntryImage(PaymentEntry entry, bool isTransfer) async {
    final ImagePicker picker = ImagePicker();
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('اخـتـيـار مـصـدر الـصـورة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPickerOption(icon: Icons.camera_alt_rounded, label: 'الـكـامـيـرا', color: Colors.blue, onTap: () async {
                  Get.back();
                  final XFile? image = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
                  if (image != null) _setEntryImage(entry, isTransfer, image.path);
                }),
                _buildPickerOption(icon: Icons.photo_library_rounded, label: 'الـمـعـرض', color: Colors.purple, onTap: () async {
                  Get.back();
                  final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                  if (image != null) _setEntryImage(entry, isTransfer, image.path);
                }),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(onTap: onTap, child: Column(children: [
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 30)),
      const SizedBox(height: 8),
      Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    ]));
  }

  void _setEntryImage(PaymentEntry entry, bool isTransfer, String path) {
    if (isTransfer) entry.transferImagePath.value = path; else entry.bankImagePath.value = path;
  }

  bool _validatePayments() {
    for (int i = 0; i < paymentEntries.length; i++) {
        final entry = paymentEntries[i];
        final amount = double.tryParse(entry.amountController.text) ?? 0.0;
        if (amount <= 0 && paymentMode.value != PaymentMode.credit) {
            Get.snackbar('خطأ', 'المبلغ في الدفعة رقم ${i+1} يجب أن يكون أكبر من الصفر.');
            return false;
        }
        if (entry.method.value == PaymentMethod.transfer && entry.transferNoController.text.trim().isEmpty) {
            Get.snackbar('خطأ', 'رقم الحوالة إلزامي في الدفعة رقم ${i+1}.');
            return false;
        }
        if (entry.method.value == PaymentMethod.bank && entry.bankReferenceController.text.trim().isEmpty) {
            Get.snackbar('خطأ', 'الرقم المرجعي للبنك إلزامي في الدفعة رقم ${i+1}.');
            return false;
        }
        if (amount > 0 && entry.fundId.value == null) {
            Get.snackbar('خطأ', 'الرجاء اختيار الصندوق لعملية الـ ${entry.method.value.name} في الدفعة رقم ${i+1}.');
            return false;
        }
    }
    return true;
  }

  Future<void> selectInvoiceDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(context: context, initialDate: invoiceDate.value, firstDate: DateTime(2000), lastDate: DateTime(2101), locale: const Locale('ar'));
    if (picked != null) { invoiceDate.value = picked; dateController.text = intl.DateFormat('yyyy-MM-dd').format(picked); }
  }

  void addProductToInvoice(ProductModel product, double quantity, {double freeQuantity = 0.0, double? rootPrice, double? rootSalePrice, int? unitId}) {
    if (quantity <= 0 && freeQuantity <= 0) { Get.snackbar('خطأ', 'الكمية يجب أن تكون أكبر من صفر.'); return; }
    final selectedUnit = unitId ?? product.unitId;
    final primaryRootPrice = rootPrice ?? product.purchasePrice;
    final primaryRootSalePrice = rootSalePrice ?? product.salePrice;
    final factor = calculateConversionFactor(product, selectedUnit!);
    final perUnitPurchasePrice = primaryRootPrice / (factor > 0 ? factor : 1.0);
    final existingItem = invoiceItems.firstWhereOrNull((item) => item.product.id == product.id && item.selectedUnitId == selectedUnit);

    if (existingItem != null) {
      existingItem.quantity += quantity; existingItem.freeQuantity += freeQuantity;
      existingItem.purchasePrice = perUnitPurchasePrice; existingItem.rootPurchasePrice = primaryRootPrice;
      existingItem.newSalePrice = primaryRootSalePrice; invoiceItems.refresh();
    } else {
      invoiceItems.add(PurchaseInvoiceItem(product: product, quantity: quantity, freeQuantity: freeQuantity, purchasePrice: perUnitPurchasePrice, rootPurchasePrice: primaryRootPrice, newSalePrice: primaryRootSalePrice, selectedUnitId: selectedUnit));
    }
    updateTotals();
  }

  void updateInvoiceItem({required int productId, required double newQuantity, double newFreeQuantity = 0.0, required double newRootPurchasePrice, double? newRootSalePrice, required int newUnitId}) {
    final item = invoiceItems.firstWhereOrNull((i) => i.product.id == productId);
    if (item != null) {
      final factor = calculateConversionFactor(item.product, newUnitId);
      item.quantity = newQuantity; item.freeQuantity = newFreeQuantity;
      item.purchasePrice = newRootPurchasePrice / (factor > 0 ? factor : 1.0);
      item.rootPurchasePrice = newRootPurchasePrice;
      if (newRootSalePrice != null && newRootSalePrice >= 0) item.newSalePrice = newRootSalePrice;
      item.selectedUnitId = newUnitId; invoiceItems.refresh(); updateTotals();
    }
  }

  void updateItemDetails(int productId, {required double newQuantity, required double newFreeQuantity, required int newUnitId, required double newRootPurchasePrice, double? newRootSalePrice}) {
    updateInvoiceItem(productId: productId, newQuantity: newQuantity, newFreeQuantity: newFreeQuantity, newRootPurchasePrice: newRootPurchasePrice, newRootSalePrice: newRootSalePrice, newUnitId: newUnitId);
  }

  List<int> getAllowedUnitIds(ProductModel product) {
    List<int> chainIds = []; int? currentId = product.unitId; final unitController = Get.find<UnitController>();
    while (currentId != null) {
      chainIds.add(currentId); final unit = unitController.allUnits.firstWhereOrNull((u) => u.id == currentId);
      currentId = unit?.childUnitId;
    }
    if (product.allowedUnits != null && product.allowedUnits!.isNotEmpty) {
      final validAllowedIds = chainIds.where((id) => product.allowedUnits!.contains(id)).toList();
      if (validAllowedIds.isNotEmpty) return validAllowedIds;
    }
    return chainIds;
  }

  double calculateConversionFactor(ProductModel product, int targetUnitId) {
    if (product.unitId == targetUnitId) return 1.0;
    final unitController = Get.find<UnitController>(); double factor = 1.0; int? currentId = product.unitId;
    while (currentId != null && currentId != targetUnitId) {
      final unit = unitController.allUnits.firstWhereOrNull((u) => u.id == currentId);
      if (unit == null) break; factor *= unit.conversionFactor; currentId = unit.childUnitId;
    }
    return currentId == targetUnitId ? factor : 1.0;
  }

  double calculatePriceForUnit(ProductModel product, int targetUnitId) {
    final factor = calculateConversionFactor(product, targetUnitId);
    return product.purchasePrice / (factor > 0 ? factor : 1.0);
  }

  double getAvailableQuantity(ProductModel product) => product.quantity;

  Future<void> savePurchaseInvoice() async {
    if (selectedSupplier.value == null) { Get.snackbar('خطأ', 'الرجاء اختيار مورد أولاً.'); return; }
    if (invoiceItems.isEmpty) { Get.snackbar('خطأ', 'يجب إضافة صنف واحد على الأقل إلى الفاتورة.'); return; }
    if (!_validatePayments()) return;

    if (remainingAmount > 0.01) {
      Get.defaultDialog(
        title: "تأكيد الفاتورة الآجلة",
        middleText: "المبلغ المدفوع أقل من الإجمالي. سيتم تسجيل المتبقي (${remainingAmount.toStringAsFixed(2)}) كدين للمورد. متابعة؟",
        textConfirm: "نعم", confirmTextColor: Colors.white, onConfirm: () { Get.back(); _performSave(); }, textCancel: "إلغاء"
      );
    } else {
      _performSave();
    }
  }

  Future<void> _performSave() async {
    try {
      isSaving(true); if (Get.isBottomSheetOpen ?? false) Get.back();
      final double exRate = Get.find<SettingsService>().exchangeRate.value;
      final List<PurchaseInvoicePaymentModel> payments = paymentEntries.map((entry) {
        double amt = double.tryParse(entry.amountController.text) ?? 0.0;
        if (isLocalCurrencyPayment.value) amt = amt / exRate;
        return PurchaseInvoicePaymentModel(method: entry.method.value.name, amount: amt, fundId: entry.fundId.value, transferNumber: entry.transferNoController.text, senderName: entry.senderNameController.text, transferCompany: entry.transferCompanyController.text, transferImage: entry.transferImagePath.value, bankName: entry.bankNameController.text, bankReference: entry.bankReferenceController.text, bankImage: entry.bankImagePath.value, notes: entry.notesController.text, createdAt: DateTime.now());
      }).toList();

      final auth = Get.find<AuthService>();
      final user = auth.currentUser.value;
      final String issuedBy = user != null ? "${user.name} (${user.roleName})" : "غير محدد";

      final int invoiceId = await _purchaseRepository.createPurchaseInvoice(
        supplierId: selectedSupplier.value?.id, supplierInvoiceNumber: supplierInvoiceNumberController.text,
        invoiceDate: invoiceDate.value, totalAmount: grandTotal, discountAmount: discountValue.value,
        paidAmount: paidAmount.value / (isLocalCurrencyPayment.value ? exRate : 1.0),
        remainingAmount: remainingAmount, notes: notesController.text, items: invoiceItems.toList(),
        payments: payments, issuedBy: issuedBy,
      );

      await supplierController.fetchAllSuppliers(); await productController.fetchAllProducts();

      // تسجيل نشاط المشتريات
      final String paymentMethodAr = paymentMode.value == PaymentMode.cash 
          ? "نقداً" 
          : (paymentMode.value == PaymentMode.credit ? "آجل" : "مجزأ (نقدي وآجل)");

      await _activityController.logAction(
        action: 'إصدار فاتورة مشتريات',
        details: 'توريد بضاعة: فاتورة رقم ($invoiceId) من المورد "${selectedSupplier.value?.name}". الإجمالي: ${grandTotal.toStringAsFixed(2)}، طريقة الدفع: $paymentMethodAr',
        type: ActivityType.purchase,
      );

      isSaving(false); _showSuccessDialog(invoiceId);
    } catch (e) {
      isSaving(false); Get.snackbar('فشل الحفظ', e.toString());
    }
  }

  void _showSuccessDialog(int invoiceId) async {
    final details = await _purchaseRepository.getInvoiceDetailsById(invoiceId);
    Get.dialog(barrierDismissible: false, AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(width: 150, height: 150, child: Lottie.asset('assets/animations/success_animation.json', repeat: false)),
        const Text('تمت العملية بنجاح', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildSuccessInfoRow('رقم الفاتورة:', '#$invoiceId'),
        _buildSuccessInfoRow('المورد:', selectedSupplier.value?.name ?? ''),
        _buildSuccessInfoRow('الإجمالي:', grandTotal.toStringAsFixed(2)),
        const Divider(height: 32),
        ElevatedButton.icon(icon: const Icon(Icons.print_outlined), label: const Text('طباعة'), onPressed: () { if (details != null) PurchaseInvoicePdfService.printInvoice(details); }),
        const SizedBox(height: 10),
        OutlinedButton.icon(icon: const Icon(Icons.add_shopping_cart), label: const Text('فاتورة جديدة'), onPressed: () { _resetInvoiceState(); if (Get.isDialogOpen ?? false) Get.back(); }),
        TextButton(child: const Text('إغلاق'), onPressed: () { Get.back(); Get.back(); }),
      ]),
    ));
  }

  Widget _buildSuccessInfoRow(String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 4.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))]));

  void _resetInvoiceState() {
    invoiceItems.clear(); selectedSupplier.value = null; discountValue.value = 0.0; paidAmount.value = 0.0;
    invoiceIdController.clear(); discountController.text = '0.0'; paidAmountController.text = '0.0';
    taxController.text = '0.0'; notesController.clear(); productSearchController.clear();
    isLocalCurrencyPayment.value = false; paymentMode.value = PaymentMode.cash;
    _resetPaymentEntries(); updateTotals();
  }

  @override
  void onClose() {
    discountController.removeListener(updateTotals); taxController.removeListener(updateTotals); paidAmountController.removeListener(updateTotals);
    invoiceIdController.dispose(); supplierInvoiceNumberController.dispose(); dateController.dispose();
    discountController.dispose(); taxController.dispose(); paidAmountController.dispose(); notesController.dispose(); productSearchController.dispose();
    for (var entry in paymentEntries) entry.dispose();
    super.onClose();
  }
}
