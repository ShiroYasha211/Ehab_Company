// File: lib/features/fund/presentation/controllers/fund_controller.dart

import 'package:ehab_company_admin/features/fund/data/models/fund_model.dart';
import 'package:ehab_company_admin/features/fund/data/models/fund_transaction_model.dart';
import 'package:ehab_company_admin/features/fund/data/repositories/fund_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FundController extends GetxController {
  final FundRepository _repository = FundRepository();

  FundRepository get repository => _repository;

  // --- متغيرات الحالة (State Variables) ---

  // متغير لتخزين بيانات الصندوق الحالي (مثل الرصيد)
  final Rx<FundModel?> currentFund = Rx<FundModel?>(null);

  // قائمة لتخزين كل حركات الصندوق
  final RxList<FundTransactionModel> transactions = <FundTransactionModel>[]
      .obs;

  // متغير لتتبع حالة التحميل
  final RxBool isLoading = true.obs;

  final RxDouble todaysDeposits = 0.0.obs;
  final RxDouble todaysWithdrawals = 0.0.obs;

  final Rx<DateTime?> fromDate = Rx<DateTime?>(null);
  final Rx<DateTime?> toDate = Rx<DateTime?>(null);
  final Rx<TransactionType?> transactionTypeFilter = Rx<TransactionType?>(null);


  @override
  void onInit() {
    super.onInit();
    // جلب البيانات عند بدء تشغيل الكنترولر
    loadFundData();

    ever(fromDate, (_) => loadFundData());
    ever(toDate, (_) => loadFundData());
    ever(transactionTypeFilter, (_) => loadFundData());
  }

  /// دالة لجلب كل بيانات الصندوق (الرصيد والحركات)
  Future<void> loadFundData() async {
    try {
      isLoading(true);
      const int mainFundId = 1;
      final results = await Future.wait([
        _repository.getMainFund(),
        _repository.getTodaysSummary(mainFundId),
        _repository.getAllTransactions(
          fundId: mainFundId,
          from: fromDate.value,
          to: toDate.value,
          type: transactionTypeFilter.value,
        ),
      ]);

      // تحديث متغيرات الحالة بالنتائج
      currentFund.value = results[0] as FundModel?;

      final summary = results[1] as Map<String, double>;
      todaysDeposits.value = summary['todaysDeposits'] ?? 0.0;
      todaysWithdrawals.value = summary['todaysWithdrawals'] ?? 0.0;

      transactions.assignAll(results[2] as List<FundTransactionModel>);
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء تحميل بيانات الصندوق: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading(false);
    }
  }

// --- نهاية التعديل ---


  /// دالة مبسطة لإضافة إيداع (توريد نقدي)
  Future<void> makeDeposit({
    required double amount,
    required String description,
    int? referenceId,
    DateTime? transactionDate, // <-- إضافة جديدة
  }) async {
    if (amount <= 0) {
      Get.snackbar('خطأ', 'يجب أن يكون المبلغ أكبر من صفر');
      return;
    }

    final newTransaction = FundTransactionModel(
      fundId: 1,
      // الصندوق الرئيسي
      type: TransactionType.DEPOSIT,
      amount: amount,
      description: description,
      referenceId: referenceId,
      // --- بداية التعديل ---
      transactionDate: transactionDate ??
          DateTime.now(), // استخدم التاريخ الممرر أو الحالي
      // --- نهاية التعديل ---
    );

    try {
      await _repository.addTransaction(newTransaction);
      await loadFundData();
      Get.back();
      Get.snackbar('نجاح', 'تمت عملية الإيداع بنجاح.',
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('خطأ', 'فشلت عملية الإيداع: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  /// دالة مبسطة لإضافة سحب (صرف نقدي)
  Future<void> makeWithdrawal({
    required double amount,
    required String description,
    int? referenceId,
    DateTime? transactionDate, // <-- إضافة جديدة
  }) async {
    await loadFundData();

    // 2. التحقق من كفاية الرصيد كخطوة أولى
    if (currentFund.value == null || currentFund.value!.balance < amount) {
      Get.snackbar(
        'خطأ في الرصيد',
        'الرصيد الحالي في الصندوق (${currentFund.value?.balance ??
            0} ريال) غير كافٍ لإتمام عملية السحب.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
      return; // إيقاف العملية تمامًا
    }
    if (amount <= 0) {
      Get.snackbar('خطأ', 'يجب أن يكون المبلغ أكبر من صفر');
      return;
    }


    final newTransaction = FundTransactionModel(
      fundId: 1,
      // الصندوق الرئيسي
      type: TransactionType.WITHDRAWAL,
      amount: amount,
      description: description,
      referenceId: referenceId,
      // --- بداية التعديل ---
      transactionDate: transactionDate ??
          DateTime.now(), // استخدم التاريخ الممرر أو الحالي
      // --- نهاية التعديل ---
    );

    try {
      await _repository.addTransaction(newTransaction);
      await loadFundData();
      Get.back();
      Get.snackbar('نجاح', 'تمت عملية السحب بنجاح.',
          backgroundColor: Colors.blue, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('خطأ', 'فشلت عملية السحب: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  // --- بداية الإضافة: دوال مساعدة للتحكم بالفلاتر ---

  /// دالة لمسح كل الفلاتر وإعادة جلب البيانات
  void clearFilters() {
    fromDate.value = null;
    toDate.value = null;
    transactionTypeFilter.value = null;
    // loadFundData() سيتم استدعاؤها تلقائيًا بفضل ever()  }

    /// دالة لإظهار DatePicker وتحديث التاري
    // --- نهاية الإضافة ---
  }
  Future<void> selectDate(BuildContext context,
      {required bool isFromDate}) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: (isFromDate ? fromDate.value : toDate.value) ??
          DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      locale: const Locale('ar'),
    );
    if (pickedDate != null) {
      if (isFromDate) {
        fromDate.value = pickedDate;
      } else {
        toDate.value = pickedDate;
      }
    }
  }
}