// File: lib/features/fund/presentation/widgets/transfer_dialog.dart

import 'package:ehab_company_admin/features/fund/presentation/controllers/fund_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TransferDialog extends StatefulWidget {
  const TransferDialog({super.key});

  @override
  State<TransferDialog> createState() => _TransferDialogState();
}

class _TransferDialogState extends State<TransferDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final FundController controller = Get.find();

  int? _sourceFundId;
  int? _targetFundId;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_sourceFundId == null || _targetFundId == null) {
        Get.snackbar('خطأ', 'الرجاء اختيار الصندوق المصدر والهدف');
        return;
      }
      controller.transferFunds(
        sourceFundId: _sourceFundId!,
        targetFundId: _targetFundId!,
        amount: double.tryParse(_amountController.text) ?? 0.0,
        description: _descriptionController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final funds = controller.subFunds;

    return AlertDialog(
      title: const Text('تحويل بين الصناديق'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'من صندوق *', prefixIcon: Icon(Icons.outbox_outlined)),
                items: funds.map((f) => DropdownMenuItem(value: f.id, child: Text('${f.displayIcon} ${f.name}'))).toList(),
                onChanged: (v) => setState(() => _sourceFundId = v),
                validator: (v) => v == null ? 'اختر الصندوق المصدر' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'إلى صندوق *', prefixIcon: Icon(Icons.move_to_inbox_outlined)),
                items: funds.map((f) => DropdownMenuItem(value: f.id, child: Text('${f.displayIcon} ${f.name}'))).toList(),
                onChanged: (v) => setState(() => _targetFundId = v),
                validator: (v) => v == null ? 'اختر الصندوق الهدف' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'المبلغ *', prefixIcon: Icon(Icons.attach_money)),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'الرجاء إدخال المبلغ';
                  if (double.tryParse(v) == null || double.parse(v) <= 0) return 'مبلغ غير صحيح';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'الوصف *', prefixIcon: Icon(Icons.description_outlined)),
                validator: (v) => (v == null || v.isEmpty) ? 'الرجاء إدخال الوصف' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          child: const Text('تحويل'),
        ),
      ],
    );
  }
}
