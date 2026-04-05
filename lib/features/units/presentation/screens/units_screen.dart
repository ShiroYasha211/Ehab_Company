import 'package:ehab_company_admin/features/units/data/models/unit_model.dart';
import 'package:ehab_company_admin/features/units/presentation/controllers/unit_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UnitsScreen extends StatelessWidget {
  const UnitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final UnitController controller = Get.put(UnitController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الوحدات'),
      ),
      body: Obx(() {
        if (controller.isLoading.isTrue) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.units.isEmpty) {
          return const Center(
              child: Text('لا توجد وحدات. قم بإضافة وحدة جديدة.',
                  style: TextStyle(color: Colors.grey)));
        }
        return ListView.builder(
          itemCount: controller.units.length,
          itemBuilder: (context, index) {
            final unit = controller.units[index];

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.account_tree_outlined, color: Colors.blue),
                ),
                title: Text('سلسلة: ${unit.name}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  controller.getPackagingChain(unit.id),
                  style: TextStyle(color: Colors.blue.shade700, fontSize: 13),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                      onPressed: () => showUnitDialog(
                        context,
                        controller,
                        unit: unit,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        Get.defaultDialog(
                          title: 'تأكيد الحذف الكلي',
                          titleStyle: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          middleText: 'حذف سلسلة "${unit.name}" سيؤدي لحذف كافة الوحدات التابعة لها أيضاً. هل أنت متأكد؟',
                          textConfirm: 'حذف السلسلة',
                          confirmTextColor: Colors.white,
                          buttonColor: Colors.red,
                          textCancel: 'إلغاء',
                          onConfirm: () {
                            controller.removeUnit(unit.id!);
                            Get.back();
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showUnitDialog(context, controller),
        child: const Icon(Icons.add),
      ),
    );
  }

  static void showUnitDialog(
    BuildContext context,
    UnitController controller, {
    UnitModel? unit,
  }) {
    // جلب مستويات السلسلة إذا كنا في وضع التعديل، أو البدء بسلسلة جديدة
    final RxList<Map<String, dynamic>> chainLevels = unit != null 
        ? controller.getChainList(unit.id!).obs
        : <Map<String, dynamic>>[
            {
              'name': TextEditingController(),
              'factor': TextEditingController(text: '1.0')
            }
          ].obs;

    final theme = Theme.of(context);

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.transparent,
        child: Container(
          width: 500, // تحديد عرض أقصى متناسق
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // رأس الحوار
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Icon(
                      unit == null ? Icons.add_circle_outline : Icons.edit_note,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      unit == null ? 'بناء سلسلة وحدات جديدة' : 'تعديل السلسلة الحالية',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // المحتوى
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'قم بإضافة مستويات التعبئة من الأكبر (كرتون) إلى الأصغر (حبة). النظام سيقوم بربطهم آلياً وبشكل مستقل.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),

                      Obx(() => ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: chainLevels.length,
                            itemBuilder: (context, index) {
                              return Column(
                                children: [
                                  UnitsScreen._buildChainLevelItem(
                                    theme,
                                    index,
                                    chainLevels[index],
                                    onDelete: chainLevels.length > 1
                                        ? () => chainLevels.removeAt(index)
                                        : null,
                                    isLast: index == chainLevels.length - 1,
                                  ),
                                  if (index < chainLevels.length - 1)
                                    UnitsScreen._buildConnectionArrow(theme),
                                ],
                              );
                            },
                          )),

                      const SizedBox(height: 16),
                      // زر إضافة مستوى
                      TextButton.icon(
                        onPressed: () {
                          chainLevels.add({
                            'name': TextEditingController(),
                            'factor': TextEditingController(text: '1.0')
                          });
                        },
                        icon: const Icon(Icons.add_circle, size: 24),
                        label: const Text('إضافة مستوى أصغر (عبوة داخلية)'),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: theme.primaryColor.withOpacity(0.3)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ملخص السلسلة (Summary)
              Obx(() {
                final names = chainLevels
                    .map((l) => (l['name'] as TextEditingController).text)
                    .where((n) => n.isNotEmpty)
                    .toList();
                if (names.length < 2) return const SizedBox.shrink();
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.primaryColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'سلسلة: ${names.join(" ⬅️ ")}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // أزرار التحكم
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            // 1. التحقق من الأسماء قبل الحفظ
                            if (chainLevels.any((l) => (l['name'] as TextEditingController).text.trim().isEmpty)) {
                              Get.snackbar('تنبيه', 'يرجى إدخال أسماء كافة مستويات التعبئة',
                                  backgroundColor: Colors.orange, colorText: Colors.white);
                              return;
                            }
                            
                            // 2. محاولة الحفظ
                            await controller.saveUnitChain(chainLevels, originalRootId: unit?.id);
                          } catch (e) {
                            Get.snackbar('خطأ', 'حدث خطأ غير متوقع: $e',
                                backgroundColor: Colors.red, colorText: Colors.white);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: Text(unit == null ? 'حفظ السلسلة' : 'حفظ التعديلات'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildChainLevelItem(
    ThemeData theme,
    int index,
    Map<String, dynamic> level, {
    VoidCallback? onDelete,
    bool isLast = false,
  }) {
    final nameCtrl = level['name'] as TextEditingController;
    final factorCtrl = level['factor'] as TextEditingController;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // زيادة الـ Padding الرأسي
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      hintText: index == 0 ? 'الوحدة الكبرى (كرتون، طبلية..)' : 'اسم الوحدة (باكت، كيس..)',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8), // زيادة مساحة الضغط
                      isDense: true,
                    ),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                if (onDelete != null)
                  IconButton(
                    icon: Icon(Icons.delete_sweep_outlined, color: Colors.red.shade400, size: 24),
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
          if (!isLast)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50.withOpacity(0.4),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
              ),
              child: Wrap( // استخدام Wrap بدلاً من Row لمنع الـ Overflow
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  const Icon(Icons.subdirectory_arrow_left, size: 18, color: Colors.blue),
                  const Text('يحتوي على عدد', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  SizedBox(
                    width: 70, // زيادة العرض قليلاً
                    child: TextField(
                      controller: factorCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      onTap: () => factorCtrl.selection = TextSelection(baseOffset: 0, extentOffset: factorCtrl.text.length), // Select All
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.primaryColor),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 6),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue, width: 1.5)),
                      ),
                    ),
                  ),
                  const Text(' قطع من الوحدة التالية', style: TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static Widget _buildConnectionArrow(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Icon(Icons.arrow_downward_rounded, size: 20, color: theme.primaryColor.withOpacity(0.4)),
    );
  }
}
