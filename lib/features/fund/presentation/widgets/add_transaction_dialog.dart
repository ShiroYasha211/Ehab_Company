// File: lib/features/fund/presentation/widgets/add_transaction_dialog.dart

import 'package:ehab_company_admin/features/fund/presentation/controllers/fund_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl; // <-- إضافة جديدة لمعالجة التاريخ

class AddTransactionDialog extends StatefulWidget {
  final bool isDeposit; // true للإيداع, false للسحب

  const AddTransactionDialog({super.key, required this.isDeposit});

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final FundController _fundController = Get.find();

  // --- بداية الإضافة: متغيرات التاريخ ---
  late DateTime _selectedDate;
  final _dateController = TextEditingController();
  // --- نهاية الإضافة ---

  @override
  void initState() {
    super.initState();
    // --- بداية الإضافة: تهيئة التاريخ الحالي ---
    _selectedDate = DateTime.now();
    _dateController.text =
        intl.DateFormat('yyyy-MM-dd – hh:mm a', 'ar').format(_selectedDate);
    // --- نهاية الإضافة ---
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _dateController.dispose(); // <-- إضافة جديدة
    super.dispose();
  }

  /// دالة لفتح نافذة اختيار التاريخ والوقت
  Future<void> _selectDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      locale: const Locale('ar'),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          _dateController.text =
              intl.DateFormat('yyyy-MM-dd – hh:mm a', 'ar').format(_selectedDate);
        });
      }
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final double amount = double.tryParse(_amountController.text) ?? 0.0;
      final String description = _descriptionController.text;

      if (widget.isDeposit) {
        _fundController.makeDeposit(
          amount: amount,
          description: description,

          transactionDate: _selectedDate, // <-- تمرير التاريخ
        );
      } else {
        _fundController.makeWithdrawal(
          amount: amount,
          description: description,
          transactionDate: _selectedDate, // <-- تمرير التاريخ
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.isDeposit ? 'إضافة توريد نقدي' : 'إضافة صرف نقدي';
    final String buttonText = widget.isDeposit ? 'إيداع' : 'سحب';

    return AlertDialog(
      title: Text(title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'المبلغ *',
                prefixIcon: Icon(Icons.attach_money),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'الرجاء إدخال المبلغ';
                }
                if (double.tryParse(value) == null || double.parse(value) <= 0) {
                  return 'الرجاء إدخال مبلغ صحيح';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'البيان (الوصف) *',
                prefixIcon: Icon(Icons.description_outlined),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'الرجاء إدخال البيان';
                }
                return null;
              },
            ),
            // --- بداية الإضافة: حقل التاريخ ---
            const SizedBox(height: 16),
            TextFormField(
              controller: _dateController,
              readOnly: true,
              onTap: _selectDateTime,
              decoration: const InputDecoration(
                labelText: 'تاريخ العملية',
                prefixIcon: Icon(Icons.calendar_today_outlined),
              ),
            ),
            // --- نهاية الإضافة ---
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(buttonText),
        ),
      ],
    );
  }
}
