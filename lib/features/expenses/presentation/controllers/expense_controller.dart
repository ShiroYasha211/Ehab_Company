// File: lib/features/expenses/presentation/controllers/expense_controller.dart

import 'package:ehab_company_admin/features/expenses/data/models/expense_category_model.dart';
import 'package:ehab_company_admin/features/expenses/data/models/expense_model.dart';
import 'package:ehab_company_admin/features/expenses/data/repositories/expense_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ehab_company_admin/features/activities/data/models/activity_model.dart';
import 'package:ehab_company_admin/features/activities/presentation/controllers/activity_controller.dart';

import '../../../fund/presentation/controllers/fund_controller.dart';
import '../../../suppliers/data/models/supplier_model.dart';
import '../../../suppliers/data/repositories/supplier_repository.dart';

class ReportData {
  final String categoryName;
  double totalAmount;
  double percentage;

  ReportData({
    required this.categoryName,
    this.totalAmount = 0.0,
    this.percentage = 0.0,
  });
}

class ExpenseController extends GetxController {
  final ExpenseRepository _repository = ExpenseRepository();
  final ActivityController _activityController = Get.find<ActivityController>();

  ExpenseRepository get expenseRepository => _repository;

  // Observables for UI state
  final RxBool isLoading = true.obs;
  final RxList<ExpenseModel> expenses = <ExpenseModel>[].obs;
  final RxList<ExpenseCategoryModel> categories = <ExpenseCategoryModel>[].obs;

  final FundController _fundController = Get.find<FundController>();
  final SupplierRepository _supplierRepository = SupplierRepository();

  final RxList<SupplierModel> suppliers = <SupplierModel>[].obs;

  final RxList<ExpenseModel> filteredExpenses = <ExpenseModel>[].obs;
  final Rx<DateTime?> fromDate = Rx<DateTime?>(null);
  final Rx<DateTime?> toDate = Rx<DateTime?>(null);
  final Rx<int?> filterByCategoryId = Rx<int?>(null);

  final RxMap<int, ReportData> reportDataMap = <int, ReportData>{}.obs;
  double get totalReportAmount =>
      reportDataMap.values.fold(0.0, (sum, item) => sum + item.totalAmount);

  // Form Controllers
  final formKey = GlobalKey<FormState>();
  final amountController = TextEditingController();
  final notesController = TextEditingController();
  final Rx<int?> selectedCategoryId = Rx<int?>(null);
  final Rx<int?> selectedFundId = Rx<int?>(null); // الصندوق المختار للصرف
  final Rx<int?> selectedSupplierId = Rx<int?>(null); // المورد المرتبط (اختياري)
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final RxBool deductFromFund = true.obs;
  final RxBool isSupplierRelated = false.obs; // هل المصروف مرتبط بمورد؟

  @override
  void onInit() {
    super.onInit();
    // جلب البيانات الأولية عند بدء تشغيل الـ Controller
    fetchInitialData();

    // --- بداية الإضافة: ربط الفلاتر ---
    ever(fromDate, (_) => _filterExpenses());
    ever(toDate, (_) => _filterExpenses());
    ever(filterByCategoryId, (_) => _filterExpenses());

    ever(filteredExpenses, (_) => generateReportData());
    // --- نهاية الإضافة ---
  }

  /// جلب كل البيانات اللازمة (المصروفات والبنود)
  Future<void> fetchInitialData() async {
    isLoading(true);
    await Future.wait([
      fetchAllExpenses(),
      fetchAllCategories(),
      fetchAllSuppliers(),
    ]);
    isLoading(false);
  }

  /// جلب كل المصروفات
  Future<void> fetchAllExpenses() async {
    try {
      final expenseList = await _repository.getAllExpenses();
      expenses.assignAll(expenseList);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في جلب المصروفات: $e');
    } finally {
      _filterExpenses();
    }
  }

  /// جلب كل الموردين لاستخدامهم في القائمة المنسدلة
  Future<void> fetchAllSuppliers() async {
    try {
      final supplierList = await _supplierRepository.getAllSuppliers();
      suppliers.assignAll(supplierList);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في جلب الموردين: $e');
    }
  }

  /// جلب كل بنود المصروفات
  Future<void> fetchAllCategories() async {
    try {
      final categoryList = await _repository.getAllCategories();
      categories.assignAll(categoryList);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في جلب بنود المصروفات: $e');
    }
  }

  /// إضافة مصروف جديد
  // --- بداية التعديل: تعديل دالة الحفظ بالكامل ---
  /// دالة لإضافة مصروف جديد مع التحقق من رصيد الصندوق
  Future<void> addExpense() async {
    // 1. التحقق من أن الفورم صالح
    if (!formKey.currentState!.validate()) {
      return;
    }

    final double amount = double.tryParse(amountController.text) ?? 0.0;

    // 1.5 التحقق من اختيار مورد إذا كان الخيار مفعلاً
    if (isSupplierRelated.value && selectedSupplierId.value == null) {
      Get.snackbar('تنبيه', 'يرجى اختيار المورد المرتبط بهذا المصروف.', backgroundColor: Colors.orange);
      return;
    }

    // 2. التحقق من رصيد الصندوق المحدد (فقط إذا كان خيار الخصم مفعلًا)
    if (deductFromFund.value) {
      if (selectedFundId.value == null) {
        Get.snackbar('خطأ', 'يرجى اختيار الصندوق الذي سيتم الصرف منه.', backgroundColor: Colors.orange);
        return;
      }

      // جلب رصيد الصندوق المحدد حصراً
      final selectedFund = _fundController.subFunds.firstWhereOrNull((f) => f.id == selectedFundId.value);
      final double currentFundBalance = selectedFund?.balance ?? 0.0;

      if (amount > currentFundBalance) {
        Get.snackbar(
          'رصيد الصندوق غير كافٍ',
          'رصيد الصندوق المختار (${selectedFund?.name}) الحالي ($currentFundBalance) أقل من مبلغ المصروف.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        return;
      }
    }

    // 3. إذا كانت كل التحققات ناجحة، قم بتنفيذ الحفظ
    try {
      final newExpense = ExpenseModel(
        categoryId: selectedCategoryId.value!,
        amount: amount,
        expenseDate: selectedDate.value,
        notes: notesController.text,
        deductFromFund: deductFromFund.value,
        fundId: selectedFundId.value,
        supplierId: isSupplierRelated.value ? selectedSupplierId.value : null,
      );
      await _repository.addExpense(newExpense, deductFromFund.value);

      // تحديث البيانات في الواجهات الأخرى
      fetchAllExpenses();
      if (deductFromFund.value) {
        _fundController.loadAllData();
      }

      // تسجيل نشاط مصروف جديد
      final categoryName = categories.firstWhereOrNull((c) => c.id == selectedCategoryId.value)?.name ?? "غير معروف";
      final fundName = _fundController.subFunds.firstWhereOrNull((f) => f.id == selectedFundId.value)?.name ?? "صندوق غير محدد";
      final supplierName = isSupplierRelated.value 
          ? (suppliers.firstWhereOrNull((s) => s.id == selectedSupplierId.value)?.name ?? "مورد غير معروف")
          : null;

      String details = 'تم تسجيل مصروف بمبلغ $amount تحت بند ($categoryName) من صندوق ($fundName).';
      if (supplierName != null) {
        details += ' تم تحميله على المورد ($supplierName).';
      }
      details += ' ملاحظات: ${notesController.text}';

      await _activityController.logAction(
        action: 'تسجيل مصروف جديد',
        details: details,
        type: ActivityType.expense,
      );

      Get.back(); // العودة من شاشة الإضافة
      Get.snackbar(
        'نجاح',
        'تم تسجيل المصروف بنجاح.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'خطأ في الحفظ',
        'حدث خطأ غير متوقع: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  // --- نهاية التعديل ---

  /// إضافة بند مصروف جديد
  Future<void> addCategory(String name) async {
    if (name.trim().isEmpty) {
      Get.snackbar('خطأ', 'اسم البند لا يمكن أن يكون فارغًا');
      return;
    }
    await _repository.addCategory(name);
    await fetchAllCategories(); // تحديث قائمة البنود

    // تسجيل إضافة بند
    await _activityController.logAction(
      action: 'إضافة بند مصروف جديد',
      details: 'تم إضافة بند جديد باسم ($name) في قائمة المصروفات.',
      type: ActivityType.expense,
    );
  }

  @override
  void onClose() {
    amountController.dispose();
    notesController.dispose();
    super.onClose();
  }

  void _filterExpenses() {
    List<ExpenseModel> _filtered = List.from(expenses);

    // الفلترة حسب البند
    if (filterByCategoryId.value != null) {
      _filtered.retainWhere(
        (exp) => exp.categoryId == filterByCategoryId.value,
      );
    }

    // الفلترة حسب تاريخ البداية
    if (fromDate.value != null) {
      _filtered.retainWhere(
        (exp) =>
            exp.expenseDate.isAtSameMomentAs(fromDate.value!) ||
            exp.expenseDate.isAfter(fromDate.value!),
      );
    }

    // الفلترة حسب تاريخ النهاية
    if (toDate.value != null) {
      // Add one day to include the end date itself
      final inclusiveToDate = toDate.value!.add(const Duration(days: 1));
      _filtered.retainWhere((exp) => exp.expenseDate.isBefore(inclusiveToDate));
    }

    filteredExpenses.assignAll(_filtered);
  }

  void clearFilters() {
    fromDate.value = null;
    toDate.value = null;
    filterByCategoryId.value = null;
  }

  /// تعديل اسم بند مصروف
  Future<void> updateCategory(int id, String newName) async {
    if (newName.trim().isEmpty) {
      Get.snackbar('خطأ', 'اسم البند لا يمكن أن يكون فارغًا');
      return;
    }
    try {
      final oldName = categories.firstWhereOrNull((c) => c.id == id)?.name ?? "صنف قديم";
      await _repository.updateCategory(id, newName);
      await fetchAllCategories(); // تحديث قائمة البنود

      // تسجيل تعديل بند
      await _activityController.logAction(
        action: 'تعديل بند مصروف',
        details: 'تم تغيير اسم البند من ($oldName) إلى ($newName).',
        type: ActivityType.expense,
      );

      Get.snackbar(
        'نجاح',
        'تم تعديل اسم البند بنجاح',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل تعديل البند: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// حذف بند مصروف
  Future<void> deleteCategory(int id) async {
    try {
      final categoryName = categories.firstWhereOrNull((c) => c.id == id)?.name ?? "صنف محذوف";
      await _repository.deleteCategory(id);
      await fetchAllCategories(); // تحديث قائمة البنود

      // تسجيل حذف بند
      await _activityController.logAction(
        action: 'حذف بند مصروف',
        details: 'تم حذف بند المصروف ($categoryName) من قائمة البنود.',
        type: ActivityType.expense,
      );

      Get.snackbar('نجاح', 'تم حذف البند بنجاح');
    } catch (e) {
      // التعامل مع خطأ الحذف إذا كان البند مستخدمًا
      Get.snackbar(
        'لا يمكن الحذف',
        'لا يمكن حذف هذا البند لأنه مستخدم في مصروفات مسجلة.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void generateReportData() {
    // 1. إعادة تعيين بيانات التقرير القديمة
    reportDataMap.clear();

    // 2. تجميع المبالغ لكل بند
    for (final expense in filteredExpenses) {
      if (reportDataMap.containsKey(expense.categoryId)) {
        // إذا كان البند موجودًا، قم بزيادة إجمالي المبلغ
        reportDataMap[expense.categoryId]!.totalAmount += expense.amount;
      } else {
        // إذا كان البند جديدًا، قم بإنشاء إدخال جديد له
        reportDataMap[expense.categoryId] = ReportData(
          categoryName: expense.categoryName ?? 'غير معروف',
          totalAmount: expense.amount,
        );
      }
    }

    // 3. حساب النسبة المئوية لكل بند
    final total = totalReportAmount;
    if (total > 0) {
      for (final reportData in reportDataMap.values) {
        reportData.percentage = (reportData.totalAmount / total) * 100;
      }
    }
  }
}
