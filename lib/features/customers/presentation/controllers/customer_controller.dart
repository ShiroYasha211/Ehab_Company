// File: lib/features/customers/presentation/controllers/customer_controller.dart

import 'package:ehab_company_admin/features/customers/data/models/customer_model.dart';
import 'package:ehab_company_admin/features/customers/data/repositories/customer_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/customer_transaction_model.dart';

enum CustomerFilter { all, hasBalance, noBalance }

class CustomerController extends GetxController {
  final CustomerRepository _repository = CustomerRepository();

  final RxList<CustomerModel> _allCustomers = <CustomerModel>[].obs;
  final RxList<CustomerModel> filteredCustomers = <CustomerModel>[].obs;
  final RxBool isLoading = true.obs;

  final RxString searchQuery = ''.obs;
  final Rx<CustomerFilter> currentFilter = CustomerFilter.all.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAllCustomers();

    debounce(searchQuery, (_) => _filterCustomers(), time: const Duration(milliseconds: 300));
    ever(currentFilter, (_) => _filterCustomers());
  }

  Future<void> fetchAllCustomers() async {
    try {
      isLoading(true);
      final customerList = await _repository.getAllCustomers();
      _allCustomers.assignAll(customerList);
      _filterCustomers();
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في جلب العملاء: $e');
    } finally {
      isLoading(false);
    }
  }

  void _filterCustomers() {
    List<CustomerModel> _filtered = List.from(_allCustomers);

    if (currentFilter.value == CustomerFilter.hasBalance) {
      _filtered.retainWhere((c) => c.balance > 0);
    } else if (currentFilter.value == CustomerFilter.noBalance) {
      _filtered.retainWhere((c) => c.balance == 0);
    }

    final query = searchQuery.value.toLowerCase().trim();
    if (query.isNotEmpty) {
      _filtered.retainWhere((customer) {
        final nameMatches = customer.name.toLowerCase().contains(query);
        final phoneMatches = customer.phone?.toLowerCase().contains(query) ?? false;
        return nameMatches || phoneMatches;
      });    }

    filteredCustomers.assignAll(_filtered);
  }

  Future<void> addCustomer({
  required  String name,
    String? phone,
    String? address,
    String? email,
    String? company,
    String? notes,  }) async {
    if (name.isEmpty) {
      Get.snackbar('خطأ', 'اسم العميل لا يمكن أن يكون فارغًا');
      return;
    }
    final newCustomer = CustomerModel(
      name: name,
      phone: phone,
      address: address,
      email: email,
      company: company,
      notes: notes,
      balance: 0.0, // الرصيد يبدأ صفرًا
      createdAt: DateTime.now(),
    );
    try {
      await _repository.addCustomer(newCustomer);
      await fetchAllCustomers();
      Get.back();
      Get.snackbar('نجاح', 'تمت إضافة العميل بنجاح', backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في إضافة العميل: $e', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> removeCustomer(int id) async {
    try {
      await _repository.deleteCustomer(id);
      _allCustomers.removeWhere((customer) => customer.id == id);
      _filterCustomers();
      Get.snackbar('نجاح', 'تم حذف العميل بنجاح', backgroundColor: Colors.blue, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في حذف العميل: $e', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> executeCustomerTransaction({
  required CustomerModel customer,
    required CustomerTransactionType type,
    required double amount,    required DateTime transactionDate,
    required bool affectsFund,
    String? notes,
  }) async {
    try {
      final newTransaction = CustomerTransactionModel(
          customerId: customer.id!,
          type: type,
        amount: amount,transactionDate: transactionDate,
        affectsFund: affectsFund,
        notes: notes,
      );

      final transactionId = await _repository.addCustomerTransaction(newTransaction);
      await fetchAllCustomers();
      Get.back();

      Get.snackbar(
          'نجاح العملية',
        'تم تسجيل الحركة المالية بنجاح. رقم السند: $transactionId',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'فشل العملية',
        'حدث خطأ غير متوقع: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> updateCustomer({
  required int id,
  required DateTime createdAt,
  required double balance,
  required String name,
  String? phone,
    String? address,
    String? email,
    String? company,
    String? notes,
  }) async {
    if (name.isEmpty) {
      Get.snackbar('خطأ', 'اسم العميل لا يمكن أن يكون فارغًا');
      return;
    }

    final updatedCustomer = CustomerModel(
      id: id,
      createdAt: createdAt,
      balance: balance,
      name: name,
      phone: phone,
      address: address,
      email: email,
      company: company,
      notes: notes,
    );

    try {
      await _repository.updateCustomer(updatedCustomer);
    await fetchAllCustomers();
      Get.back();

      Get.snackbar(
        'نجاح',
        'تم تعديل بيانات العميل بنجاح.',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في تعديل العميل: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
}

















