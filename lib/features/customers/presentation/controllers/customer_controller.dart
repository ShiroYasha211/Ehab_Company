// File: lib/features/customers/presentation/controllers/customer_controller.dart

import 'package:ehab_company_admin/features/customers/data/models/customer_model.dart';
import 'package:ehab_company_admin/features/customers/data/repositories/customer_repository.dart';
import 'package:flutter/material.dart' hide DateRangePickerDialog;
import 'package:get/get.dart';
import 'package:ehab_company_admin/core/services/customer_report_service.dart'; // <-- إضافة هذا السطر
import 'package:ehab_company_admin/features/fund/presentation/widgets/date_range_picker_dialog.dart';
import '../../data/models/customer_transaction_model.dart';

enum CustomerFilter { all, hasBalance, noBalance }

class CustomerController extends GetxController {
  final CustomerRepository _repository = CustomerRepository();

  CustomerRepository get repository => _repository;

  final RxList<CustomerModel> _allCustomers = <CustomerModel>[].obs;
  final RxList<CustomerModel> filteredCustomers = <CustomerModel>[].obs;
  final RxBool isLoading = true.obs;

  final RxString searchQuery = ''.obs;
  final Rx<CustomerFilter> currentFilter = CustomerFilter.all.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAllCustomers();

    debounce(searchQuery, (_) => _filterCustomers(),
        time: const Duration(milliseconds: 300));
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
        final phoneMatches = customer.phone?.toLowerCase().contains(query) ??
            false;
        return nameMatches || phoneMatches;
      });
    }

    filteredCustomers.assignAll(_filtered);
  }

  Future<void> addCustomer({
    required String name,
    String? phone,
    String? address,
    String? email,
    String? company,
    String? notes,}) async {
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
      balance: 0.0,
      // الرصيد يبدأ صفرًا
      createdAt: DateTime.now(),
    );
    try {
      await _repository.addCustomer(newCustomer);
      await fetchAllCustomers();
      Get.back();
      Get.snackbar(
          'نجاح', 'تمت إضافة العميل بنجاح', backgroundColor: Colors.green,
          colorText: Colors.white);
    } catch (e) {
      Get.snackbar(
          'خطأ', 'فشل في إضافة العميل: $e', backgroundColor: Colors.red,
          colorText: Colors.white);
    }
  }

  Future<void> deleteCustomer(CustomerModel customer) async {
    // 1. التحقق مما إذا كان للعميل أي علاقات (فواتير أو سندات)
    final bool hasRelations = await _repository.checkCustomerHasRelations(
        customer.id!);

    if (hasRelations) {
      // 2. إذا وجدت علاقات، اعرض ديالوج التحذير الشديد
      _showStrongWarningDialog(customer);
    } else {
      // 3. إذا لم توجد علاقات، اعرض ديالوج الحذف العادي
      _showSimpleDeleteDialog(customer);
    }
  }

  /// ديالوج الحذف العادي (للعملاء الذين ليس لديهم معاملات)
  void _showSimpleDeleteDialog(CustomerModel customer) {
    Get.defaultDialog(
      title: 'تأكيد الحذف',
      middleText: 'هل أنت متأكد من رغبتك في حذف العميل "${customer.name}"؟',
      textConfirm: 'حذف',
      textCancel: 'إلغاء',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back(); // أغلق الديالوج
        _performDelete(customer.id!);
      },
    );
  }

  /// ديالوج التحذير الشديد (للعملاء الذين لديهم معاملات)
  void _showStrongWarningDialog(CustomerModel customer) {
    Get.defaultDialog(
      title: '⚠️ تحذير خطير!',
      titleStyle: TextStyle(
          color: Colors.red.shade700, fontWeight: FontWeight.bold),
      content: const Column(
        children: [
          Text(
            'هذا العميل لديه فواتير أو حركات مالية مسجلة.',
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          Text(
            'حذف العميل سيؤدي إلى فقدان ربط هذه الفواتير والسندات به، وهو إجراء غير قابل للتراجع. هل أنت متأكد تمامًا من رغبتك في المتابعة؟',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red),
          ),
        ],
      ),
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
        onPressed: () {
          Get.back(); // أغلق الديالوج
          _performDelete(customer.id!);
        },
        child: const Text('نعم، أحذف العميل على مسؤوليتي'),
      ),
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: const Text('إلغاء'),
      ),
    );
  }

  /// دالة مساعدة لتنفيذ الحذف الفعلي بعد التأكيد
  Future<void> _performDelete(int id) async {
    try {
      await _repository.deleteCustomer(id);
      _allCustomers.removeWhere((customer) => customer.id == id);
      _filterCustomers(); // تحديث الواجهة
      Get.snackbar(
        'نجاح',
        'تم حذف العميل بنجاح.',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في حذف العميل: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> executeCustomerTransaction({
    required CustomerModel customer,
    required CustomerTransactionType type,
    required double amount, required DateTime transactionDate,
    required bool affectsFund,
    String? notes,
  }) async {
    try {
      final newTransaction = CustomerTransactionModel(
        customerId: customer.id!,
        type: type,
        amount: amount,
        transactionDate: transactionDate,
        affectsFund: affectsFund,
        notes: notes,
      );

      final transactionId = await _repository.addCustomerTransaction(
          newTransaction);
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

  // --- بداية الإضافة: دالة جديدة لطباعة كشف الحساب ---
  /// يبدأ عملية طباعة كشف حساب العميل لفترة محددة
  void printCustomerStatement(CustomerModel customer) {
    // 1. عرض ديالوج اختيار فترة التقرير
    Get.dialog(
      DateRangePickerDialog(
        onConfirm: (from, to) async {
          // 2. بعد أن يؤكد المستخدم، قم بإنشاء التقرير
          try {
            Get.dialog(
              const Center(child: CircularProgressIndicator()),
              barrierDismissible: false,
            );

            // 3. جلب بيانات كشف الحساب (الرصيد الافتتاحي والحركات)
            final reportData = await _repository.getCustomerStatementData(
              customerId: customer.id!,
              from: from,
              to: to,
            );

            if (Get.isDialogOpen!) Get.back(); // إغلاق مؤشر التحميل

            // 4. طباعة التقرير باستخدام البيانات التي تم جلبها
            await CustomerReportService.printCustomerStatement(
              customer: customer,
              // تمرير بيانات العميل
              openingBalance: reportData['openingBalance'],
              // تمرير الرصيد الافتتاحي
              transactions: reportData['transactions'], // تمرير قائمة الحركات
            );
          } catch (e) {
            if (Get.isDialogOpen!) Get
                .back(); // إغلاق مؤشر التحميل في حال حدوث خطأ
            Get.snackbar('خطأ', 'فشل في إنشاء كشف الحساب: $e');
          }
        },
      ),
    );
  }
// --- نهاية الإضافة ---
}

















