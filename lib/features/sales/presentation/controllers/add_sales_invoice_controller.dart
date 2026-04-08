// File: lib/features/sales/presentation/controllers/add_sales_invoice_controller.dart

import 'package:ehab_company_admin/features/customers/data/models/customer_model.dart';
import 'package:ehab_company_admin/features/customers/presentation/controllers/customer_controller.dart';
import 'package:ehab_company_admin/features/products/data/models/product_model.dart';
import 'package:ehab_company_admin/features/products/presentation/controllers/product_controller.dart';
import 'package:ehab_company_admin/features/categories/presentation/controllers/category_controller.dart'; // <-- إضافة
import 'package:ehab_company_admin/features/sales/data/repositories/sales_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import 'package:lottie/lottie.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ehab_company_admin/features/fund/presentation/controllers/fund_controller.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/printing/sales_invoice_pdf_service.dart';
import '../../../../core/services/settings_service.dart';
import '../../../units/presentation/controllers/unit_controller.dart';
import '../../data/repositories/sales_details_repository.dart';
import '../../../../features/activities/data/models/activity_model.dart';
import '../../../../features/activities/presentation/controllers/activity_controller.dart';

enum DiscountType { amount, percentage }

enum PaymentMode { cash, credit, split }

enum PaymentMethod { cash, transfer, bank }

/// كلاس مساعد لإدارة بيانات كل دفعة في الواجهة
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

/// كلاس مساعد لتخزين بيانات المنتج داخل فاتورة المبيعات
class SalesInvoiceItem {
  final ProductModel product;
  double quantity;
  double freeQuantity; // الكمية المجانية (لا تحسب في السعر ولكن تخرج من المخزن)
  double salePrice; // سعر البيع للوحدة المختارة
  int? selectedUnitId; // الوحدة التي يتم البيع بها حالياً

  SalesInvoiceItem({
    required this.product,
    this.quantity = 1.0,
    this.freeQuantity = 0.0,
    required this.salePrice,
    this.selectedUnitId,
  });

  double get subtotal => quantity * salePrice;
}

class AddSalesInvoiceController extends GetxController {
  // جلب الـ Controllers والـ Repositories
  final CustomerController customerController =
      Get.find<CustomerController>(); // استخدام CustomerController
  final ProductController productController = Get.find<ProductController>();
  final CategoryController categoryController = Get.find<CategoryController>(); // <-- إضافة
  final SalesRepository _salesRepository =
      SalesRepository(); // استخدام SalesRepository
  final FundController fundController = Get.find<FundController>();
  final ActivityController _activityController = Get.find<ActivityController>();

  final RxBool isSaving = false.obs;

  // متغيرات الفاتورة
  final Rx<CustomerModel?> selectedCustomer = Rx<CustomerModel?>(
    null,
  ); // استخدام CustomerModel
  final Rx<DateTime> invoiceDate = Rx<DateTime>(DateTime.now());
  final RxList<SalesInvoiceItem> invoiceItems = <SalesInvoiceItem>[].obs;

  // متغيرات مالية
  final RxDouble discountValue = 0.0.obs;
  final Rx<DiscountType> discountType = DiscountType.amount.obs;
  final RxDouble discountPercentage = 0.0.obs;
  final RxDouble taxPercentage = 0.0.obs;
  final RxDouble paidAmount = 0.0.obs;

  // خيار الدفع بالعملة المحلية
  final RxBool isLocalCurrencyPayment = false.obs;

  // وضع الدفع المختار
  final Rx<PaymentMode> paymentMode = PaymentMode.cash.obs;

  // Text Editing Controllers
  final TextEditingController invoiceIdController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController discountController = TextEditingController(
    text: '0.0',
  );
  final TextEditingController taxController = TextEditingController(
    text: '0.0',
  );
  final TextEditingController paidAmountController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final productSearchController = TextEditingController();
  
  // قائمة المدفوعات التفصيلية
  final RxList<PaymentEntry> paymentEntries = <PaymentEntry>[].obs;

  // متغيرات البحث الهرمي
  final RxnString selectedSearchCategory = RxnString(); // القسم المختار حالياً في البحث

  // متغيرات محسوبة
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      productController.fetchAllProducts();
    });
    dateController.text = intl.DateFormat(
      'yyyy-MM-dd',
    ).format(invoiceDate.value);

    discountController.addListener(updateTotals);
    taxController.addListener(updateTotals);
    paidAmountController.addListener(updateTotals);
    
    // بدء الدفعة الأولى تلقائياً
    _initializeDefaultPayment();
  }

  void _initializeDefaultPayment() {
    if (paymentEntries.isEmpty) {
      paymentEntries.add(PaymentEntry(amount: 0.0));
      // إضافة مستمع لتغيير المبلغ في الدفعة الأولى لتحديث الإجمالي
      paymentEntries[0].amountController.addListener(_syncTotalPaidFromEntries);
    }
  }

  void _syncTotalPaidFromEntries() {
    if (isSaving.value) return;
    double total = paymentEntries.fold(0.0, (sum, entry) {
      return sum + (double.tryParse(entry.amountController.text) ?? 0.0);
    });
    
    // تحديث الحقل الرئيسي للمدفوع
    paidAmountController.text = total.toStringAsFixed(2);
    paidAmount.value = total;
  }

  void updateTotals() {
    if (discountType.value == DiscountType.amount) {
      // إذا كان الخصم مبلغًا، القيمة هي ما في الحقل مباشرة
      discountValue.value = double.tryParse(discountController.text) ?? 0.0;
    } else {
      // إذا كان الخصم نسبة، قم بحساب القيمة
      discountPercentage.value =
          double.tryParse(discountController.text) ?? 0.0;
      discountValue.value = subtotal * (discountPercentage.value / 100);
    }

    // مزامنة المبلغ المدفوع إذا كان الوضع نقداً أو آجلاً
    if (paymentMode.value == PaymentMode.cash) {
      double targetAmount = grandTotal;
      if (isLocalCurrencyPayment.value) {
        final settings = Get.find<SettingsService>();
        targetAmount = grandTotal * settings.exchangeRate.value;
      }
      paidAmountController.text = targetAmount.toStringAsFixed(2);
      
      // مزامنة الدفعة الأولى في حال كان الوضع نقداً صريحاً
      if (paymentEntries.isNotEmpty && paymentEntries.length == 1) {
        paymentEntries[0].amountController.text = targetAmount.toStringAsFixed(2);
        paymentEntries[0].method.value = PaymentMethod.cash;
      }
    } else if (paymentMode.value == PaymentMode.credit) {
      paidAmountController.text = '0.0';
      if (paymentEntries.isNotEmpty) {
        paymentEntries[0].amountController.text = '0.0';
      }
    }

    // باقي الحسابات تبقى كما هي
    taxPercentage.value = double.tryParse(taxController.text) ?? 0.0;
    paidAmount.value = double.tryParse(paidAmountController.text) ?? 0.0;
  }

  void togglePaymentCurrency(bool isLocal) {
    // إذا لم يتغير الوضع، لا نفعل شيئًا
    if (isLocalCurrencyPayment.value == isLocal) return;

    final settings = Get.find<SettingsService>();
    final double currentVal = double.tryParse(paidAmountController.text) ?? 0.0;

    // إذا كان هناك قيمة مدخلة، نقوم بتحويلها
    if (currentVal > 0) {
      double convertedVal;
      if (isLocal) {
        // التحويل من الأساسي إلى المحلي (ضرب في سعر الصرف)
        convertedVal = currentVal * settings.exchangeRate.value;
      } else {
        // التحويل من المحلي إلى الأساسي (قسمة على سعر الصرف)
        convertedVal = currentVal / settings.exchangeRate.value;
      }
      paidAmountController.text = convertedVal.toStringAsFixed(2);
    }

    isLocalCurrencyPayment.value = isLocal;
    
    // إعادة تحديث المجاميع لضمان مزامنة "النقدي" في العملة الجديدة
    if (paymentMode.value == PaymentMode.cash) {
      updateTotals();
    }
  }

  void setPaymentMode(PaymentMode mode) {
    if (isClosed) return; // فحص أمان
    paymentMode.value = mode;
    
    // إذا تغير الوضع لنقد، نعيد تصفير القائمة لواحدة فقط
    if (mode == PaymentMode.cash || mode == PaymentMode.credit) {
       _resetPaymentEntries();
    }
    
    updateTotals(); // سيقوم بتصفير أو ملء حقل المدفوع تلقائياً بناءً على النوع المختار
  }

  void _resetPaymentEntries() {
    for (var entry in paymentEntries) {
      entry.dispose();
    }
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
    
    // إظهار نافذة اختيار المصدر (كاميرا أو معرض)
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'اخـتـيـار مـصـدر الـصـورة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPickerOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'الـكـامـيـرا',
                  color: Colors.blue,
                  onTap: () async {
                    Get.back();
                    final XFile? image = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
                    if (image != null) _setEntryImage(entry, isTransfer, image.path);
                  },
                ),
                _buildPickerOption(
                  icon: Icons.photo_library_rounded,
                  label: 'الـمـعـرض',
                  color: Colors.purple,
                  onTap: () async {
                    Get.back();
                    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                    if (image != null) _setEntryImage(entry, isTransfer, image.path);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _setEntryImage(PaymentEntry entry, bool isTransfer, String path) {
    if (isTransfer) {
      entry.transferImagePath.value = path;
    } else {
      entry.bankImagePath.value = path;
    }
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

  /// دالة لحساب الكمية المتوفرة الفعلية بعد خصم ما تم إضافته للفاتورة مسبقاً
  double getAvailableQuantity(ProductModel product) {
    double addedQuantityInPrimary = 0;
    for (var item in invoiceItems) {
      if (item.product.id == product.id) {
        double factor = calculateConversionFactor(product, item.selectedUnitId ?? product.unitId!);
        // خصم كل من الكمية الأساسية والمجانية من المتوفر
        double totalItemQty = item.quantity + item.freeQuantity;
        addedQuantityInPrimary += totalItemQty / (factor > 0 ? factor : 1.0);
      }
    }
    return product.quantity - addedQuantityInPrimary;
  }

  void addProductToInvoice(ProductModel product, double quantity, {int? unitId, double freeQuantity = 0.0}) {
    if (product.isSalesStopped) {
      Get.snackbar(
        'منتج موقوف',
        'هذا المنتج موقف من البيع من قبل الإدارة ولا يمكن بيعه حالياً.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (quantity < 0 || freeQuantity < 0) {
      Get.snackbar('خطأ', 'الكمية يجب أن لا تكون سالبة.');
      return;
    }
    
    if (quantity == 0 && freeQuantity == 0) {
      Get.snackbar('خطأ', 'يجب إدخال كمية بيع أو كمية مجانية.');
      return;
    }

    final selectedId = unitId ?? product.unitId;
    
    // التحقق من أن الوحدة مسموحة
    final allowedIds = getAllowedUnitIds(product);
    if (selectedId != null && !allowedIds.contains(selectedId)) {
        Get.snackbar('خطأ', 'هذه الوحدة غير مسموح بالبيع بها لهذا المنتج.');
        return;
    }

    final price = calculatePriceForUnit(product, selectedId!);
    final double conversionFactor = calculateConversionFactor(product, selectedId);
    final double totalQuantityInPrimary = (quantity + freeQuantity) / conversionFactor;

    // التحقق من توفر الكمية في المخزون الحقيقي (المتبقي)
    double available = getAvailableQuantity(product);
    if (totalQuantityInPrimary > available + 0.0001) {
      Get.snackbar(
        'خطأ في الكمية',
        'الكمية الإجمالية (بيع + مجاناً) تتجاوز المتبقي في المخزون (${(available * conversionFactor).toStringAsFixed(2)}).',
      );
      return;
    }

    // التحقق مما إذا كان الصنف موجوداً بالفعل في الفاتورة (بنفس الوحدة)
    final existingItem = invoiceItems.firstWhereOrNull(
      (item) => item.product.id == product.id && item.selectedUnitId == selectedId,
    );

    if (existingItem != null) {
      existingItem.quantity += quantity;
      existingItem.freeQuantity += freeQuantity;
    } else {
      invoiceItems.add(
        SalesInvoiceItem(
          product: product,
          quantity: quantity,
          freeQuantity: freeQuantity,
          salePrice: price,
          selectedUnitId: selectedId,
        ),
      );
    }
    invoiceItems.refresh();
    updateTotals();
  }

  /// دالة مساعدة لحساب معامل التحويل من الوحدة الأساسية لوحدة معينة
  double calculateConversionFactor(ProductModel product, int targetUnitId) {
    if (product.unitId == targetUnitId) return 1.0;

    final unitController = Get.find<UnitController>();
    double factor = 1.0;
    int? currentId = product.unitId;

    while (currentId != null && currentId != targetUnitId) {
      final unit = unitController.allUnits.firstWhereOrNull((u) => u.id == currentId);
      if (unit != null) {
        factor *= unit.conversionFactor;
        currentId = unit.childUnitId;
      } else {
        break;
      }
    }
    return factor;
  }

  void removeProductFromInvoice(int productId, int unitId) {
    invoiceItems.removeWhere((item) => item.product.id == productId && item.selectedUnitId == unitId);
  }

  void updateItemDetails(int productId, {double? newQuantity, double? newFreeQuantity, double? newPrice, int? newUnitId}) {
    final item = invoiceItems.firstWhereOrNull((i) => i.product.id == productId);
    if (item != null) {
      // إذا كان هناك تحديث للكمية، يجب التأكد من عدم تجاوز المخزون الكلي
      if (newQuantity != null || newFreeQuantity != null) {
         // نحسب الكمية المضافة من غير هذا العنصر
         double otherAddedQuantityInPrimary = 0;
         for (var other in invoiceItems) {
           if (other.product.id == productId && other != item) {
             double factor = calculateConversionFactor(other.product, other.selectedUnitId ?? other.product.unitId!);
             double totalOther = other.quantity + other.freeQuantity;
             otherAddedQuantityInPrimary += totalOther / (factor > 0 ? factor : 1.0);
           }
         }
         
         int targetUnitId = newUnitId ?? item.selectedUnitId ?? item.product.unitId!;
         double factor = calculateConversionFactor(item.product, targetUnitId);
         
         double updatedQty = newQuantity ?? item.quantity;
         double updatedFreeQty = newFreeQuantity ?? item.freeQuantity;
         double newTotalQtyInPrimary = (updatedQty + updatedFreeQty) / (factor > 0 ? factor : 1.0);
         
         if (otherAddedQuantityInPrimary + newTotalQtyInPrimary > item.product.quantity + 0.0001) {
           Get.snackbar('خطأ', 'الكمية الإجمالية (بيع + مجاناً) تتجاوز المتاح الكلي للمنتج بالمخزن.');
           return;
         }
         if (newQuantity != null) item.quantity = newQuantity;
         if (newFreeQuantity != null) item.freeQuantity = newFreeQuantity;
      }

      if (newUnitId != null && newUnitId != item.selectedUnitId) {
        if (newPrice == null) {
          newPrice = calculatePriceForUnit(item.product, newUnitId);
        }
        item.selectedUnitId = newUnitId;
      }
      if (newPrice != null) item.salePrice = newPrice;
      
      invoiceItems.refresh();
      updateTotals();
    }
  }

  /// دالة مساعدة لحساب سعر وحدة معينة بناءً على سعر المنتج الأساسي والتحويل
  double calculatePriceForUnit(ProductModel product, int targetUnitId) {
    if (product.unitId == targetUnitId) return product.salePrice;
    double factor = calculateConversionFactor(product, targetUnitId);
    return product.salePrice / (factor > 0 ? factor : 1.0);
  }

  /// دالة لجلب الوحدات المسموح ببيعها فقط لهذا المنتج بشكل صحيح 100%
  List<int> getAllowedUnitIds(ProductModel product) {
    // 1. استخراج السلسلة الكاملة لهذه الوحدة كمرجع موثوق
    List<int> chainIds = [];
    int? currentId = product.unitId;
    final unitController = Get.find<UnitController>();
    
    while (currentId != null) {
      chainIds.add(currentId);
      final unit = unitController.allUnits.firstWhereOrNull((u) => u.id == currentId);
      currentId = unit?.childUnitId;
    }
    
    // 2. التحقق من الوحدات المخصصة للمنتج، ومقاطعتها مع السلسلة حتى نتأكد من عدم وجود بيانات قديمة
    if (product.allowedUnits != null && product.allowedUnits!.isNotEmpty) {
      final validAllowedIds = chainIds.where((id) => product.allowedUnits!.contains(id)).toList();
      // إذا نتج عن المقاطعة وحدات مسموحة صحيحة، نعيدها
      if (validAllowedIds.isNotEmpty) {
        return validAllowedIds;
      }
    }
    
    // 3. كإجراء احتياطي تام، إذا لم تكن هناك وحدات مخصصة، نعيد السلسلة بأكملها لتكون متاحة للبيع
    return chainIds;
  }

  void updateItemPrice(int productId, double newPrice) {
    final item = invoiceItems.firstWhereOrNull(
      (item) => item.product.id == productId,
    );
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
    if (paidAmount.value < 0) {
      Get.snackbar('خطأ', 'المبلغ المدفوع لا يمكن أن يكون سالبًا.');
      return;
    }
    double paymentInPrimary = paidAmount.value;
    if (isLocalCurrencyPayment.value) {
      final settings = Get.find<SettingsService>();
      paymentInPrimary = paidAmount.value / settings.exchangeRate.value;
    }

    // 2. التحقق مما إذا كانت الفاتورة آجلة أو نقدية أو مشتركة
    final double remaining = grandTotal - paymentInPrimary;

    // التحقق من صحة المبالغ بناءً على نوع الدفع
    if (paymentMode.value == PaymentMode.cash && remaining > 0.01) {
      Get.snackbar('خطأ', 'في فواتير النقد، يجب دفع كامل المبلغ.');
      return;
    }
    if (paymentMode.value == PaymentMode.split && (remaining <= 0 || paymentInPrimary <= 0)) {
       if(paymentInPrimary <= 0) {
          Get.snackbar('خطأ', 'في فواتير النقد والآجل، يجب دفع جزء من المبلغ على الأقل.');
          return;
       }
    }

    if (!_validatePayments()) return;

    // حساب إجمالي المدفوع بالعملة الأساسية بجمع كافة الدفعات (لضمان الدقة المطلقة)
    final double exchangeRate = Get.find<SettingsService>().exchangeRate.value;
    double totalPaidInPrimaryFromEntries = 0;
    
    for (var entry in paymentEntries) {
        double entryAmt = double.tryParse(entry.amountController.text) ?? 0.0;
        if (isLocalCurrencyPayment.value) {
            totalPaidInPrimaryFromEntries += entryAmt / exchangeRate;
        } else {
            totalPaidInPrimaryFromEntries += entryAmt;
        }
    }

    _performSave(totalPaidInPrimaryFromEntries);
  }

  /// دالة للتحقق من صحة قائمة المدفوعات قبل الحفظ
  bool _validatePayments() {
    for (int i = 0; i < paymentEntries.length; i++) {
        final entry = paymentEntries[i];
        final amount = double.tryParse(entry.amountController.text) ?? 0.0;
        
        if (amount <= 0 && paymentMode.value != PaymentMode.credit) {
            Get.snackbar('خطأ', 'المبلغ في الدفعة رقم ${i+1} يجب أن يكون أكبر من الصفر.');
            return false;
        }

        if (entry.method.value == PaymentMethod.transfer) {
            if (entry.transferNoController.text.trim().isEmpty) {
                Get.snackbar('خطأ', 'رقم الحوالة إلزامي في الدفعة رقم ${i+1}.');
                return false;
            }
        }
        
        if (entry.method.value == PaymentMethod.bank) {
            if (entry.bankReferenceController.text.trim().isEmpty) {
                Get.snackbar('خطأ', 'الرقم المرجعي للبنك إلزامي في الدفعة رقم ${i+1}.');
                return false;
            }
        }

        // التحقق الإلزامي من اختيار الصندوق (جديد)
        if (amount > 0 && entry.fundId.value == null) {
            Get.snackbar('خطأ', 'الرجاء اختيار الصندوق لعملية الـ ${entry.method.value.name == "cash" ? "نقد" : entry.method.value.name == "bank" ? "بنك" : "حوالة"} في الدفعة رقم ${i+1}.');
            return false;
        }
    }
    return true;
  }

  /// دالة مساعدة لتنفيذ عملية الحفظ الفعلية بعد التحقق
  Future<void> _performSave(double finalPaidInPrimary) async {
    try {
      isSaving(true);
      // إغلاق شاشة المراجعة (BottomSheet)
      if (Get.isBottomSheetOpen ?? false) {
        Get.back();
      }

      String finalNotes = notesController.text;
      if (isLocalCurrencyPayment.value) {
        final settings = Get.find<SettingsService>();
        final localSymbol = settings.localCurrency.value.symbol;
        final rate = settings.exchangeRate.value;
        final localPaid = paidAmount.value;

        finalNotes +=
            '\n[تم الدفع: ${localPaid.toStringAsFixed(2)} $localSymbol (سعر الصرف: $rate)]';
      }

      final authService = Get.find<AuthService>();
      final currentUser = authService.currentUser.value;
      final String issuedByUserName = currentUser != null 
          ? '${currentUser.name} (${currentUser.roleName})' 
          : 'غير محدد';

      // تجهيز قائمة المدفوعات للتخزين
      final List<Map<String, dynamic>> paymentsData = [];
      final double exchangeRate = Get.find<SettingsService>().exchangeRate.value;

      for (var entry in paymentEntries) {
        double entryAmount = double.tryParse(entry.amountController.text) ?? 0.0;
        // تحويل المبلغ للعملة الأساسية إذا كان الدفع محلياً
        if (isLocalCurrencyPayment.value && entryAmount > 0) {
           entryAmount = entryAmount / exchangeRate;
        }

        if (entryAmount > 0 || paymentEntries.length == 1) {
            paymentsData.add({
              'method': entry.method.value.name,
              'amount': entryAmount,
              'transferNumber': entry.transferNoController.text,
              'senderName': entry.senderNameController.text,
              'transferCompany': entry.transferCompanyController.text,
              'transferImage': entry.transferImagePath.value,
              'bankName': entry.bankNameController.text,
              'bankReference': entry.bankReferenceController.text,
              'bankImage': entry.bankImagePath.value,
              'fundId': entry.fundId.value, // الإرسال للمستودع
              'notes': entry.notesController.text,
              'createdAt': DateTime.now().toIso8601String(),
            });
        }
      }

      // تنفيذ الحفظ مع تقريب المبالغ لمرتبتين عشريتين لمنع الديون الوهمية ناتجة عن التحويل
      double remaining = grandTotal - finalPaidInPrimary;
      if (remaining.abs() < 0.01) {
          remaining = 0;
          finalPaidInPrimary = grandTotal;
      }

      final invoiceId = await _salesRepository.createSalesInvoice(
        customerId: selectedCustomer.value!.id,
        invoiceDate: invoiceDate.value,
        totalAmount: grandTotal,
        discountAmount: discountValue.value,
        paidAmount: finalPaidInPrimary,
        remainingAmount: remaining,
        notes: finalNotes,
        items: invoiceItems,
        issuedBy: issuedByUserName,
        payments: paymentsData,
      );

      // تحديث البيانات في الخلفية
      final int? currentCustomerId = selectedCustomer.value?.id;
      await customerController.fetchAllCustomers();
      if (currentCustomerId != null) {
        selectedCustomer.value = customerController.filteredCustomers
            .firstWhereOrNull((c) => c.id == currentCustomerId);
      }
      await productController.fetchAllProducts();

      // تسجيل نشاط المبيعات
      final String paymentMethodAr = paymentMode.value == PaymentMode.cash 
          ? "نقداً" 
          : (paymentMode.value == PaymentMode.credit ? "آجل" : "مجزأ (نقدي وآجل)");
          
      await _activityController.logAction(
        action: 'إصدار فاتورة مبيعات',
        details: 'تم إصدار الفاتورة رقم (#$invoiceId) للعميل "${selectedCustomer.value?.name}". الإجمالي: ${grandTotal.toStringAsFixed(2)}، طريقة الدفع: $paymentMethodAr',
        type: ActivityType.sale,
      );

      isSaving(false);

      // إظهار ديالوج النجاح
      _showSuccessDialog(invoiceId);
    } catch (e) {
      isSaving(false);
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      Get.snackbar(
        'فشل الحفظ',
        errorMessage,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    }
  }

  void _showSuccessDialog(int invoiceId) async {
    // جلب بيانات الفاتورة التي تم حفظها للتو
    final salesDetailsRepo = SalesDetailsRepository();
    final invoiceDetails = await salesDetailsRepo.getInvoiceDetailsById(
      invoiceId,
    );
    final customerName = selectedCustomer.value?.name ?? '';
    final total = grandTotal;

    Get.dialog(
      barrierDismissible: false, // منع إغلاق الديالوج بالضغط في الخارج
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. الأنميشن
            SizedBox(
              width: 150,
              height: 150,
              child: Lottie.asset(
                'assets/animations/success_animation.json',
                repeat: false,
              ),
            ),

            // 2. رسالة النجاح
            const Text(
              'تمت عملية البيع بنجاح',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // 3. ملخص الفاتورة
            _buildSuccessInfoRow('رقم الفاتورة:', '#$invoiceId'),
            _buildSuccessInfoRow('العميل:', customerName),
            _buildSuccessInfoRow(
              'الإجمالي:',
              '${total.toStringAsFixed(2)} ${Get.find<SettingsService>().primaryCurrency.value.symbol}',
            ),
            const Divider(height: 32),

            // 4. أزرار الإجراءات
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
                  SalesInvoicePdfService.printInvoice(invoiceDetails);
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
                _resetInvoiceState();
                if (Get.isDialogOpen ?? false) Get.back();
              },
            ),
            const SizedBox(height: 10),
            TextButton(
              child: const Text('إغلاق', style: TextStyle(color: Colors.grey)),
              onPressed: () {
                if (Get.isDialogOpen ?? false) Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }

  // دالة مساعدة لبناء صفوف المعلومات في الديالوج
  Widget _buildSuccessInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // دالة لإعادة تعيين حالة لإصدار فاتورة جديدة
  void _resetInvoiceState() {
    if (isClosed) return; // فحص أمان
    
    invoiceItems.clear();
    selectedCustomer.value = null;
    discountValue.value = 0.0;
    paidAmount.value = 0.0;
    
    // تصفير الحقول النصية
    invoiceIdController.clear();
    discountController.text = '0.0';
    paidAmountController.text = '0.0';
    taxController.text = '0.0';
    notesController.clear();
    productSearchController.clear(); // مسح نص البحث
    
    selectedSearchCategory.value = null; // إعادة تعيين القسم المختار في البحث
    isLocalCurrencyPayment.value = false; // إعادة تعيين خيار العملة
    paymentMode.value = PaymentMode.cash; // إعادة تعيين وضع الدفع للنقد
    
    _resetPaymentEntries(); // تصفير قائمة المدفوعات لتعود كاش افتراضياً
    
    updateTotals(); // تحديث المجاميع لضمان مزامنة الحقول والواجهة
  }

  @override
  void onClose() {
    invoiceIdController.dispose();
    discountController.removeListener(updateTotals);
    taxController.removeListener(updateTotals);
    paidAmountController.removeListener(updateTotals);
    // --- نهاية التعديل ---
    dateController.dispose();
    discountController.dispose();
    taxController.dispose();
    paidAmountController.dispose();
    notesController.dispose();
    productSearchController.dispose();
    super.onClose();
  }
}
