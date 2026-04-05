// File: lib/features/categories/presentation/controllers/category_controller.dart

import 'package:ehab_company_admin/features/categories/data/models/category_model.dart';
import 'package:ehab_company_admin/features/categories/data/repositories/category_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ehab_company_admin/features/activities/data/models/activity_model.dart';
import 'package:ehab_company_admin/features/activities/presentation/controllers/activity_controller.dart';

class CategoryController extends GetxController {
  final CategoryRepository _repository = CategoryRepository();
  final ActivityController _activityController = Get.find<ActivityController>();

  final RxList<CategoryModel> categories = <CategoryModel>[].obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAllCategories();
  }

  Future<void> fetchAllCategories() async {
    try {
      isLoading(true);
      final categoryList = await _repository.getAllCategories();
      categories.assignAll(categoryList);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في جلب التصنيفات: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> addNewCategory(String name) async {
    if (name.isEmpty) {
      Get.snackbar('خطأ', 'اسم التصنيف لا يمكن أن يكون فارغًا');
      return;
    }
    final newCategory = CategoryModel(name: name);
    try {
      await _repository.addCategory(newCategory);
      
      // تسجيل النشاط
      await _activityController.logAction(
        action: 'إضافة تصنيف جديد',
        details: 'تم إضافة التصنيف "$name"',
        type: ActivityType.inventory,
      );

      await fetchAllCategories(); // تحديث القائمة
      Get.back(); // إغلاق نافذة الإدخال
      Get.snackbar('نجاح', 'تمت إضافة التصنيف بنجاح', backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في إضافة التصنيف: $e', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> removeCategory(int id) async {
    try {
      final category = categories.firstWhereOrNull((c) => c.id == id);
      await _repository.deleteCategory(id);
      
      // تسجيل النشاط
      await _activityController.logAction(
        action: 'حذف تصنيف',
        details: 'تم حذف التصنيف "${category?.name ?? "غير معروف"}"',
        type: ActivityType.inventory,
      );

      categories.removeWhere((cat) => cat.id == id);
      Get.snackbar('نجاح', 'تم حذف التصنيف بنجاح', backgroundColor: Colors.blue, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في حذف التصنيف: $e', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
}
