// File: lib/features/activities/presentation/widgets/advanced_filter_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/operations_controller.dart';
import '../../data/models/operation_model.dart';

class AdvancedFilterBottomSheet extends StatelessWidget {
  const AdvancedFilterBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OperationsController>();
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('فلترة متقدمة', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => controller.resetFilters(),
                  child: const Text('إعادة ضبط'),
                ),
              ],
            ),
            const Divider(height: 32),

            // 1. التاريخ
            Text('الفترة الزمنية', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDateButton(
                    context, 'من', controller.fromDate, (date) => controller.fromDate.value = date,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateButton(
                    context, 'إلى', controller.toDate, (date) => controller.toDate.value = date,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 2. نوع العملية
            Text('نوع العملية', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: OperationType.values.map((type) {
                return Obx(() {
                  final isSelected = controller.selectedTypes.contains(type);
                  return FilterChip(
                    label: Text(_getTypeLabel(type)),
                    selected: isSelected,
                    onSelected: (_) => controller.toggleType(type),
                    selectedColor: theme.primaryColor.withOpacity(0.2),
                    checkmarkColor: theme.primaryColor,
                  );
                });
              }).toList(),
            ),
            const SizedBox(height: 24),

            // 3. الموظف
            Text('بواسطة الموظف', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Obx(() => DropdownButtonFormField<String>(
              value: controller.selectedEmployee.value.isEmpty ? null : controller.selectedEmployee.value,
              items: [
                const DropdownMenuItem(value: "", child: Text('الكل')),
                ...controller.availableEmployees.map((e) => DropdownMenuItem(value: e, child: Text(e))),
              ],
              onChanged: (val) => controller.selectedEmployee.value = val ?? "",
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
            )),
            const SizedBox(height: 32),

            // زر التطبيق
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  controller.loadOperations();
                  Get.back();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('تطبيق الفلتر', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDateButton(BuildContext context, String label, Rx<DateTime?> dateRx, Function(DateTime) onSelected) {
    return Obx(() => OutlinedButton.icon(
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: dateRx.value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) onSelected(picked);
      },
      icon: const Icon(Icons.calendar_month, size: 18),
      label: Text(dateRx.value == null ? label : DateFormat('yyyy-MM-dd').format(dateRx.value!)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        alignment: Alignment.centerLeft,
      ),
    ));
  }

  String _getTypeLabel(OperationType type) {
    switch (type) {
      case OperationType.sale: return 'بيع';
      case OperationType.purchase: return 'شراء';
      case OperationType.expense: return 'مصروف';
      case OperationType.transfer: return 'تحويل';
      case OperationType.settlement: return 'تسوية';
      case OperationType.returnSale: return 'مرتجع بيع';
      case OperationType.returnPurchase: return 'مرتجع شراء';
    }
  }
}
