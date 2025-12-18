// File: lib/features/products/presentation/controllers/product_controller.dart


import 'package:ehab_company_admin/features/products/data/models/product_model.dart';
import 'package:ehab_company_admin/features/products/data/repositories/product_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/services/import_serivce.dart';
import '../../../categories/presentation/controllers/category_controller.dart';

class ProductController extends GetxController {
  final ProductRepository _repository = ProductRepository();
  final CategoryController _categoryController = Get.find<CategoryController>(); // <-- إضافة جديدة

  final RxList<ProductModel> _allProducts = <ProductModel>[].obs;
  final RxList<ProductModel> filteredProducts = <ProductModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxString searchQuery = ''.obs;
  RxList<String> get categoryNames => _categoryController.categories.map((c) => c.name).toList().obs;

  final RxDouble totalPurchaseValue = 0.0.obs;
  final RxDouble totalSaleValue = 0.0.obs;
  final RxBool isCalculatingValue = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAllProducts();
    debounce(searchQuery, (_) => _filterProducts(), time: const Duration(milliseconds: 300));
  }
  final ImportService _importService = ImportService();
  final RxBool isImporting = false.obs;

  /// دالة لبدء عملية الاستيراد من الواجهة
  Future<void> importProducts(String filePath) async {
    try {
      isImporting(true);
      Get.snackbar(
        'جاري الاستيراد...',
        'الرجاء الانتظار، قد تستغرق العملية بعض الوقت.',
        showProgressIndicator: true,
        isDismissible: false,
      );

      final result = await _importService.importProductsFromExcel(filePath);

      // تحديث قائمة المنتجات بعد الاستيراد
      await fetchAllProducts();
      isImporting(false);

      // إغلاق رسالة التحميل وعرض النتيجة
      if (Get.isSnackbarOpen) {
        Get.closeCurrentSnackbar();
      }

      Get.defaultDialog(
        title: 'اكتملت عملية الاستيراد',
        middleText:
        'تم استيراد ${result['success']} منتج بنجاح.\nفشل استيراد ${result['failure']} منتج.',
        textConfirm: 'موافق',
        onConfirm: () => Get.back(),
      );

    } catch (e) {
      isImporting(false);
      Get.snackbar(
        'فشل الاستيراد',
        'حدث خطأ غير متوقع أثناء قراءة الملف: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  // --- نهاية الإضافة ---
  Future<void> fetchAllProducts() async {
    if(_allProducts.isEmpty){
      isLoading(true);
    }
    try {
      isLoading(true);
      final productList = await _repository.getAllProducts();
      _allProducts.assignAll(productList);
      _filterProducts();
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ أثناء جلب المنتجات: $e', snackPosition: SnackPosition.BOTTOM);
    } finally {
      _filterProducts();
      isLoading(false);
    }
  }

  Future<void> getInventoryValue() async {
    isCalculatingValue(true);
    try {
      final values = await _repository.getInventoryValue();
      totalPurchaseValue.value = values['totalPurchaseValue'] ?? 0.0;
      totalSaleValue.value = values['totalSaleValue'] ?? 0.0;
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في حساب قيمة المخزون: $e');
    } finally {
      isCalculatingValue(false);
    }
  }

  void _filterProducts() {
    final query = searchQuery.value.toLowerCase().trim();
    if (query.isEmpty) {
      filteredProducts.assignAll(_allProducts);
    } else {
      filteredProducts.assignAll(_allProducts.where((product) {
        final nameMatches = product.name.toLowerCase().contains(query);
        final codeMatches = product.code?.toLowerCase().contains(query) ?? false;
        return nameMatches || codeMatches;
      }).toList());
    }
  }

  Future<void> addNewProduct({
    required String name,
    String? code,
    String? description,
    required double quantity,
    required double purchasePrice,
    required double salePrice,
    String? imageUrl,
    double? minStockLevel,
    String? category,
    String? unit,
    DateTime? productionDate,
    DateTime? expiryDate,
  }) async {
    try {
      final newProduct = ProductModel(
        name: name, code: code, description: description, quantity: quantity,
        purchasePrice: purchasePrice, salePrice: salePrice, imageUrl: imageUrl,
        minStockLevel: minStockLevel ?? 0,
        category: category, unit: unit, productionDate: productionDate,
        expiryDate: expiryDate, createdAt: DateTime.now(),
      );
      await _repository.addProduct(newProduct);
      await fetchAllProducts();
      if(Get.isDialogOpen ?? false) Get.back();
      Get.back();
      Get.snackbar('نجاح', 'تمت إضافة المنتج بنجاح.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ أثناء إضافة المنتج: $e', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  /// دالة لتعديل منتج موجود
  Future<void> updateProduct({
    required int id,
    required String name,
    String? code,
    required double quantity,
    required double purchasePrice,
    required double salePrice,
    String? category,
    String? unit,
    DateTime? productionDate,
    DateTime? expiryDate,
    String? imageUrl,
    double? minStockLevel,
    required DateTime createdAt,
  }) async {
    try {
      final updatedProduct = ProductModel(
        id: id, createdAt: createdAt, name: name, code: code, quantity: quantity ,
        purchasePrice: purchasePrice , salePrice: salePrice , category: category, unit: unit,
        productionDate: productionDate, expiryDate: expiryDate, imageUrl: imageUrl,
        minStockLevel: minStockLevel ?? 0.0,
      );

      await _repository.updateProduct(updatedProduct);
      await fetchAllProducts();

      Get.back(); // العودة من شاشة التعديل

      Get.snackbar('نجاح', 'تم تعديل المنتج بنجاح.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.blue, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('خطأ في التعديل', 'حدث خطأ غير متوقع: $e', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> deleteProduct(int id) async {
    try {
      await _repository.deleteProduct(id);
      _allProducts.removeWhere((product) => product.id == id);
      _filterProducts();
      Get.snackbar('نجاح', 'تم حذف المنتج بنجاح.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.blue, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ أثناء حذف المنتج: $e', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
  Future<void> applyBulkPriceUpdate({
    required String scope,
    String? category,
    required String targetPriceField,
    required String operationType,
    required String calculationMethod,
    required double value1,
    double? value2,
  }) async {
    try {
      // التحقق من المدخلات
      if (scope == 'category' && (category == null || category.isEmpty)) {
        Get.snackbar('خطأ', 'الرجاء اختيار قسم لتطبيق التغييرات عليه.');
        return;
      }

      final String? targetCategory = (scope == 'category') ? category : null;

      final int updatedRows = await _repository.bulkUpdatePrices(
        category: targetCategory,
        targetPriceField: targetPriceField,
        operationType: operationType,
        calculationMethod: calculationMethod,
        value1: value1,
        value2: value2,
      );

      // تحديث البيانات في الواجهة
      await fetchAllProducts();

      Get.snackbar(
        'نجاح العملية',
        'تم تحديث أسعار $updatedRows منتج بنجاح.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

    } catch (e) {
      Get.snackbar(
        'فشل العملية',
        'حدث خطأ غير متوقع: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  Future<void> downloadTemplate() async {
    try {
      // تم تغيير المنطق هنا. الدالة الآن تفتح الملف مباشرة.
      await _importService.createExcelTemplate();

      // يمكن عرض رسالة بسيطة هنا إذا أردت، ولكن فتح الملف هو التنبيه الأفضل.
      Get.snackbar(
        'تم إنشاء القالب',
        'يتم الآن فتح ملف Excel...',
        snackPosition: SnackPosition.BOTTOM,
      );

    } catch (e) {
      Get.snackbar(
        'فشل تنزيل القالب',
        e.toString().replaceAll('Exception: ', ''), // لإزالة كلمة Exception من الرسالة
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
// --- نهاية الإضافة ---
}