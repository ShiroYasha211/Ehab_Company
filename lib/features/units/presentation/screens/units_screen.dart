import 'package:ehab_company_admin/features/units/presentation/controllers/unit_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UnitsScreen extends StatelessWidget {
  const UnitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final UnitController controller = Get.put(UnitController());
    final TextEditingController newUnitController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الوحدات'),
      ),
      body: Obx(() {
        if (controller.isLoading.isTrue) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.units.isEmpty) {
          return const Center(child: Text('لا توجد وحدات. قم بإضافة وحدة جديدة.', style: TextStyle(color: Colors.grey)));
        }
        return ListView.builder(
          itemCount: controller.units.length,
          itemBuilder: (context, index) {
            final unit = controller.units[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.category_outlined),
                title: Text(unit.name),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    Get.defaultDialog(
                      title: 'تأكيد الحذف',
                      middleText: 'هل أنت متأكد من حذف وحدة "${unit.name}"؟',
                      textConfirm: 'حذف',
                      textCancel: 'إلغاء',
                      onConfirm: () {
                        controller.removeUnit(unit.id!);
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
            title: 'إضافة وحدة جديدة',
            content: TextField(
              controller: newUnitController,
              decoration: const InputDecoration(labelText: 'اسم الوحدة (مثال: حبة، كرتون)'),
              autofocus: true,
            ),
            textConfirm: 'إضافة',
            textCancel: 'إلغاء',
            onConfirm: () {
              controller.addNewUnit(newUnitController.text);
              newUnitController.clear();
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
