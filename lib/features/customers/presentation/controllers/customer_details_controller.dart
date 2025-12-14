// File: lib/features/customers/presentation/controllers/customer_details_controller.dart

import 'package:ehab_company_admin/features/customers/data/models/customer_model.dart';
import 'package:ehab_company_admin/features/customers/data/models/customer_transaction_model.dart';
import 'package:ehab_company_admin/features/customers/data/repositories/customer_repository.dart';
import 'package:ehab_company_admin/features/customers/presentation/controllers/customer_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/repositories/customers_transactions_repository.dart';

class CustomerDetailsController extends GetxController {
  final Rx<CustomerModel> customer;
  final CustomerTransactionsRepository _transactionsRepository =
  CustomerTransactionsRepository();
  final CustomerRepository _customerRepository = CustomerRepository(); // لإضافة دفعة

  final RxList<CustomerTransactionModel> transactions =
      <CustomerTransactionModel>[].obs;
  final RxBool isLoading = true.obs;

  CustomerDetailsController(CustomerModel initialCustomer)
      : customer = initialCustomer.obs;

  @override
  void onInit() {
    super.onInit();
    fetchTransactions();

    // الاستماع للتغييرات في القائمة الرئيسية لتحديث بيانات العميل الحالي لحظيًا
    final mainController = Get.find<CustomerController>();
    ever(mainController.filteredCustomers, (updatedList) {
      final updatedCustomer = updatedList.firstWhere(
            (c) => c.id == customer.value.id,
        orElse: () => customer.value,
      );
      customer.value = updatedCustomer;
    });
  }

  Future<void> fetchTransactions() async {
    try {
      isLoading(true);
      final transactionList = await _transactionsRepository
          .getTransactionsForCustomer(customer.value.id!);
      transactions.assignAll(transactionList);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في جلب حركات العميل: $e');
    } finally {
      isLoading(false);
    }
  }

  /// دالة لإضافة دفعة مستلمة من العميل
  Future<void> addReceiptTransaction(double amount, String notes) async {
    if (amount <= 0) {
      Get.snackbar('خطأ', 'الرجاء إدخال مبلغ صحيح.');
      return;
    }
    if (amount > customer.value.balance) {
      Get.snackbar('خطأ',
          'مبلغ الدفعة أكبر من الرصيد المستحق على العميل.');
      return;
    }

    final newTransaction = CustomerTransactionModel(
      customerId: customer.value.id!,
      type: CustomerTransactionType.RECEIPT, // سند قبض
      amount: amount,
      transactionDate: DateTime.now(),
      affectsFund: true,
      notes: notes.isEmpty ? 'سند قبض' : notes,
    );

    try {
      // استخدام repository العملاء لإضافة الحركة وتحديث الأرصدة
      await _customerRepository.addCustomerTransaction(newTransaction);

      // تحديث البيانات بعد النجاح
      await fetchTransactions(); // تحديث كشف الحساب

      // لا حاجة لتحديث قائمة العملاء الرئيسية يدويًا، لأن ever() ستقوم بذلك
      // Get.find<CustomerController>().fetchAllCustomers();

      Get.back(); // إغلاق ديالوج الدفع
      Get.snackbar(
        'نجاح',
        'تم تسجيل الدفعة بنجاح.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('فشل العملية', e.toString());
    }
  }
}
