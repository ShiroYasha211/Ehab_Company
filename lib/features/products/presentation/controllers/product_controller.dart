// File: lib/features/products/presentation/controllers/product_controller.dart

import 'package:ehab_company_admin/features/products/data/models/product_model.dart';
import 'package:ehab_company_admin/features/products/data/repositories/product_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart'; // <-- 1. إضافة import للتعامل مع أخطاء قاعدة البيانات

import '../../../../core/services/import_serivce.dart';
import '../../../categories/presentation/controllers/category_controller.dart';

enum ProductSortOption {
  newest,
  oldest,
  nameAsc,
  nameDesc,
  quantityDesc,
  quantityAsc,
}

enum ExpiryFilterOption { all, expiringSoon, expired }

enum ProductViewMode { list, grid }

class ProductController extends GetxController {
  final ProductRepository _repository = ProductRepository();
  final CategoryController _categoryController = Get.find<CategoryController>();

  final RxList<ProductModel> _allProducts = <ProductModel>[].obs;
  final RxList<ProductModel> filteredProducts = <ProductModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxString searchQuery = ''.obs;

  final Rx<ProductSortOption> sortOption = ProductSortOption.newest.obs;
  final Rx<ExpiryFilterOption> expiryFilter = ExpiryFilterOption.all.obs;

  final Rx<ProductViewMode> viewMode = ProductViewMode.list.obs;

  RxList<String> get categoryNames => _categoryController.categories.map((c) => c.name).toList().obs;

  final RxDouble totalPurchaseValue = 0.0.obs;
  final RxDouble totalSaleValue = 0.0.obs;
  final RxBool isCalculatingValue = true.obs;

  List<ProductModel> get allProducts => _allProducts.toList();

  @override
  void onInit() {
    super.onInit();
    fetchAllProducts();
    debounce(searchQuery, (_) => _filterAndSortProducts(), time: const Duration(milliseconds: 300));
    ever(sortOption, (_) => _filterAndSortProducts());
    ever(expiryFilter, (_) => _filterAndSortProducts());
  }

  void toggleViewMode() {
    viewMode.value =
    viewMode.value == ProductViewMode.list ? ProductViewMode.grid : ProductViewMode.list;
  }

  Future<void> fetchAllProducts() async {
    if (_allProducts.isEmpty) {
      isLoading(true);
    }
    try {
      // isLoading(true); // <<-- هذا تكرار، يمكن حذفه
      final productList = await _repository.getAllProducts();
      _allProducts.assignAll(productList);
      // --- بداية التعديل: ضمان تحديث القائمة المفلترة ---
      // هذا السطر يضمن أن القائمة المفلترة يتم تحديثها بالبيانات الجديدة
      // حتى لو لم يكن هناك فلتر بحث نشط.
      filteredProducts.assignAll(productList);
      // --- نهاية التعديل ---
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ أثناء جلب المنتجات: $e', snackPosition: SnackPosition.BOTTOM);
    } finally {
      _filterAndSortProducts();
      isLoading(false);
    }
  }

  // --- 2. بداية التعديل: إعادة كتابة دالة إضافة المنتج بالكامل ---
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
    // التحقق من الباركود أولاً إذا كان غير فارغ
    if (code != null && code.trim().isNotEmpty) {
      final existingProduct = await _repository.getProductByBarcode(code.trim());
      if (existingProduct != null) {
        // إذا كان الباركود موجودًا، اعرض ديالوج التحذير
        _showBarcodeConflictDialog(existingProduct, onConfirm: () {
          // في حال وافق المستخدم على الاستبدال، قم بتحديث المنتج القديم
          updateProduct(
            id: existingProduct.id!,
            createdAt: existingProduct.createdAt, // استخدم تاريخ الإنشاء القديم
            name: name,
            code: code,
            quantity: quantity,
            purchasePrice: purchasePrice,
            salePrice: salePrice,
            imageUrl: imageUrl,
            minStockLevel: minStockLevel,
            category: category,
            unit: unit,
            productionDate: productionDate,
            expiryDate: expiryDate,
          );
        });
        return; // أوقف عملية الإضافة
      }
    }

    // إذا لم يكن هناك تعارض، قم بعملية الإضافة كالمعتاد
    _performAddProduct(
        name: name, code: code, description: description, quantity: quantity,
        purchasePrice: purchasePrice, salePrice: salePrice, imageUrl: imageUrl,
        minStockLevel: minStockLevel, category: category, unit: unit,
        productionDate: productionDate, expiryDate: expiryDate
    );
  }

  /// دالة مساعدة لتنفيذ عملية الإضافة الفعلية
  Future<void> _performAddProduct({
    required String name, String? code, String? description, required double quantity,
    required double purchasePrice, required double salePrice, String? imageUrl,
    double? minStockLevel, String? category, String? unit,
    DateTime? productionDate, DateTime? expiryDate,
  }) async {
    try {
      final newProduct = ProductModel(
        name: name, code: code, description: description, quantity: quantity,
        purchasePrice: purchasePrice, salePrice: salePrice, imageUrl: imageUrl,
        minStockLevel: minStockLevel ?? 0, category: category, unit: unit,
        productionDate: productionDate, expiryDate: expiryDate, createdAt: DateTime.now(),
      );
      await _repository.addProduct(newProduct);
      await fetchAllProducts();
      if (Get.isDialogOpen ?? false) Get.back();
      Get.back(); // العودة من شاشة الإضافة
      Get.snackbar('نجاح', 'تمت إضافة المنتج بنجاح.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        Get.snackbar('خطأ', 'الباركود "$code" مستخدم بالفعل لمنتج آخر.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      } else {
        Get.snackbar('خطأ في قاعدة البيانات', e.toString(), snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ أثناء إضافة المنتج: $e', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  /// ديالوج لعرض تحذير تعارض الباركود
  void _showBarcodeConflictDialog(ProductModel existingProduct, {required VoidCallback onConfirm}) {
    Get.defaultDialog(
      title: "تحذير: الباركود مستخدم",
      titleStyle: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold),
      middleText: 'هذا الباركود مسجل بالفعل للمنتج:\n"${existingProduct.name}"\n\nهل تريد استبدال بيانات المنتج القديم بالبيانات الجديدة؟',
      textConfirm: "نعم، استبدال",
      confirmTextColor: Colors.white,
      onConfirm: () {
        if(Get.isDialogOpen ?? false) Get.back(); // إغلاق ديالوج التحذير
        onConfirm(); // تنفيذ عملية الاستبدال (التحديث)
      },
      textCancel: "إلغاء",
      onCancel: () {},
    );
  }
  // --- نهاية التعديل ---


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
        id: id, createdAt: createdAt, name: name, code: code, quantity: quantity,
        purchasePrice: purchasePrice, salePrice: salePrice, category: category, unit: unit,
        productionDate: productionDate, expiryDate: expiryDate, imageUrl: imageUrl,
        minStockLevel: minStockLevel ?? 0.0,
      );

      await _repository.updateProduct(updatedProduct);
      await fetchAllProducts();

      // التحقق مما إذا كانت هناك أي نوافذ مفتوحة (مثل ديالوج التحذير) قبل العودة من شاشة التعديل الرئيسية
      if(Get.isOverlaysOpen) {
        Get.back(); // يغلق الديالوج أو الـ snackbar
      }
      if(Get.isBottomSheetOpen ?? false){
        Get.back(); // يغلق bottom sheet
      }
      // وأخيراً، العودة من شاشة الإضافة/التعديل نفسها
      if(Get.currentRoute != '/ProductsScreen') { // تأكد أننا لسنا في الشاشة الرئيسية
        Get.back();
      }


      Get.snackbar('نجاح', 'تم تعديل المنتج بنجاح.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.blue, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('خطأ في التعديل', 'حدث خطأ غير متوقع: $e', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  // --- 3. بداية الحذف: قم بحذف دالة _filterProducts القديمة ---
  // void _filterProducts() { ... } // <<-- هذه الدالة يجب حذفها

  // ... باقي دوال الكلاس تبقى كما هي (deleteProduct, getInventoryValue, etc.)
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

  void _filterAndSortProducts() {
    List<ProductModel> _tempList = List.from(_allProducts);

    // 1. تطبيق فلتر البحث
    final query = searchQuery.value.toLowerCase().trim();
    if (query.isNotEmpty) {
      _tempList = _tempList.where((product) {
        final nameMatches = product.name.toLowerCase().contains(query);
        final codeMatches = product.code?.toLowerCase().contains(query) ?? false;
        return nameMatches || codeMatches;
      }).toList();
    }

    // 2. تطبيق فلتر الصلاحية
    switch (expiryFilter.value) {
      case ExpiryFilterOption.expiringSoon:
        _tempList = _tempList.where((p) => p.isExpiringSoon).toList();
        break;
      case ExpiryFilterOption.expired:
        _tempList = _tempList.where((p) => p.isExpired).toList();
        break;
      case ExpiryFilterOption.all:
      // لا تفعل شيئًا
        break;
    }

    // 3. تطبيق الفرز
    switch (sortOption.value) {
      case ProductSortOption.newest:
        _tempList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case ProductSortOption.oldest:
        _tempList.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case ProductSortOption.nameAsc:
        _tempList.sort((a, b) => a.name.compareTo(b.name));
        break;
      case ProductSortOption.nameDesc:
        _tempList.sort((a, b) => b.name.compareTo(a.name));
        break;
      case ProductSortOption.quantityDesc:
        _tempList.sort((a, b) => b.quantity.compareTo(a.quantity));
        break;
      case ProductSortOption.quantityAsc:
        _tempList.sort((a, b) => a.quantity.compareTo(b.quantity));
        break;
    }

    filteredProducts.assignAll(_tempList);
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

  Future<void> deleteProduct(int id) async {
    try {
      await _repository.deleteProduct(id);
      _allProducts.removeWhere((product) => product.id == id);
      _filterAndSortProducts();
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
}
