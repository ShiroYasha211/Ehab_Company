// File: lib/features/expenses/presentation/screens/add_expense_screen.dart

import 'package:ehab_company_admin/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;

class AddExpenseScreen extends StatelessWidget {
const AddExpenseScreen({super.key});

@override
Widget build(BuildContext context) {
final controller = Get.put(ExpenseController());
final dateController = TextEditingController(
text: intl.DateFormat('yyyy-MM-dd').format(controller.selectedDate.value),
);

return Scaffold(
appBar: AppBar(
title: const Text('تسجيل مصروف جديد'),
),
body: Form(
key: controller.formKey,
child: ListView(
padding: const EdgeInsets.all(20),
children: [
// 1. اختيار بند المصروف
Obx(() => DropdownButtonFormField<int>(
value: controller.selectedCategoryId.value,
items: controller.categories.map((category) {
return DropdownMenuItem<int>(
value: category.id,
child: Text(category.name),
);
}).toList(),
onChanged: (value) {
controller.selectedCategoryId.value = value;
},
decoration: InputDecoration(
labelText: 'اختر بند المصروف *',
prefixIcon: const Icon(Icons.category_outlined),
border: const OutlineInputBorder(),
// لإضافة زر "إضافة بند جديد"
suffixIcon: IconButton(
icon: const Icon(Icons.add_circle_outline),
onPressed: () => _showAddCategoryDialog(context, controller),
tooltip: 'إضافة بند جديد',
),
),
validator: (value) =>
value == null ? 'الرجاء اختيار بند المصروف' : null,
)),
const SizedBox(height: 20),

// 2. المبلغ
TextFormField(
controller: controller.amountController,
keyboardType: const TextInputType.numberWithOptions(decimal: true),
decoration: const InputDecoration(
labelText: 'المبلغ *',
prefixIcon: Icon(Icons.attach_money),
border: OutlineInputBorder(),
),
validator: (value) {
if (value == null || value.isEmpty) {
return 'الرجاء إدخال المبلغ';
}
if (double.tryParse(value) == null || double.parse(value) <= 0) {
return 'الرجاء إدخال مبلغ صحيح أكبر من صفر';
}
return null;
},
),
const SizedBox(height: 16),

// 3. التاريخ
TextFormField(
controller: dateController,
readOnly: true,
onTap: () async {
final DateTime? pickedDate = await showDatePicker(
context: context,
initialDate: controller.selectedDate.value,
firstDate: DateTime(2000),
lastDate: DateTime(2101),
locale: const Locale('ar'),
);
if (pickedDate != null) {
controller.selectedDate.value = pickedDate;
dateController.text =
intl.DateFormat('yyyy-MM-dd').format(pickedDate);
}
},
decoration: const InputDecoration(
labelText: 'تاريخ المصروف',
prefixIcon: Icon(Icons.calendar_today_outlined),
border: OutlineInputBorder(),
),
),
const SizedBox(height: 16),

// 4. خيار الخصم من الصندوق
Obx(() => SwitchListTile(
title: const Text('خصم من الصندوق'),
subtitle: const Text('سيتم خصم مبلغ المصروف من رصيد الصندوق'),
value: controller.deductFromFund.value,
onChanged: (value) {
controller.deductFromFund.value = value;
},
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(8),
side: BorderSide(color: Colors.grey.shade300),
),
)),
const SizedBox(height: 16),

// 5. الملاحظات
TextFormField(
controller: controller.notesController,
maxLines: 3,
decoration: const InputDecoration(
labelText: 'ملاحظات (اختياري)',
alignLabelWithHint: true,
prefixIcon: Icon(Icons.notes_rounded),
border: OutlineInputBorder(),
),
),
const SizedBox(height: 32),

// 6. زر الحفظ
ElevatedButton.icon(
onPressed: controller.addExpense,
icon: const Icon(Icons.save_alt_rounded),
label: const Text('حفظ المصروف'),
style: ElevatedButton.styleFrom(
padding: const EdgeInsets.symmetric(vertical: 16),
),
),
],
),
),
);
}

// ديالوج لإضافة بند مصروف جديد بسرعة
void _showAddCategoryDialog(BuildContext context, ExpenseController controller) {
final categoryNameController = TextEditingController();
Get.dialog(
AlertDialog(
title: const Text('إضافة بند مصروف جديد'),
content: TextField(
controller: categoryNameController,
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
await controller.addCategory(categoryNameController.text);
Get.back();
},
child: const Text('إضافة'),
),
],
),
);
}
}
