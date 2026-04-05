// File: lib/features/fund/presentation/widgets/add_bank_dialog.dart

import 'package:ehab_company_admin/features/fund/data/models/fund_model.dart';
import 'package:ehab_company_admin/features/fund/presentation/controllers/fund_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddBankDialog extends StatefulWidget {
  final FundModel? fundToEdit;
  const AddBankDialog({super.key, this.fundToEdit});

  @override
  State<AddBankDialog> createState() => _AddBankDialogState();
}

class _AddBankDialogState extends State<AddBankDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _initialBalanceController = TextEditingController(text: '0');
  final FundController controller = Get.find();

  FundType _selectedType = FundType.bank;

  @override
  void initState() {
    super.initState();
    if (widget.fundToEdit != null) {
      _nameController.text = widget.fundToEdit!.name;
      _bankNameController.text = widget.fundToEdit!.bankName ?? '';
      _accountNumberController.text = widget.fundToEdit!.accountNumber ?? '';
      _initialBalanceController.text = widget.fundToEdit!.initialBalance.toString();
      _selectedType = widget.fundToEdit!.fundType;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _initialBalanceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final double initialBalance = double.tryParse(_initialBalanceController.text) ?? 0.0;

      if (widget.fundToEdit != null) {
        // وضع التعديل
        final updatedFund = widget.fundToEdit!.copyWith(
          name: _nameController.text,
          fundType: _selectedType,
          bankName: _selectedType == FundType.bank ? _bankNameController.text : null,
          accountNumber: _selectedType == FundType.bank ? _accountNumberController.text : null,
          initialBalance: initialBalance,
          balance: initialBalance, // Ensure balance is also updated
        );
        controller.updateSubFund(updatedFund);
      } else {
        // وضع الإضافة
        controller.createSubFund(
          name: _nameController.text,
          type: _selectedType,
          bankName: _selectedType == FundType.bank ? _bankNameController.text : null,
          accountNumber: _selectedType == FundType.bank ? _accountNumberController.text : null,
          initialBalance: initialBalance,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.fundToEdit != null ? 'تعديل بيانات الصندوق' : 'إضافة صندوق فرعي'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // اختيار نوع الصندوق
              SegmentedButton<FundType>(
                segments: const [
                  ButtonSegment(value: FundType.bank, label: Text('بنك 🏦')),
                  ButtonSegment(value: FundType.transfer, label: Text('حوالات 📨')),
                ],
                selected: {_selectedType},
                onSelectionChanged: (s) => setState(() => _selectedType = s.first),
              ),
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'اسم الصندوق *', prefixIcon: Icon(Icons.label_outline)),
                validator: (v) => (v == null || v.isEmpty) ? 'الرجاء إدخال الاسم' : null,
              ),
              if (_selectedType == FundType.bank) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bankNameController,
                  decoration: const InputDecoration(labelText: 'اسم البنك', prefixIcon: Icon(Icons.account_balance)),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _accountNumberController,
                  decoration: const InputDecoration(labelText: 'رقم الحساب', prefixIcon: Icon(Icons.numbers)),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _initialBalanceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'الرصيد الافتتاحي', prefixIcon: Icon(Icons.attach_money)),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
        ElevatedButton(onPressed: _submit, child: const Text('إنشاء')),
      ],
    );
  }
}
