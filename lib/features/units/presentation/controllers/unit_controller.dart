import 'package:ehab_company_admin/features/units/data/models/unit_model.dart';
import 'package:ehab_company_admin/features/units/data/repositories/unit_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UnitController extends GetxController {
  final UnitRepository _repository = UnitRepository();

  final RxList<UnitModel> units = <UnitModel>[].obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAllUnits();
  }

  Future<void> fetchAllUnits() async {
    try {
      isLoading(true);
      units.assignAll(await _repository.getAllUnits());
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في جلب الوحدات: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> addNewUnit(String name) async {
    if (name.isEmpty) {
      Get.snackbar('خطأ', 'اسم الوحدة لا يمكن أن يكون فارغًا');
      return;
    }
    try {
      await _repository.addUnit(UnitModel(name: name));
      await fetchAllUnits();
      Get.back();
      Get.snackbar('نجاح', 'تمت إضافة الوحدة بنجاح', backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في إضافة الوحدة: $e', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> removeUnit(int id) async {
    try {
      await _repository.deleteUnit(id);
      units.removeWhere((unit) => unit.id == id);
      Get.snackbar('نجاح', 'تم حذف الوحدة بنجاح', backgroundColor: Colors.blue, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في حذف الوحدة: $e', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
}
