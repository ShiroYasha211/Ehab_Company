// File: lib/features/expenses/presentation/screens/manage_expense_categories_screen.dart

import 'package:ehab_company_admin/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/expense_category_model.dart';

class ManageExpenseCategoriesScreen extends StatelessWidget {
  const ManageExpenseCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ExpenseController controller = Get.find<ExpenseController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة بنود المصروفات'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(context, controller),
        child: const Icon(Icons.add),
        tooltip: 'إضافة بند جديد',
      ),
      body: Obx(() {
        if (controller.isLoading.isTrue && controller.categories.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.categories.isEmpty) {
          return const Center(
            child: Text(
              'لم يتم إضافة أي بنود مصروفات بعد.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }
        return ListView.builder(
          itemCount: controller.categories.length,
          itemBuilder: (context, index) {
            final category = controller.categories[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: ListTile(
                title: Text(category.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit_outlined,
                          color: Theme
                              .of(context)
                              .primaryColor),
                      onPressed: () =>
                          _showCategoryDialog(
                              context, controller, category: category),
                      tooltip: 'تعديل',
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_forever_outlined, color: Theme
                          .of(context)
                          .colorScheme
                          .error),
                      onPressed: () {
                        Get.defaultDialog(
                          title: 'تأكيد الحذف',
                          middleText: 'هل أنت متأكد من حذف بند "${category
                              .name}"؟\nلا يمكن حذف البند إذا كان مستخدمًا.',
                          onConfirm: () {
                            controller.deleteCategory(category.id!);
                            Get.back();
                          },

                          textConfirm: 'حذف',
                          textCancel: 'إلغاء',
                        );
                      },

                      tooltip: 'حذف',
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  /// ديالوج لإضافة أو تعديل بند مصروف
  void _showCategoryDialog(BuildContext context, ExpenseController controller,
      {ExpenseCategoryModel? category}) {
    final bool isEditMode = category != null;
    final nameController = TextEditingController(
        text: isEditMode ? category.name : '');

    Get.dialog(
      AlertDialog(
        title: Text(isEditMode ? 'تعديل بند' : 'إضافة بند جديد'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'اسم البند'),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (isEditMode) {
                await controller.updateCategory(
                    category.id!, nameController.text);
              } else {
                await controller.addCategory(nameController.text);
              }
              Get.back();
            },
            child: Text(isEditMode ? 'حفظ التعديل' : 'إضافة'),
          ),
        ],
      ),
    );
  }
}
