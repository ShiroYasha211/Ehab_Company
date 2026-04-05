// File: lib/features/warehouses/presentation/controllers/inventory_transfer_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../categories/presentation/controllers/category_controller.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/presentation/controllers/product_controller.dart';
import '../../data/models/inventory_transfer_model.dart';
import '../../data/models/warehouse_model.dart';
import '../../data/repositories/inventory_transfer_repository.dart';
import '../../data/repositories/warehouse_repository.dart';
import '../controllers/warehouse_controller.dart';

import '../../../units/presentation/controllers/unit_controller.dart';

/// عنصر واحد في سند التحويل قيد الإنشاء
class TransferCartItem {
  final ProductModel product;
  double quantity; // الكمية بالوحدة المختارة
  final int unitId;
  final String unitName;
  final double conversionFactor;

  TransferCartItem({
    required this.product, 
    this.quantity = 1.0,
    required this.unitId,
    required this.unitName,
    required this.conversionFactor,
  });

  // السعر للوحدة المختارة (مثال: سعر الكرتون 120، ومعامل الباكت 6، السعر للباكت 120/6 = 20)
  double get unitSalePrice => product.salePrice / (conversionFactor > 0 ? conversionFactor : 1.0);
  double get unitPurchasePrice => product.purchasePrice / (conversionFactor > 0 ? conversionFactor : 1.0);

  double get totalSaleValue => quantity * unitSalePrice;
  double get totalCostValue => quantity * unitPurchasePrice;
  
  // الكمية بالوحدة الأساسية (للمخزن) (مثال: 6 بواكت / 6 = 1 كرتون)
  double get quantityInBaseUnit => quantity / (conversionFactor > 0 ? conversionFactor : 1.0);
}

class InventoryTransferController extends GetxController {
  final InventoryTransferRepository _transferRepo = InventoryTransferRepository();
  final WarehouseRepository _warehouseRepo = WarehouseRepository();
  final ProductController productController = Get.find<ProductController>();
  final WarehouseController warehouseController = Get.find<WarehouseController>();
  final CategoryController categoryController = Get.find<CategoryController>();
  final UnitController unitController = Get.find<UnitController>();

  // البحث السحري
  final RxnString selectedSearchCategory = RxnString(null);
  final productSearchController = TextEditingController();

  // سندات التحويل
  final RxList<InventoryTransferModel> transfers = <InventoryTransferModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;

  // سلة التحويل الحالي
  final RxList<TransferCartItem> cartItems = <TransferCartItem>[].obs;
  final Rx<WarehouseModel?> sourceWarehouse = Rx<WarehouseModel?>(null);
  final Rx<WarehouseModel?> destinationWarehouse = Rx<WarehouseModel?>(null);
  final notesController = TextEditingController();

  // إجماليات
  double get totalSaleValue =>
      cartItems.fold(0.0, (sum, item) => sum + item.totalSaleValue);
  double get totalCostValue =>
      cartItems.fold(0.0, (sum, item) => sum + item.totalCostValue);
  int get totalItems => cartItems.length;

  @override
  void onInit() {
    super.onInit();
    // الافتراضي: المصدر = المخزن الرئيسي دائماً
    _setMainAsDefaultSource();
    fetchAllTransfers();
  }

  void _setMainAsDefaultSource() {
    final main = warehouseController.mainWarehouse;
    if (main != null) {
      sourceWarehouse.value = main;
    }
  }

  Future<void> fetchAllTransfers({int? warehouseId}) async {
    try {
      isLoading(true);
      final list = await _transferRepo.getAllTransfers(warehouseId: warehouseId);
      transfers.assignAll(list);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في جلب السندات: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading(false);
    }
  }

  /// إضافة منتج لسلة التحويل مع مراعاة الوحدة
  void addToCart(ProductModel product, double quantity, {int? unitId, String? unitName, double? factor}) {
    final selectedUnitId = unitId ?? product.unitId!;
    final selectedUnitName = unitName ?? unitController.getUnitName(selectedUnitId);
    final selectedFactor = factor ?? calculateConversionFactor(product, selectedUnitId);

    // البحث عن المنتج بنفس الوحدة في السلة
    final existing = cartItems.firstWhereOrNull(
      (i) => i.product.id == product.id && i.unitId == selectedUnitId
    );

    if (existing != null) {
      existing.quantity += quantity;
      cartItems.refresh();
    } else {
      cartItems.add(TransferCartItem(
        product: product, 
        quantity: quantity,
        unitId: selectedUnitId,
        unitName: selectedUnitName,
        conversionFactor: selectedFactor,
      ));
    }
  }

  double calculateConversionFactor(ProductModel product, int targetUnitId) {
    if (product.unitId == targetUnitId) return 1.0;
    
    // نبدأ من الوحدة الأساسية (وحدة المنتج الكبرى، مثلاً كرتون)
    // وننزل للمستويات الصغرى (مثلاً باكت) ونحسب كم باكت في الكرتون
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

  /// لحساب الكمية المتوفرة الفعلية بعد خصم ما تم إضافته للسند مسبقاً
  double getAvailableQuantity(ProductModel product) {
    double addedQuantityInPrimary = 0;
    for (var item in cartItems) {
      if (item.product.id == product.id) {
        double factor = calculateConversionFactor(product, item.unitId);
        addedQuantityInPrimary += item.quantity / (factor > 0 ? factor : 1.0);
      }
    }
    return product.quantity - addedQuantityInPrimary;
  }

  /// إزالة منتج من السلة
  void removeFromCart(int productId) {
    cartItems.removeWhere((i) => i.product.id == productId);
  }

  /// تحديث كمية منتج في السلة
  void updateCartQuantity(int productId, double newQuantity) {
    final item = cartItems.firstWhereOrNull((i) => i.product.id == productId);
    if (item != null) {
      item.quantity = newQuantity;
      cartItems.refresh();
    }
  }

  /// تنفيذ سند التحويل
  Future<void> executeTransfer() async {
    if (sourceWarehouse.value == null || destinationWarehouse.value == null) {
      Get.snackbar('خطأ', 'يرجى اختيار المخزن المصدر والوجهة');
      return;
    }
    if (cartItems.isEmpty) {
      Get.snackbar('خطأ', 'يرجى إضافة أصناف للتحويل');
      return;
    }
    if (sourceWarehouse.value!.id == destinationWarehouse.value!.id) {
      Get.snackbar('خطأ', 'لا يمكن التحويل لنفس المخزن');
      return;
    }

    try {
      isSaving(true);

      final items = cartItems.map((ci) => TransferItemInput(
        productId: ci.product.id!,
        productName: ci.product.name,
        quantity: ci.quantity, 
        quantityInBaseUnit: ci.quantityInBaseUnit, // تحويل للوحدة الأساسية للتخزين
        unitId: ci.unitId,
        salePrice: ci.unitSalePrice,
        purchasePrice: ci.unitPurchasePrice,
      )).toList();

      final transferId = await _transferRepo.createTransfer(
        sourceWarehouseId: sourceWarehouse.value!.id!,
        destinationWarehouseId: destinationWarehouse.value!.id!,
        transferDate: DateTime.now(),
        notes: notesController.text.isNotEmpty ? notesController.text : null,
        items: items,
      );

      // تحديث البيانات
      await productController.fetchAllProducts();
      await warehouseController.fetchAllWarehouses();
      await fetchAllTransfers();

      // تنظيف السلة
      _resetCart();
      isSaving(false);

      Get.back();
      Get.snackbar(
        'نجاح',
        'تم تنفيذ سند التحويل رقم #$transferId بنجاح',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      isSaving(false);
      Get.snackbar(
        'فشل التحويل',
        e.toString().replaceAll('Exception: ', ''),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    }
  }

  /// جلب تفاصيل سند
  Future<List<InventoryTransferItemModel>> getTransferItems(int transferId) async {
    return await _transferRepo.getTransferItems(transferId);
  }

  /// جلب سند بالمعرف
  Future<InventoryTransferModel?> getTransferById(int id) async {
    return await _transferRepo.getTransferById(id);
  }

  /// جلب الكمية المتوفرة في المخزن المصدر
  Future<double> getAvailableStock(int productId) async {
    if (sourceWarehouse.value == null) return 0.0;
    return await _warehouseRepo.getProductStockInWarehouse(
      sourceWarehouse.value!.id!,
      productId,
    );
  }

  void _resetCart() {
    cartItems.clear();
    sourceWarehouse.value = null;
    destinationWarehouse.value = null;
    notesController.clear();
  }

  @override
  void onClose() {
    notesController.dispose();
    super.onClose();
  }
}
