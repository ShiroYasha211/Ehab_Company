// File: lib/features/customers/presentation/controllers/add_customer_payment_controller.dart

import 'package:ehab_company_admin/features/customers/data/models/customer_model.dart';
import 'package:ehab_company_admin/features/customers/data/models/customer_transaction_model.dart';
import 'package:ehab_company_admin/features/customers/presentation/controllers/customer_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;

class AddCustomerPaymentController extends GetxController {
  final CustomerController _mainCustomerController = Get.find<CustomerController>();
  final formKey = GlobalKey<FormState>();

  // Observables
  final Rx<int?> selectedCustomerId = Rx<int?>(null);
  final Rx<CustomerTransactionType> selectedType =
      CustomerTransactionType.RECEIPT.obs; // الافتراضي هو سند قبض
  final RxBool affectsFund = true.obs;
  final Rx<DateTime> selectedDate = DateTime.now().obs;

  // Text Editing Controllers
  final amountController = TextEditingController();
  final dateController = TextEditingController();
  final notesController = TextEditingController();

  // Lists
  final RxList<CustomerModel> customersList = <CustomerModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    // جلب قائمة العملاء
    customersList.assignAll(_mainCustomerController.filteredCustomers);
    // ربط تغيير النوع بخيار الصندوق
    ever(selectedType, _handleTypeChange);
    // تهيئة حقل التاريخ
    dateController.text = intl.DateFormat('yyyy-MM-dd').format(selectedDate.value);
  }

  void _handleTypeChange(CustomerTransactionType type) {
    if (type == CustomerTransactionType.OPENING_BALANCE) {
      affectsFund.value = false; // الرصيد الافتتاحي لا يؤثر على الصندوق
    } else {
      affectsFund.value = true;
    }
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
      selectedDate.value = pickedDate;
      dateController.text = intl.DateFormat('yyyy-MM-dd').format(pickedDate);
    }
  }

  void submit() async {
    if (formKey.currentState!.validate()) {
      final customer = customersList.firstWhere((c) => c.id == selectedCustomerId.value);
      final double amount = double.parse(amountController.text);

      // --- بداية الإضافة: التحقق من مبلغ الدفعة ---
      // هذا الشرط يعمل فقط في حالة سند القبض، لأن الرصيد الافتتاحي يمكن أن يكون أي مبلغ
      if (selectedType.value == CustomerTransactionType.RECEIPT && amount > customer.balance) {
        Get.snackbar(
          'خطأ في المبلغ',
          'مبلغ الدفعة لا يمكن أن يكون أكبر من الرصيد المستحق على العميل.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return; // إيقاف العملية
      }
      // --- نهاية الإضافة ---

      await _mainCustomerController.executeCustomerTransaction(
        customer: customer,
        type: selectedType.value,
        amount: amount,
        notes: notesController.text,
        transactionDate: selectedDate.value,
        affectsFund: affectsFund.value,
      );
    }
  }

  @override
  void onClose() {
    amountController.dispose();
    dateController.dispose();
    notesController.dispose();
    super.onClose();
  }
}
