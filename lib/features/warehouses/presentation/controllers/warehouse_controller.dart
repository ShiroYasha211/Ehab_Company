// File: lib/features/warehouses/presentation/controllers/warehouse_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/warehouse_model.dart';
import '../../data/repositories/warehouse_repository.dart';

class WarehouseController extends GetxController {
  final WarehouseRepository _repository = WarehouseRepository();

  final RxList<WarehouseModel> warehouses = <WarehouseModel>[].obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAllWarehouses();
  }

  Future<void> fetchAllWarehouses() async {
    try {
      isLoading(true);
      final list = await _repository.getAllWarehouses();
      warehouses.assignAll(list);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في جلب المخازن: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading(false);
    }
  }

  /// جلب المخازن النشطة فقط
  List<WarehouseModel> get activeWarehouses =>
      warehouses.where((w) => w.isActive).toList();

  /// جلب المخازن الفرعية (المندوبين) فقط
  List<WarehouseModel> get repWarehouses =>
      warehouses.where((w) => w.isRep).toList();

  /// جلب المخزن الرئيسي
  WarehouseModel? get mainWarehouse =>
      warehouses.firstWhereOrNull((w) => w.isMain);

  /// إضافة مخزن جديد
  Future<void> addWarehouse({
    required String name,
    String type = 'rep',
    String? salesRepName,
    String? salesRepPhone,
    double creditLimit = 0.0,
  }) async {
    try {
      final warehouse = WarehouseModel(
        name: name,
        type: type,
        salesRepName: salesRepName,
        salesRepPhone: salesRepPhone,
        creditLimit: creditLimit,
        createdAt: DateTime.now(),
      );
      await _repository.addWarehouse(warehouse);
      await fetchAllWarehouses();
      Get.back();
      Get.snackbar('نجاح', 'تم إنشاء المخزن بنجاح',
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في إنشاء المخزن: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  /// تعديل مخزن
  Future<void> updateWarehouse(WarehouseModel warehouse) async {
    try {
      await _repository.updateWarehouse(warehouse);
      await fetchAllWarehouses();
      Get.back();
      Get.snackbar('نجاح', 'تم تحديث المخزن بنجاح',
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في تحديث المخزن: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  /// حذف مخزن فرعي
  Future<void> deleteWarehouse(int id) async {
    try {
      await _repository.deleteWarehouse(id);
      await fetchAllWarehouses();
      Get.snackbar('نجاح', 'تم حذف المخزن بنجاح',
          backgroundColor: Colors.blue, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('خطأ', e.toString().replaceAll('Exception: ', ''),
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  /// جلب تقرير قيمة مخزن
  Future<Map<String, dynamic>> getWarehouseReport(int warehouseId) async {
    return await _repository.getWarehouseValueReport(warehouseId);
  }

  /// جلب أرصدة مخزن
  Future<List<Map<String, dynamic>>> getWarehouseStock(int warehouseId) async {
    return await _repository.getWarehouseStock(warehouseId);
  }
}
