// File: lib/features/customers/presentation/screens/add_customer_payment_screen.dart

import 'package:ehab_company_admin/features/customers/data/models/customer_transaction_model.dart';
import 'package:ehab_company_admin/features/customers/presentation/controllers/add_customer_payment_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddCustomerPaymentScreen extends StatelessWidget {
  const AddCustomerPaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AddCustomerPaymentController());

    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          return Text(controller.selectedType.value == CustomerTransactionType.RECEIPT
              ? 'سند قبض جديد'
              : 'تسجيل رصيد افتتاحي');
        }),
      ),
      body: Form(
        key: controller.formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // اختيار العميل
            Obx(() => DropdownButtonFormField<int>(
              value: controller.selectedCustomerId.value,
              items: controller.customersList.map((customer) {
                return DropdownMenuItem<int>(
                  value: customer.id,
                  child: Text(customer.name),
                );
              }).toList(),
              onChanged: (value) {
                controller.selectedCustomerId.value = value;
              },
              decoration: const InputDecoration(
                labelText: 'اختر العميل *',
                prefixIcon: Icon(Icons.person_search_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null ? 'الرجاء اختيار عميل' : null,
            )),
            const SizedBox(height: 20),

            // نوع الحركة
            Obx(() => SegmentedButton<CustomerTransactionType>(
              segments: const [
                ButtonSegment(
                    value: CustomerTransactionType.RECEIPT,
                    label: Text('سند قبض'),
                    icon: Icon(Icons.call_received)),
                ButtonSegment(
                    value: CustomerTransactionType.OPENING_BALANCE,
                    label: Text('رصيد افتتاحي'),
                    icon: Icon(Icons.play_for_work)),
              ],
              selected: {controller.selectedType.value},
              onSelectionChanged: (newSelection) {
                controller.selectedType.value = newSelection.first;
              },
            )),
            const SizedBox(height: 20),

            // المبلغ
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
                if (double.tryParse(value) == null) {
                  return 'الرجاء إدخال رقم صحيح';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // التاريخ
            TextFormField(
              controller: controller.dateController,
              readOnly: true,
              onTap: () => controller.selectDateTime(context),
              decoration: const InputDecoration(
                labelText: 'التاريخ',
                prefixIcon: Icon(Icons.calendar_today_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // خيار الصندوق
            Obx(() => SwitchListTile(
              title: const Text('تأثير على الصندوق'),
              subtitle: Text(controller.selectedType.value == CustomerTransactionType.RECEIPT
                  ? 'سيتم إيداع المبلغ في الصندوق'
                  : 'لن يتم إضافة أو خصم أي مبلغ من الصندوق'),
              value: controller.affectsFund.value,
              onChanged: controller.selectedType.value == CustomerTransactionType.OPENING_BALANCE
                  ? null // تعطيل الخيار في حالة الرصيد الافتتاحي
                  : (value) {
                controller.affectsFund.value = value;
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade300),
              ),
            )),
            const SizedBox(height: 16),

            // الملاحظات
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

            // زر الحفظ
            ElevatedButton.icon(
              onPressed: controller.submit,
              icon: const Icon(Icons.save_alt_rounded),
              label: const Text('حفظ الحركة'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
