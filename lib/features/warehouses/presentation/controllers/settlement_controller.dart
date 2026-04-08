import 'package:ehab_company_admin/features/units/data/models/unit_model.dart';
import 'package:ehab_company_admin/features/units/presentation/controllers/unit_controller.dart';
import 'package:ehab_company_admin/features/warehouses/data/models/custody_model.dart';
import 'package:ehab_company_admin/features/warehouses/data/models/warehouse_model.dart';
import 'package:ehab_company_admin/features/warehouses/data/repositories/custody_repository.dart';
import 'package:ehab_company_admin/features/warehouses/presentation/controllers/warehouse_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettlementController extends GetxController {
  final CustodyRepository _repository = CustodyRepository();
  final WarehouseController _warehouseController =
      Get.find<WarehouseController>();
  final UnitController _unitController = Get.find<UnitController>();

  final Rx<WarehouseModel?> selectedWarehouse = Rx<WarehouseModel?>(null);
  final RxList<CustodyProductSummary> currentProducts =
      <CustodyProductSummary>[].obs;
  final RxMap<int, List<CustodyLayerModel>> productLayers =
      <int, List<CustodyLayerModel>>{}.obs;
  final RxMap<int, Map<String, dynamic>> entryData =
      <int, Map<String, dynamic>>{}.obs;

  final RxBool isLoading = false.obs;
  final RxString paymentMethod = 'cash'.obs;
  final RxnInt selectedFundId = RxnInt();

  Future<void> selectWarehouse(WarehouseModel warehouse) async {
    selectedWarehouse.value = warehouse;
    await fetchCurrentCustody();
  }

  Future<void> fetchCurrentCustody() async {
    final warehouse = selectedWarehouse.value;
    if (warehouse == null) return;

    try {
      isLoading(true);
      final products = await _repository.getCurrentCustodyProducts(
        warehouse.id!,
      );
      final allLayers = await _repository.getCurrentCustodyLayers(
        warehouse.id!,
      );

      currentProducts.assignAll(products);
      productLayers.clear();
      for (final layer in allLayers) {
        productLayers.putIfAbsent(layer.productId, () => <CustodyLayerModel>[]);
        productLayers[layer.productId]!.add(layer);
      }

      entryData.clear();
      for (final product in products) {
        entryData[product.productId] = {
          'sold': 0.0,
          'returned': 0.0,
          'soldUnitId': product.unitId,
          'returnedUnitId': product.unitId,
        };
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في تحميل عهدة المندوب: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading(false);
    }
  }

  void updateEntry(int productId, {double? sold, double? returned}) {
    if (!entryData.containsKey(productId)) return;
    final item = entryData[productId]!;
    if (sold != null) item['sold'] = sold;
    if (returned != null) item['returned'] = returned;
    entryData.refresh();
  }

  void updateEntryUnit(int productId, {int? soldUnitId, int? returnedUnitId}) {
    if (!entryData.containsKey(productId)) return;
    final item = entryData[productId]!;
    if (soldUnitId != null) item['soldUnitId'] = soldUnitId;
    if (returnedUnitId != null) item['returnedUnitId'] = returnedUnitId;
    entryData.refresh();
  }

  CustodyProductSummary? getProductSummary(int productId) {
    return currentProducts.firstWhereOrNull((p) => p.productId == productId);
  }

  double getCurrentQty(int productId) {
    return getProductSummary(productId)?.quantity ?? 0.0;
  }

  double getSoldQty(int productId) {
    return (entryData[productId]?['sold'] as double?) ?? 0.0;
  }

  double getReturnedQty(int productId) {
    return (entryData[productId]?['returned'] as double?) ?? 0.0;
  }

  int? getSoldUnitId(int productId) {
    return entryData[productId]?['soldUnitId'] as int?;
  }

  int? getReturnedUnitId(int productId) {
    return entryData[productId]?['returnedUnitId'] as int?;
  }

  double _calculateConversionFactor(int? rootUnitId, int? targetUnitId) {
    if (rootUnitId == null || targetUnitId == null) return 1.0;
    if (rootUnitId == targetUnitId) return 1.0;

    double factor = 1.0;
    int? currentId = rootUnitId;

    while (currentId != null && currentId != targetUnitId) {
      final unit = _unitController.allUnits.firstWhereOrNull(
        (u) => u.id == currentId,
      );
      if (unit == null) return 1.0;
      factor *= unit.conversionFactor;
      currentId = unit.childUnitId;
    }

    return currentId == targetUnitId ? factor : 1.0;
  }

  double _convertToBaseQty({
    required int productId,
    required double quantity,
    required int? selectedUnitId,
  }) {
    final product = getProductSummary(productId);
    if (product == null || quantity <= 0) return quantity;
    final factor = _calculateConversionFactor(product.unitId, selectedUnitId);
    return quantity / (factor > 0 ? factor : 1.0);
  }

  double getSoldQtyInBase(int productId) {
    return _convertToBaseQty(
      productId: productId,
      quantity: getSoldQty(productId),
      selectedUnitId: getSoldUnitId(productId),
    );
  }

  double getReturnedQtyInBase(int productId) {
    return _convertToBaseQty(
      productId: productId,
      quantity: getReturnedQty(productId),
      selectedUnitId: getReturnedUnitId(productId),
    );
  }

  double getRemainingQty(int productId) {
    return getCurrentQty(productId) -
        getSoldQtyInBase(productId) -
        getReturnedQtyInBase(productId);
  }

  bool isItemValid(int productId) {
    final soldRaw = getSoldQty(productId);
    final returnedRaw = getReturnedQty(productId);
    final sold = getSoldQtyInBase(productId);
    final returned = getReturnedQtyInBase(productId);

    if (soldRaw < 0 || returnedRaw < 0 || sold < 0 || returned < 0) {
      return false;
    }

    return (sold + returned) <= (getCurrentQty(productId) + 0.0001);
  }

  double getItemSoldValue(int productId) {
    final layers = productLayers[productId] ?? const <CustodyLayerModel>[];
    double remainingSold = getSoldQtyInBase(productId);
    double total = 0.0;

    for (final layer in layers) {
      if (remainingSold <= 0.0001) break;
      final layerSold = remainingSold > layer.remainingQty
          ? layer.remainingQty
          : remainingSold;
      total += layerSold * layer.salePricePerBaseUnit;
      remainingSold -= layerSold;
    }

    return total;
  }

  String getProductPricingHint(int productId) {
    final layers = productLayers[productId] ?? const <CustodyLayerModel>[];
    if (layers.isEmpty) return '';
    final prices = layers
        .map((layer) => layer.salePricePerBaseUnit.toStringAsFixed(2))
        .toSet()
        .toList();
    if (prices.length == 1) {
      return 'سعر العهدة: ${prices.first}';
    }
    return 'أسعار متعددة حسب دفعات التسليم';
  }

  List<UnitModel> getAllowedUnits(int productId) {
    final product = getProductSummary(productId);
    if (product?.unitId == null) return const <UnitModel>[];

    final levels = _unitController.getUnitLevels(product!.unitId!);
    final allowedIds = <int>{product.unitId!, ...?product.allowedUnitIds};
    return levels.where((unit) => allowedIds.contains(unit.id)).toList();
  }

  String formatQuantityInSelectedUnit(
    int productId,
    double baseQty,
    int? unitId,
  ) {
    final product = getProductSummary(productId);
    if (product == null || unitId == null) {
      return baseQty.toStringAsFixed(2);
    }

    final factor = _calculateConversionFactor(product.unitId, unitId);
    final converted = baseQty * (factor > 0 ? factor : 1.0);
    final value = converted == converted.toInt()
        ? converted.toInt().toString()
        : converted.toStringAsFixed(2);
    return '$value ${_unitController.getUnitName(unitId)}';
  }

  bool get areAllItemsValid {
    for (final product in currentProducts) {
      if (!isItemValid(product.productId)) return false;
    }
    return true;
  }

  double get totalSoldValue {
    return currentProducts.fold<double>(
      0.0,
      (sum, item) => sum + getItemSoldValue(item.productId),
    );
  }

  double get totalReturnedQty {
    return currentProducts.fold<double>(
      0.0,
      (sum, item) => sum + getReturnedQtyInBase(item.productId),
    );
  }

  double get totalRemainingQty {
    return currentProducts.fold<double>(
      0.0,
      (sum, item) => sum + getRemainingQty(item.productId),
    );
  }

  Future<void> submitSettlement({
    required double receivedAmount,
    String? notes,
  }) async {
    final warehouse = selectedWarehouse.value;
    if (warehouse == null) return;

    if (!areAllItemsValid) {
      Get.snackbar(
        'خطأ',
        'يوجد صنف بكمية غير صحيحة داخل التسوية.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (receivedAmount < 0) {
      Get.snackbar(
        'خطأ',
        'لا يمكن إدخال مبلغ مستلم سالب.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (receivedAmount > 0 && selectedFundId.value == null) {
      Get.snackbar(
        'خطأ',
        'اختر الصندوق أو الحساب المالي قبل اعتماد التسوية.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final items = currentProducts
        .map(
          (product) => CustodySettlementInput(
            productId: product.productId,
            soldQty: getSoldQtyInBase(product.productId),
            returnedQty: getReturnedQtyInBase(product.productId),
          ),
        )
        .where((item) => item.soldQty > 0.0001 || item.returnedQty > 0.0001)
        .toList();

    if (items.isEmpty && receivedAmount <= 0) {
      Get.snackbar(
        'خطأ',
        'لا توجد أي حركة لإرسالها في هذه التسوية.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading(true);
      final result = await _repository.processManualSettlement(
        warehouseId: warehouse.id!,
        items: items,
        receivedAmount: receivedAmount,
        paymentMethod: receivedAmount > 0 ? paymentMethod.value : null,
        fundId: receivedAmount > 0 ? selectedFundId.value : null,
        notes: notes,
      );

      await _warehouseController.fetchAllWarehouses();
      final refreshed = _warehouseController.warehouses.firstWhereOrNull(
        (element) => element.id == warehouse.id,
      );
      if (refreshed != null) {
        selectedWarehouse.value = refreshed;
      }
      await fetchCurrentCustody();

      Get.back();
      Get.snackbar(
        'نجاح',
        'تم اعتماد التسوية. فرق التسوية: ${result.settlementDifference.toStringAsFixed(2)}',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل تنفيذ التسوية: ${e.toString().replaceAll('Exception: ', '')}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading(false);
    }
  }
}
