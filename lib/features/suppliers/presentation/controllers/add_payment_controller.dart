// File: lib/features/suppliers/presentation/controllers/add_payment_controller.dart

import 'package:ehab_company_admin/features/suppliers/data/models/supplier_model.dart';
import 'package:ehab_company_admin/features/suppliers/data/models/supplier_transaction_model.dart';
import 'package:ehab_company_admin/features/suppliers/presentation/controllers/supplier_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;


class AddPaymentController extends GetxController {
  final SupplierController _mainSupplierController = Get.find<SupplierController>();

  // State variables managed by GetX
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final Rx<int?> selectedSupplierId = Rx<int?>(null);
  final Rx<SupplierModel?> selectedSupplier = Rx<SupplierModel?>(null);
  final Rx<SupplierTransactionType> selectedType = Rx<SupplierTransactionType>(SupplierTransactionType.PAYMENT);
  final Rx<DateTime> selectedDate = Rx<DateTime>(DateTime.now());
  final RxBool affectsFund = true.obs;

  // Text Editing Controllers
  final TextEditingController amountController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController dateController = TextEditingController();

  // Getter to simplify access in the UI
  RxList<SupplierModel> get suppliersList => _mainSupplierController.filteredSuppliers;
  @override
  void onInit() {
    super.onInit();
    if (_mainSupplierController.suppliers.isEmpty) {
      _mainSupplierController.fetchAllSuppliers();
    }
    // Initialize date text
    dateController.text = intl.DateFormat('yyyy-MM-dd – hh:mm a', 'ar').format(selectedDate.value);

    // Listen to changes in the transaction type
    ever(selectedType, (type) {
      if (type == SupplierTransactionType.OPENING_BALANCE) {
        affectsFund.value = false;
      } else {
        affectsFund.value = true;
      }
    });
  }

  Future<void> selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate.value,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      locale: const Locale('ar'),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedDate.value),
      );
      if (pickedTime != null) {
        selectedDate.value = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        dateController.text = intl.DateFormat('yyyy-MM-dd – hh:mm a', 'ar').format(selectedDate.value);
      }
    }
  }

  void submit() async { // <-- 1. تحويل الدالة إلى async
    if (formKey.currentState!.validate()) {
      final supplier = suppliersList.firstWhere((s) => s.id == selectedSupplierId.value);

      // 2. استدعاء الدالة وانتظار النتيجة
      await _mainSupplierController.executeSupplierTransaction(
        supplier: supplier,
        type: selectedType.value,
        amount: double.parse(amountController.text),
        notes: notesController.text,
        transactionDate: selectedDate.value,
        affectsFund: affectsFund.value,
      );

      // --- 3. بداية الحل: تحديث إحصائيات الشاشة الرئيسية ---
      // بعد إتمام الحركة بنجاح، قم بإعادة جلب الإحصائيات
      // --- نهاية الحل ---
    }
  }

  @override
  void onClose() {
    amountController.dispose();
    notesController.dispose();
    dateController.dispose();
    super.onClose();
  }
}
