// File: lib/features/categories/presentation/screens/categories_screen.dart

import 'package:ehab_company_admin/features/categories/presentation/controllers/category_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CategoryController controller = Get.put(CategoryController());
    final TextEditingController newCategoryController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة التصنيفات'),
      ),
      body: Obx(() {
        if (controller.isLoading.isTrue) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.categories.isEmpty) {
          return const Center(child: Text('لا توجد تصنيفات. قم بإضافة تصنيف جديد.', style: TextStyle(color: Colors.grey)));
        }
        return ListView.builder(
          itemCount: controller.categories.length,
          itemBuilder: (context, index) {
            final category = controller.categories[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.category_outlined),
                title: Text(category.name),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    Get.defaultDialog(
                      title: 'تأكيد الحذف',
                      middleText: 'هل أنت متأكد من حذف تصنيف "${category.name}"؟',
                      textConfirm: 'حذف',
                      textCancel: 'إلغاء',
                      onConfirm: () {
                        controller.removeCategory(category.id!);
                        Get.back();
                      },
                    );
                  },
                ),
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.defaultDialog(
            title: 'إضافة تصنيف جديد',
            content: TextField(
              controller: newCategoryController,
              decoration: const InputDecoration(labelText: 'اسم التصنيف'),
              autofocus: true,
            ),
            textConfirm: 'إضافة',
            textCancel: 'إلغاء',
            onConfirm: () {
              controller.addNewCategory(newCategoryController.text);
              newCategoryController.clear();
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
