// File: lib/features/fund/presentation/controllers/fund_controller.dart

import 'package:ehab_company_admin/features/fund/data/models/fund_model.dart';
import 'package:ehab_company_admin/features/fund/data/models/fund_transaction_model.dart';
import 'package:ehab_company_admin/features/fund/data/repositories/fund_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FundController extends GetxController {
  final FundRepository _repository = FundRepository();

  // --- متغيرات الحالة (State Variables) ---

  // متغير لتخزين بيانات الصندوق الحالي (مثل الرصيد)
  final Rx<FundModel?> currentFund = Rx<FundModel?>(null);

  // قائمة لتخزين كل حركات الصندوق
  final RxList<FundTransactionModel> transactions = <FundTransactionModel>[].obs;

  // متغير لتتبع حالة التحميل
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    // جلب البيانات عند بدء تشغيل الكنترولر
    loadFundData();
  }

  /// دالة لجلب كل بيانات الصندوق (الرصيد والحركات)
  Future<void> loadFundData() async {
    try {
      isLoading(true);
      // نفترض أننا نتعامل دائمًا مع الصندوق الرئيسي (ID = 1)
      const int mainFundId = 1;

      // جلب بيانات الصندوق (الرصيد)
      currentFund.value = await _repository.getMainFund();

      // جلب كل الحركات المرتبطة بهذا الصندوق
      final transactionList = await _repository.getAllTransactions(mainFundId);
      transactions.assignAll(transactionList);
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
      fundId: 1, // الصندوق الرئيسي
      type: TransactionType.DEPOSIT,
      amount: amount,
      description: description,
      referenceId: referenceId,
      // --- بداية التعديل ---
      transactionDate: transactionDate ?? DateTime.now(), // استخدم التاريخ الممرر أو الحالي
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
        'الرصيد الحالي في الصندوق (${currentFund.value?.balance ?? 0} ريال) غير كافٍ لإتمام عملية السحب.',
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
      fundId: 1, // الصندوق الرئيسي
      type: TransactionType.WITHDRAWAL,
      amount: amount,
      description: description,
      referenceId: referenceId,
      // --- بداية التعديل ---
      transactionDate: transactionDate ?? DateTime.now(), // استخدم التاريخ الممرر أو الحالي
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
}
