// File: lib/features/sales/presentation/controllers/add_sales_invoice_controller.dart

import 'package:ehab_company_admin/features/customers/data/models/customer_model.dart';
import 'package:ehab_company_admin/features/customers/presentation/controllers/customer_controller.dart';
import 'package:ehab_company_admin/features/products/data/models/product_model.dart';
import 'package:ehab_company_admin/features/products/presentation/controllers/product_controller.dart';
import 'package:ehab_company_admin/features/sales/data/repositories/sales_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import 'package:lottie/lottie.dart';

import '../../../../core/services/sales_invoice_pdf_service.dart';
import '../../data/repositories/sales_details_repository.dart';


enum DiscountType { amount, percentage }
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
  final Rx<DiscountType> discountType = DiscountType.amount.obs;
  final RxDouble discountPercentage = 0.0.obs;
  final RxDouble taxPercentage = 0.0.obs;
  final RxDouble paidAmount = 0.0.obs;

  // Text Editing Controllers
  final TextEditingController invoiceIdController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController discountController = TextEditingController(text: '0.0');
  final TextEditingController taxController = TextEditingController(text: '0.0');
  final TextEditingController paidAmountController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final productSearchController = TextEditingController();

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      productController.fetchAllProducts();
    });
    dateController.text = intl.DateFormat('yyyy-MM-dd').format(invoiceDate.value);

    discountController.addListener(updateTotals);
    taxController.addListener(updateTotals);
    paidAmountController.addListener(updateTotals);
  }


  void updateTotals() {
    if (discountType.value == DiscountType.amount) {
      // إذا كان الخصم مبلغًا، القيمة هي ما في الحقل مباشرة
      discountValue.value = double.tryParse(discountController.text) ?? 0.0;
    } else {
      // إذا كان الخصم نسبة، قم بحساب القيمة
      discountPercentage.value = double.tryParse(discountController.text) ?? 0.0;
      discountValue.value = subtotal * (discountPercentage.value / 100);
    }

    // باقي الحسابات تبقى كما هي
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
    if (paidAmount.value < 0) {
      Get.snackbar('خطأ', 'المبلغ المدفوع لا يمكن أن يكون سالبًا.');
      return;
    }
    if (paidAmount.value > grandTotal) {
      Get.snackbar('خطأ', 'المبلغ المدفوع لا يمكن أن يكون أكبر من الإجمالي النهائي.');
      return;
    }

    // 2. التحقق مما إذا كانت الفاتورة آجلة
    if (remainingAmount > 0) {
      // إذا كان هناك مبلغ متبقٍ، اعرض ديالوج التأكيد
      Get.defaultDialog(
        title: "تأكيد الفاتورة الآجلة",
        middleText:
        "المبلغ المدفوع أقل من الإجمالي. سيتم تسجيل المبلغ المتبقي (${remainingAmount.toStringAsFixed(2)} ريال) كدين على العميل. هل تريد المتابعة؟",
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
      isSaving(true);
      // إغلاق شاشة المراجعة (BottomSheet)
      if (Get.isBottomSheetOpen ?? false) {
        Get.back();
      }

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

      // تحديث البيانات في الخلفية
      final int? currentCustomerId = selectedCustomer.value?.id;
      await customerController.fetchAllCustomers();
      if (currentCustomerId != null) {
        selectedCustomer.value = customerController.filteredCustomers
            .firstWhereOrNull((c) => c.id == currentCustomerId);
      }
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
  void _showSuccessDialog(int invoiceId) async {
    // جلب بيانات الفاتورة التي تم حفظها للتو
    final salesDetailsRepo = SalesDetailsRepository();
    final invoiceDetails = await salesDetailsRepo.getInvoiceDetailsById(invoiceId);
    final customerName =selectedCustomer.value?.name ?? '';
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
            _buildSuccessInfoRow('الإجمالي:', '${total.toStringAsFixed(2)} ريال'),
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
                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 45),
                ),
              onPressed: () {
                if (Get.isDialogOpen ?? false) Get.back(); // إغلاق الديالوج

                // --- بداية التعديل ---
                // يجب إغلاق الشاشة الحالية قبل إعادة تعيين الحالة والانتقال
                Get.back();
                // --- نهاية التعديل ---

                // إعادة تعيين الحالة لبدء فاتورة جديدة
                _resetInvoiceState();
                Get.toNamed('/add_sales_invoice');
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

// دالة لإعادة تعيين حالة
  void _resetInvoiceState() {
    invoiceItems.clear();
    selectedCustomer.value = null;
    discountValue.value = 0.0;
    paidAmount.value = 0.0;
    discountController.text = '0.0';
    paidAmountController.text = '0.0';
    notesController.clear();
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
