import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import '../../../../core/services/auth_service.dart';
import '../../data/models/activity_model.dart';
import '../controllers/activity_controller.dart';

class ActivityFilterDialog extends StatelessWidget {
  const ActivityFilterDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final ActivityController controller = Get.find<ActivityController>();
    final AuthService authService = Get.find<AuthService>();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'فلترة العمليات',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    controller.resetFilters();
                    Get.back();
                  },
                  child: const Text('إعادة تعيين', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),
            
            // القسم 1: الموظف
            const Text('الموظف المسؤول', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Obx(() => DropdownButtonFormField<int?>(
              value: controller.selectedUserId.value,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('جميع الموظفين')),
                ...authService.mockUsers.map((user) => DropdownMenuItem(
                  value: user.id,
                  child: Text(user.name),
                )),
              ],
              onChanged: (val) => controller.selectedUserId.value = val,
            )),
            
            const SizedBox(height: 24),
            
            // القسم 2: نوع العملية
            const Text('نوع العملية', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ActivityType.values.map((type) {
                return Obx(() {
                  final isSelected = controller.selectedType.value == type;
                  return ChoiceChip(
                    label: Text(type.label),
                    selected: isSelected,
                    onSelected: (selected) {
                      controller.selectedType.value = selected ? type : null;
                    },
                    selectedColor: type.color.withOpacity(0.2),
                    checkmarkColor: type.color,
                    labelStyle: TextStyle(
                      color: isSelected ? type.color : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                });
              }).toList(),
            ),
            
            const SizedBox(height: 24),
            
            // القسم 3: الفترة الزمنية
            const Text('الفترة الزمنية', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Obx(() {
              final range = controller.selectedDateRange.value;
              final String rangeText = range == null 
                ? 'اختر الفترة' 
                : '${intl.DateFormat('yyyy/MM/dd').format(range.start)} - ${intl.DateFormat('yyyy/MM/dd').format(range.end)}';
                
              return InkWell(
                onTap: () async {
                  final selected = await showDateRangePicker(
                    context: context,
                    initialDateRange: range,
                    firstDate: DateTime(2023),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: Get.theme.primaryColor,
                            onPrimary: Colors.white,
                            onSurface: Colors.black,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (selected != null) {
                    controller.selectedDateRange.value = selected;
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(rangeText, style: TextStyle(color: range == null ? Colors.grey : Colors.black)),
                      const Icon(Icons.calendar_month_rounded, color: Colors.blue),
                    ],
                  ),
                ),
              );
            }),
            
            const SizedBox(height: 32),
            
            // زر التطبيق
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  controller.loadActivities();
                  Get.back();
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('تطبيق الفلتر', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
