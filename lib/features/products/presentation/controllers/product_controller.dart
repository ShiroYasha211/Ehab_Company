// File: lib/features/products/presentation/controllers/product_controller.dart

import 'package:ehab_company_admin/features/products/data/models/product_model.dart';
import 'package:ehab_company_admin/features/products/data/repositories/product_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart'; // <-- 1. إضافة import للتعامل مع أخطاء قاعدة البيانات

import '../../../../core/services/import_service.dart';
import '../../../categories/presentation/controllers/category_controller.dart';
import 'package:ehab_company_admin/features/activities/data/models/activity_model.dart';
import 'package:ehab_company_admin/features/activities/presentation/controllers/activity_controller.dart';

enum ProductSortOption {
  newest,
  oldest,
  nameAsc,
  nameDesc,
  quantityDesc,
  quantityAsc,
}

enum ExpiryFilterOption { all, expiringSoon, expired, suspended }

enum ProductViewMode { list, grid }

class ProductController extends GetxController {
  final ProductRepository _repository = ProductRepository();
  final CategoryController _categoryController = Get.find<CategoryController>();
  final ActivityController _activityController = Get.find<ActivityController>();

  final RxList<ProductModel> _allProducts = <ProductModel>[].obs;
  final RxList<ProductModel> filteredProducts = <ProductModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxString searchQuery = ''.obs;

  final Rx<ProductSortOption> sortOption = ProductSortOption.newest.obs;
  final Rx<ExpiryFilterOption> expiryFilter = ExpiryFilterOption.all.obs;

  final Rx<ProductViewMode> viewMode = ProductViewMode.list.obs;
  final RxString selectedCategory = 'الكل'.obs;
  final RxBool showStoppedOnly = false.obs; // <-- إضافة فلتر الموقوفة

  List<String> get categoryNames => _categoryController.categories.map((c) => c.name).toList();

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
    ever(selectedCategory, (_) => _filterAndSortProducts());
    ever(showStoppedOnly, (_) => _filterAndSortProducts());
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
    int? unitId,
    DateTime? productionDate,
    DateTime? expiryDate,
    List<int>? allowedUnits,
    bool isSalesStopped = false, // <-- إضافة
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
            unitId: unitId,
            productionDate: productionDate,
            expiryDate: expiryDate,
            allowedUnits: allowedUnits,
            isSalesStopped: isSalesStopped, // <-- إضافة
          );
        });
        return; // أوقف عملية الإضافة
      }
    }

    // إذا لم يكن هناك تعارض، قم بعملية الإضافة كالمعتاد
    _performAddProduct(
        name: name, code: code, description: description, quantity: quantity,
        purchasePrice: purchasePrice, salePrice: salePrice, imageUrl: imageUrl,
        minStockLevel: minStockLevel, category: category, unitId: unitId,
        productionDate: productionDate, expiryDate: expiryDate,
        allowedUnits: allowedUnits,
        isSalesStopped: isSalesStopped // <-- إضافة
    );
  }

  /// دالة مساعدة لتنفيذ عملية الإضافة الفعلية
  Future<void> _performAddProduct({
    required String name, String? code, String? description, required double quantity,
    required double purchasePrice, required double salePrice, String? imageUrl,
    double? minStockLevel, String? category, int? unitId,
    DateTime? productionDate, DateTime? expiryDate,
    List<int>? allowedUnits,
    bool isSalesStopped = false, // <-- إضافة
  }) async {
    try {
      final newProduct = ProductModel(
        name: name, code: code, description: description, quantity: quantity,
        purchasePrice: purchasePrice, salePrice: salePrice, imageUrl: imageUrl,
        minStockLevel: minStockLevel ?? 0, category: category, unitId: unitId,
        productionDate: productionDate, expiryDate: expiryDate, 
        allowedUnits: allowedUnits,
        isSalesStopped: isSalesStopped, // <-- إضافة
        createdAt: DateTime.now(),
      );
      await _repository.addProduct(newProduct);
      
      // تسجيل النشاط
      await _activityController.logAction(
        action: 'إضافة منتج جديد',
        details: 'تمت إضافة المنتج "$name" بباركود "${code ?? "بدون"}" وكمية $quantity',
        type: ActivityType.inventory,
      );

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
    int? unitId,
    DateTime? productionDate,
    DateTime? expiryDate,
    String? imageUrl,
    double? minStockLevel,
    List<int>? allowedUnits,
    required DateTime createdAt,
    bool isSalesStopped = false,
  }) async {
    try {
      // 1. جلب نسخة المنتج الحالية لمقارنة التغييرات (Audit Logic)
      final oldProduct = _allProducts.firstWhereOrNull((p) => p.id == id);
      
      final updatedProduct = ProductModel(
        id: id, createdAt: createdAt, name: name, code: code, quantity: quantity,
        purchasePrice: purchasePrice, salePrice: salePrice, category: category, unitId: unitId,
        productionDate: productionDate, expiryDate: expiryDate, imageUrl: imageUrl,
        minStockLevel: minStockLevel ?? 0.0,
        allowedUnits: allowedUnits,
        isSalesStopped: isSalesStopped,
      );

      await _repository.updateProduct(updatedProduct);

      // 2. تحليل التغييرات الدقيقة لتدوينها في السجل
      String changes = '';
      if (oldProduct != null) {
        List<String> changeList = [];
        if (oldProduct.name != name) changeList.add('الاسم: "${oldProduct.name}" -> "$name"');
        if (oldProduct.purchasePrice != purchasePrice) changeList.add('سعر الشراء: ${oldProduct.purchasePrice} -> $purchasePrice');
        if (oldProduct.salePrice != salePrice) changeList.add('سعر البيع: ${oldProduct.salePrice} -> $salePrice');
        if (oldProduct.code != code) changeList.add('الباركود: "${oldProduct.code ?? ''}" -> "${code ?? ''}"');
        if (oldProduct.category != category) changeList.add('التصنيف: "${oldProduct.category ?? ''}" -> "${category ?? ''}"');
        if (oldProduct.isSalesStopped != isSalesStopped) changeList.add('حالة البيع: ${oldProduct.isSalesStopped ? "موقف" : "نشط"} -> ${isSalesStopped ? "موقف" : "نشط"}');
        
        changes = changeList.isNotEmpty ? 'التعديلات: (${changeList.join(')، (')})' : 'لم يتم تغيير أي بيانات أساسية.';
      }

      // تسجيل النشاط
      await _activityController.logAction(
        action: 'تعديل بيانات منتج',
        details: 'المنتج: "$name" (المعرف: $id). $changes',
        type: ActivityType.inventory,
      );

      await fetchAllProducts();

      if(Get.isOverlaysOpen) Get.back();
      if(Get.isBottomSheetOpen ?? false) Get.back();
      if(Get.currentRoute != '/ProductsScreen') Get.back();

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
      
      // تسجيل النشاط
      await _activityController.logAction(
        action: 'استيراد من Excel',
        details: 'تم استيراد ${result['success']} منتج بنجاح، وفشل ${result['failure']} منتج.',
        type: ActivityType.inventory,
      );

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
      case ExpiryFilterOption.suspended:
        _tempList = _tempList.where((p) => p.isSalesStopped).toList();
        break;
      case ExpiryFilterOption.all:
        break;
    }

    // 3. تطبيق فلتر القسم
    if (selectedCategory.value != 'الكل') {
      _tempList = _tempList.where((p) => p.category == selectedCategory.value).toList();
    }

    // 4. تطبيق فلتر المنتجات الموقوفة
    if (showStoppedOnly.value) {
      _tempList = _tempList.where((p) => p.isSalesStopped).toList();
    }

    // 5. تطبيق الفرز
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
      final product = _allProducts.firstWhereOrNull((p) => p.id == id);
      
      // تسجيل النشاط
      await _activityController.logAction(
        action: 'حذف منتج',
        details: 'تم حذف المنتج "${product?.name ?? "غير معروف"}" (المعرف: $id) نهائياً.',
        type: ActivityType.inventory,
      );

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

      // تعريب المعايير للسجل
      final String arScope = (scope == 'all') ? 'الكل' : 'قسم ($category)';
      final String arPriceField = (targetPriceField == 'salePrice') ? 'سعر البيع' : 'سعر الشراء';
      final String arOpType = (operationType == 'increase') ? 'زيادة' : (operationType == 'decrease' ? 'نقص' : 'تحديد');
      final String arCalcMethod = (calculationMethod == 'fixed') ? 'قيمة ثابتة' : 'نسبة مئوية';

      // تسجيل النشاط
      await _activityController.logAction(
        action: 'تحديث أسعار جماعي',
        details: 'تم تحديث أسعار $updatedRows منتج في نطاق ($arScope). الإجراء: ($arOpType) لـ ($arPriceField) باستخدام ($arCalcMethod). القيمة: $value1',
        type: ActivityType.inventory,
      );

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

  /// دالة لتبديل حالة إيقاف البيع للمنتج فوراً
  Future<void> toggleProductSalesStatus(ProductModel product) async {
    try {
      final updatedProduct = ProductModel(
        id: product.id,
        name: product.name,
        code: product.code,
        description: product.description,
        quantity: product.quantity,
        purchasePrice: product.purchasePrice,
        salePrice: product.salePrice,
        category: product.category,
        unitId: product.unitId,
        productionDate: product.productionDate,
        expiryDate: product.expiryDate,
        imageUrl: product.imageUrl,
        minStockLevel: product.minStockLevel,
        allowedUnits: product.allowedUnits,
        isSalesStopped: !product.isSalesStopped, // عكس الحالة الحالية
        createdAt: product.createdAt,
      );

      await _repository.updateProduct(updatedProduct);
      await fetchAllProducts();
      
      // تسجيل النشاط
      await _activityController.logAction(
        action: updatedProduct.isSalesStopped ? 'إيقاف منتج' : 'تنشيط منتج',
        details: 'تم ${updatedProduct.isSalesStopped ? "إيقاف" : "إعادة تنشيط"} بيع المنتج "${product.name}"',
        type: ActivityType.inventory,
      );

      Get.snackbar(
        'تحديث الحالة',
        updatedProduct.isSalesStopped ? 'تم إيقاف بيع المنتج' : 'تم تفعيل بيع المنتج',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: updatedProduct.isSalesStopped ? Colors.orange : Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('خطأ', 'فشل تحديث الحالة: $e', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
}