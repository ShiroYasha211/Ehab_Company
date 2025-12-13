// File: lib/features/suppliers/presentation/screens/add_supplier_payment_screen.dart

import 'package:ehab_company_admin/features/suppliers/data/models/supplier_transaction_model.dart';
import 'package:ehab_company_admin/features/suppliers/presentation/controllers/add_payment_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddSupplierPaymentScreen extends StatelessWidget {
  const AddSupplierPaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use Get.put to create and find the controller
    final AddPaymentController controller = Get.put(AddPaymentController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل حركة مالية لمورد'),
      ),
      body: Form(
        key: controller.formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // 1. اختيار المورد
            Obx(() {
              // --- بداية التعديل: التحقق من القائمة قبل العرض ---
              if (controller.suppliersList.isEmpty) {
                // إذا كانت القائمة فارغة، اعرض مؤشر تحميل أو رسالة
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Center(child: Text("جاري تحميل قائمة الموردين...")),
                );
              }
              // --- نهاية التعديل ---

              return DropdownButtonFormField<int>(
                value: controller.selectedSupplierId.value,
                items: controller.suppliersList.map((supplier) {
                  return DropdownMenuItem<int>(
                    value: supplier.id,
                    child: Text(supplier.name),
                  );
                }).toList(),
                onChanged: (value) {
                  controller.selectedSupplierId.value = value;
                },
                decoration: const InputDecoration(
                  labelText: 'اختر المورد *',
                  prefixIcon: Icon(Icons.person_search),
                ),
                validator: (value) =>
                value == null ? 'الرجاء اختيار مورد' : null,
              );
            }),
            const SizedBox(height: 20),

            // 2. نوع الحركة
            Obx(() => SegmentedButton<SupplierTransactionType>(
              segments: const [
                ButtonSegment(
                    value: SupplierTransactionType.PAYMENT,
                    label: Text('دفعة نقدية'),
                    icon: Icon(Icons.arrow_upward)),
                ButtonSegment(
                    value: SupplierTransactionType.OPENING_BALANCE,
                    label: Text('رصيد افتتاحي'),
                    icon: Icon(Icons.play_for_work)),
              ],
              selected: {controller.selectedType.value},
              onSelectionChanged: (newSelection) {
                controller.selectedType.value = newSelection.first;
              },
            )),
            const SizedBox(height: 20),

            // 3. المبلغ
            TextFormField(
              controller: controller.amountController,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'المبلغ *',
                  prefixIcon: Icon(Icons.attach_money)),
              validator: (value) {
                if (value == null ||
                    value.isEmpty ||
                    (double.tryParse(value) ?? 0) <= 0) {
                  return 'الرجاء إدخال مبلغ صحيح';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 4. التاريخ والوقت
            TextFormField(
              controller: controller.dateController,
              readOnly: true,
              onTap: () => controller.selectDateTime(context),
              decoration: const InputDecoration(
                  labelText: 'تاريخ العملية',
                  prefixIcon: Icon(Icons.calendar_today_outlined)),
            ),
            const SizedBox(height: 16),

            // 5. الملاحظات
            TextFormField(
              controller: controller.notesController,
              decoration: const InputDecoration(
                  labelText: 'البيان (ملاحظات)',
                  prefixIcon: Icon(Icons.notes)),
            ),
            const SizedBox(height: 16),

            // 6. خيار الخصم من الصندوق
            Obx(() {
              if (controller.selectedType.value ==
                  SupplierTransactionType.PAYMENT) {
                return SwitchListTile(
                  title: const Text('خصم المبلغ من الصندوق'),
                  subtitle:
                  const Text('هل تريد تسجيل هذه العملية كسحب نقدي؟'),
                  value: controller.affectsFund.value,
                  onChanged: (value) {
                    controller.affectsFund.value = value;
                  },
                  secondary:
                  const Icon(Icons.account_balance_wallet_outlined),
                );
              }
              return const SizedBox.shrink(); // Hide if not a payment
            }),
            const SizedBox(height: 32),

            // 7. زر الحفظ
            ElevatedButton.icon(
              onPressed: controller.submit,
              icon: const Icon(Icons.save_alt_outlined),
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
