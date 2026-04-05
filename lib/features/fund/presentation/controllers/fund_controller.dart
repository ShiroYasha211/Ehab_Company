// File: lib/features/fund/presentation/controllers/fund_controller.dart

import 'package:ehab_company_admin/features/fund/data/models/fund_model.dart';
import 'package:ehab_company_admin/features/fund/data/models/fund_transaction_model.dart';
import 'package:ehab_company_admin/features/fund/data/repositories/fund_repository.dart';
import 'package:ehab_company_admin/features/activities/data/models/activity_model.dart';
import 'package:ehab_company_admin/features/activities/presentation/controllers/activity_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/services/settings_service.dart';

class FundController extends GetxController {
  final FundRepository _repository = FundRepository();
  final ActivityController _activityController = Get.find<ActivityController>();

  FundRepository get repository => _repository;

  // --- متغيرات الحالة ---
  final RxList<FundModel> subFunds = <FundModel>[].obs;
  final RxDouble totalBalance = 0.0.obs;
  final RxInt selectedFundIndex = 0.obs; // التبويب الحالي: 0=نقد، 1=بنوك، 2=حوالات

  // تعقب الصندوق المختار في كل تاب
  final RxInt selectedCashId = 0.obs;
  final RxInt selectedBankId = 0.obs;
  final RxInt selectedTransferId = 0.obs;
  final RxList<FundTransactionModel> transactions = <FundTransactionModel>[].obs;
  final RxBool isLoading = true.obs;

  // ملخص اليوم
  final RxDouble todaysDeposits = 0.0.obs;
  final RxDouble todaysWithdrawals = 0.0.obs;

  // فلاتر
  final Rx<DateTime?> fromDate = Rx<DateTime?>(null);
  final Rx<DateTime?> toDate = Rx<DateTime?>(null);
  final Rx<TransactionType?> transactionTypeFilter = Rx<TransactionType?>(null);

  @override
  void onInit() {
    super.onInit();
    loadAllData();

    ever(fromDate, (_) => _loadTransactions());
    ever(toDate, (_) => _loadTransactions());
    ever(transactionTypeFilter, (_) => _loadTransactions());
    ever(selectedFundIndex, (_) => _loadTransactions());
    ever(selectedCashId, (_) => _loadTransactions());
    ever(selectedBankId, (_) => _loadTransactions());
    ever(selectedTransferId, (_) => _loadTransactions());
  }

  /// جلب كل البيانات (الصناديق + الحركات)
  Future<void> loadAllData() async {
    try {
      isLoading(true);
      
      // جلب كل الصناديق الفرعية
      final funds = await _repository.getAllSubFunds();
      subFunds.assignAll(funds);

      // حساب الرصيد الإجمالي
      totalBalance.value = await _repository.getTotalBalance();

      // تعيين القيم الافتراضية إذا لم تكن محددة
      if (funds.isNotEmpty) {
        final cashFunds = getFundsByType(FundType.cash);
        if (selectedCashId.value == 0 && cashFunds.isNotEmpty) selectedCashId.value = cashFunds.first.id;
        
        final bankFunds = getFundsByType(FundType.bank);
        if (selectedBankId.value == 0 && bankFunds.isNotEmpty) selectedBankId.value = bankFunds.first.id;
        
        final transferFunds = getFundsByType(FundType.transfer);
        if (selectedTransferId.value == 0 && transferFunds.isNotEmpty) selectedTransferId.value = transferFunds.first.id;
      }

      // جلب حركات الصندوق المحدد
      await _loadTransactions();
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ أثناء تحميل بيانات الصناديق: $e',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading(false);
    }
  }

  /// جلب حركات الصندوق المحدد حالياً
  Future<void> _loadTransactions() async {
    try {
      if (subFunds.isEmpty) return;

      final selectedFund = getSelectedFund();
      if (selectedFund == null) {
        transactions.clear();
        todaysDeposits.value = 0;
        todaysWithdrawals.value = 0;
        return;
      }

      final results = await Future.wait([
        _repository.getTransactions(
          fundId: selectedFund.id,
          from: fromDate.value,
          to: toDate.value,
          type: transactionTypeFilter.value,
        ),
        _repository.getTodaysSummary(selectedFund.id),
      ]);

      transactions.assignAll(results[0] as List<FundTransactionModel>);

      final summary = results[1] as Map<String, double>;
      todaysDeposits.value = summary['todaysDeposits'] ?? 0.0;
      todaysWithdrawals.value = summary['todaysWithdrawals'] ?? 0.0;
    } catch (_) {}
  }

  /// الصندوق المحدد حالياً بناءً على التبويب والنوع
  FundModel? getSelectedFund() {
    if (subFunds.isEmpty) return null;
    
    int targetId = 0;
    if (selectedFundIndex.value == 0) targetId = selectedCashId.value;
    else if (selectedFundIndex.value == 1) targetId = selectedBankId.value;
    else if (selectedFundIndex.value == 2) targetId = selectedTransferId.value;

    if (targetId == 0) return null;
    return subFunds.firstWhereOrNull((f) => f.id == targetId);
  }

  /// الصناديق حسب النوع
  List<FundModel> getFundsByType(FundType type) {
    return subFunds.where((f) => f.fundType == type).toList();
  }

  // ==================== عمليات الإيداع والسحب ====================

  Future<void> makeDeposit({
    required int fundId,
    required double amount,
    required String description,
    int? referenceId,
    DateTime? transactionDate,
    String? transferCompany,
    String? senderName,
    String? receiverName,
    String? transferNumber,
    String? referenceType,
    double fees = 0.0,
    String? attachmentPath,
  }) async {
    if (amount <= 0) {
      Get.snackbar('خطأ', 'يجب أن يكون المبلغ أكبر من صفر');
      return;
    }

    final tx = FundTransactionModel(
      fundId: fundId,
      type: TransactionType.DEPOSIT,
      amount: amount,
      description: description,
      referenceId: referenceId,
      transactionDate: transactionDate ?? DateTime.now(),
      transferCompany: transferCompany,
      senderName: senderName,
      receiverName: receiverName,
      transferNumber: transferNumber,
      referenceType: referenceType,
      fees: fees,
      attachmentPath: attachmentPath,
    );

    try {
      await _repository.addTransaction(tx);
      await loadAllData();

      // تسجيل إيداع
      final fundName = subFunds.firstWhereOrNull((f) => f.id == fundId)?.name ?? "غير معروف";
      await _activityController.logAction(
        action: 'إيداع في الصندوق/الخزنة',
        details: 'تم إيداع مبلغ $amount في صندوق ($fundName). البيان: $description',
        type: ActivityType.fund,
      );

      Get.back();
      Get.snackbar('نجاح', 'تمت عملية الإيداع بنجاح.',
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('خطأ', 'فشلت عملية الإيداع: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> makeWithdrawal({
    required int fundId,
    required double amount,
    required String description,
    int? referenceId,
    DateTime? transactionDate,
    String? transferCompany,
    String? senderName,
    String? receiverName,
    String? transferNumber,
    String? referenceType,
    double fees = 0.0,
    String? attachmentPath,
  }) async {
    if (amount <= 0) {
      Get.snackbar('خطأ', 'يجب أن يكون المبلغ أكبر من صفر');
      return;
    }

    // التحقق من كفاية الرصيد (المبلغ + الرسوم)
    final balance = await _repository.getFundBalance(fundId);
    if (balance < (amount + fees)) {
      final settings = Get.find<SettingsService>();
      Get.snackbar(
        'خطأ في الرصيد',
        'الرصيد الحالي (${balance.toStringAsFixed(2)} ${settings.primaryCurrency.value.symbol}) غير كافٍ لتغطية المبلغ والرسوم (${(amount + fees).toStringAsFixed(2)}).',
        backgroundColor: Colors.red, colorText: Colors.white, duration: const Duration(seconds: 5),
      );
      return;
    }

    final tx = FundTransactionModel(
      fundId: fundId,
      type: TransactionType.WITHDRAWAL,
      amount: amount,
      description: description,
      referenceId: referenceId,
      transactionDate: transactionDate ?? DateTime.now(),
      transferCompany: transferCompany,
      senderName: senderName,
      receiverName: receiverName,
      transferNumber: transferNumber,
      referenceType: referenceType,
      fees: fees,
      attachmentPath: attachmentPath,
    );

    try {
      await _repository.addTransaction(tx);
      await loadAllData();

      // تسجيل سحب
      final fundName = subFunds.firstWhereOrNull((f) => f.id == fundId)?.name ?? "غير معروف";
      await _activityController.logAction(
        action: 'سحب من الصندوق/الخزنة',
        details: 'تم سحب مبلغ $amount من صندوق ($fundName). البيان: $description',
        type: ActivityType.fund,
      );

      Get.back();
      Get.snackbar('نجاح', 'تمت عملية السحب بنجاح.',
          backgroundColor: Colors.blue, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('خطأ', 'فشلت عملية السحب: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  // ==================== التحويل بين الصناديق ====================

  Future<void> transferFunds({
    required int sourceFundId,
    required int targetFundId,
    required double amount,
    required String description,
    DateTime? transactionDate,
    double fees = 0.0,
    String? transferNumber,
  }) async {
    if (amount <= 0) {
      Get.snackbar('خطأ', 'يجب أن يكون المبلغ أكبر من صفر');
      return;
    }
    if (sourceFundId == targetFundId) {
      Get.snackbar('خطأ', 'لا يمكن التحويل إلى نفس الصندوق');
      return;
    }

    // التحقق من كفاية الرصيد (المبلغ + الرسوم) في المصدر
    final balance = await _repository.getFundBalance(sourceFundId);
    if (balance < (amount + fees)) {
      Get.snackbar('خطأ', 'رصيد الصندوق المصدر غير كافٍ لتغطية المبلغ والرسوم.',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    try {
      await _repository.transferBetweenFunds(
        sourceFundId: sourceFundId,
        targetFundId: targetFundId,
        amount: amount,
        description: description,
        transactionDate: transactionDate,
        fees: fees,
        transferNumber: transferNumber,
      );
      await loadAllData();

      // تسجيل تحويل
      final sourceName = subFunds.firstWhereOrNull((f) => f.id == sourceFundId)?.name ?? "غير معروف";
      final targetName = subFunds.firstWhereOrNull((f) => f.id == targetFundId)?.name ?? "غير معروف";
      await _activityController.logAction(
        action: 'تحويل بين الصناديق',
        details: 'تحويل مبلغ $amount من ($sourceName) إلى ($targetName). البيان: $description. الرسوم: $fees',
        type: ActivityType.fund,
      );

      Get.back();
      Get.snackbar('نجاح', 'تم التحويل بنجاح.',
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل التحويل: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  // ==================== إنشاء صندوق فرعي ====================

  Future<void> createSubFund({
    required String name,
    required FundType type,
    String? bankName,
    String? accountNumber,
    double initialBalance = 0.0,
  }) async {
    final fund = FundModel(
      id: 0,
      name: name,
      balance: initialBalance,
      fundType: type,
      bankName: bankName,
      accountNumber: accountNumber,
      isActive: true,
      initialBalance: initialBalance,
    );

    try {
      await _repository.createFund(fund);
      await loadAllData();

      // تسجيل إنشاء صندوق
      await _activityController.logAction(
        action: 'إنشاء صندوق جديد',
        details: 'تم إنشاء صندوق جديد باسم ($name) بنوع (${type.name}) ورصيد افتتاحي $initialBalance',
        type: ActivityType.fund,
      );

      Get.back();
      Get.snackbar('نجاح', 'تم إنشاء الصندوق الفرعي بنجاح.',
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل إنشاء الصندوق: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  // ==================== تعديل وحذف الصندوق ====================

  Future<void> updateSubFund(FundModel fund) async {
    try {
      await _repository.updateFund(fund);
      await loadAllData();

      // تسجيل تعديل صندوق
      await _activityController.logAction(
        action: 'تعديل بيانات صندوق',
        details: 'تم تحديث بيانات الصندوق (${fund.name}). الرصيد الحالي: ${fund.balance}',
        type: ActivityType.fund,
      );

      Get.back(); // إغلاق الديالوج
      Get.snackbar('نجاح', 'تم تحديث بيانات الصندوق بنجاح.',
          backgroundColor: Colors.blue, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل التحديث: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> handleFundDeletion(int fundId) async {
    try {
      // 1. التحقق من وجود حركات
      bool hasTx = await _repository.hasTransactions(fundId);

      if (hasTx) {
        // إذا كان له حركات، نقوم بالتعطيل فقط
        await _repository.deactivateFund(fundId);

        // تسجيل تعطيل
        await _activityController.logAction(
          action: 'تعطيل صندوق',
          details: 'تم تعطيل/إخفاء الصندوق رقم (#$fundId) لوجود حركات مالية سابقة.',
          type: ActivityType.fund,
        );

        Get.snackbar('تم التعطيل', 'تم إخفاء الصندوق لوجود حركات مالية مرتبطة به حفاظاً على سلامة البيانات.',
            backgroundColor: Colors.orange, colorText: Colors.white);
      } else {
        // إذا لم يكن له حركات، نحذفه نهائياً
        await _repository.deleteFund(fundId);

        // تسجيل حذف
        await _activityController.logAction(
          action: 'حذف صندوق',
          details: 'تم حذف الصندوق رقم (#$fundId) نهائياً لعدم وجود حركات مالية.',
          type: ActivityType.fund,
        );

        Get.snackbar('تم الحذف', 'تم حذف الصندوق بنجاح.',
            backgroundColor: Colors.green, colorText: Colors.white);
      }

      // 2. تصفير الاختيارات إذا كان الصندوق المحذوف هو المختار
      if (selectedCashId.value == fundId) selectedCashId.value = 0;
      if (selectedBankId.value == fundId) selectedBankId.value = 0;
      if (selectedTransferId.value == fundId) selectedTransferId.value = 0;

      await loadAllData();
    } catch (e) {
      Get.snackbar('خطأ', 'فشلت عملية الحذف: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  // ==================== الفلاتر ====================

  void clearFilters() {
    fromDate.value = null;
    toDate.value = null;
    transactionTypeFilter.value = null;
  }

  Future<void> selectDate(BuildContext context, {required bool isFromDate}) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: (isFromDate ? fromDate.value : toDate.value) ?? DateTime.now(),
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
