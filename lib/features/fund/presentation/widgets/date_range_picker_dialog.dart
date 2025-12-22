// File: lib/features/fund/presentation/widgets/date_range_picker_dialog.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;

class DateRangePickerDialog extends StatefulWidget {
  final Function(DateTime from, DateTime to) onConfirm;

  const DateRangePickerDialog({super.key, required this.onConfirm});

  @override
  State<DateRangePickerDialog> createState() => _DateRangePickerDialogState();
}

class _DateRangePickerDialogState extends State<DateRangePickerDialog> {
  late DateTime fromDate;
  late DateTime toDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Set default range to the current month
    fromDate = DateTime(now.year, now.month, 1);
    toDate = DateTime(now.year, now.month + 1, 0); // Last day of the current month
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate ? fromDate : toDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      locale: const Locale('ar'),
    );
    if (picked != null) {
      setState(() {
        if (isFromDate) {
          fromDate = picked;
        } else {
          toDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تحديد فترة التقرير'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDateField(context, 'من تاريخ', fromDate, true),
          const SizedBox(height: 16),
          _buildDateField(context, 'إلى تاريخ', toDate, false),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () {
            Get.back(); // Close the dialog
            widget.onConfirm(fromDate, toDate); // Execute the callback
          },
          child: const Text('إنشاء التقرير'),
        ),
      ],
    );
  }

  Widget _buildDateField(BuildContext context, String label, DateTime date, bool isFrom) {
    return TextField(
      readOnly: true,
      controller: TextEditingController(
        text: intl.DateFormat('yyyy-MM-dd', 'ar').format(date),
      ),
      onTap: () => _selectDate(context, isFrom),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.calendar_today_outlined),
        border: const OutlineInputBorder(),
      ),
    );
  }
}
