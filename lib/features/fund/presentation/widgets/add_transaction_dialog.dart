// File: lib/features/fund/presentation/widgets/add_transaction_dialog.dart

import 'package:ehab_company_admin/features/fund/data/models/fund_model.dart';
import 'package:ehab_company_admin/features/fund/presentation/controllers/fund_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;

class AddTransactionDialog extends StatefulWidget {
  final bool isDeposit;
  final int fundId;
  final FundType fundType;

  const AddTransactionDialog({
    super.key,
    required this.isDeposit,
    required this.fundId,
    this.fundType = FundType.cash,
  });

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();
  final _transferCompanyController = TextEditingController();
  final _senderNameController = TextEditingController();
  final _receiverNameController = TextEditingController();
  final _transferNumberController = TextEditingController();
  final FundController _fundController = Get.find();
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _dateController.text = intl.DateFormat('yyyy-MM-dd – hh:mm a', 'ar').format(_selectedDate);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _transferCompanyController.dispose();
    _senderNameController.dispose();
    _receiverNameController.dispose();
    _transferNumberController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      locale: const Locale('ar'),
    );
    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );
      if (pickedTime != null) {
        setState(() {
          _selectedDate = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
          _dateController.text = intl.DateFormat('yyyy-MM-dd – hh:mm a', 'ar').format(_selectedDate);
        });
      }
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      final description = _descriptionController.text;

      if (widget.isDeposit) {
        _fundController.makeDeposit(
          fundId: widget.fundId,
          amount: amount,
          description: description,
          transactionDate: _selectedDate,
          transferCompany: _transferCompanyController.text.isNotEmpty ? _transferCompanyController.text : null,
          senderName: _senderNameController.text.isNotEmpty ? _senderNameController.text : null,
          receiverName: _receiverNameController.text.isNotEmpty ? _receiverNameController.text : null,
          transferNumber: _transferNumberController.text.isNotEmpty ? _transferNumberController.text : null,
          referenceType: widget.fundType == FundType.transfer ? 'HAWALA' : null,
        );
      } else {
        _fundController.makeWithdrawal(
          fundId: widget.fundId,
          amount: amount,
          description: description,
          transactionDate: _selectedDate,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isDeposit ? 'إضافة إيداع' : 'إضافة سحب';
    final buttonText = widget.isDeposit ? 'إيداع' : 'سحب';
    final showTransferFields = widget.fundType == FundType.transfer;

    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                decoration: const InputDecoration(labelText: 'البيان (الوصف) *', prefixIcon: Icon(Icons.description_outlined)),
                validator: (v) => (v == null || v.isEmpty) ? 'الرجاء إدخال البيان' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dateController,
                readOnly: true,
                onTap: _selectDateTime,
                decoration: const InputDecoration(labelText: 'تاريخ العملية', prefixIcon: Icon(Icons.calendar_today_outlined)),
              ),
              if (showTransferFields) ...[
                const SizedBox(height: 16),
                const Divider(),
                const Text('تفاصيل الحوالة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _transferNumberController,
                  decoration: const InputDecoration(labelText: 'رقم الحوالة', prefixIcon: Icon(Icons.tag)),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _senderNameController,
                  decoration: const InputDecoration(labelText: 'اسم المُرسل', prefixIcon: Icon(Icons.person_outline)),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _receiverNameController,
                  decoration: const InputDecoration(labelText: 'اسم المُستلم', prefixIcon: Icon(Icons.person)),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _transferCompanyController,
                  decoration: const InputDecoration(labelText: 'شركة التحويل', prefixIcon: Icon(Icons.business)),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
        ElevatedButton(onPressed: _submit, child: Text(buttonText)),
      ],
    );
  }
}
