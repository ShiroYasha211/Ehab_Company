// File: lib/features/expenses/presentation/controllers/expense_controller.dart

import 'package:ehab_company_admin/features/expenses/data/models/expense_category_model.dart';
import 'package:ehab_company_admin/features/expenses/data/models/expense_model.dart';
import 'package:ehab_company_admin/features/expenses/data/repositories/expense_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../home/presentation/controllers/home_controller.dart';


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

  // Observables for UI state
  final RxBool isLoading = true.obs;
  final RxList<ExpenseModel> expenses = <ExpenseModel>[].obs;
  final RxList<ExpenseCategoryModel> categories = <ExpenseCategoryModel>[].obs;

  final RxList<ExpenseModel> filteredExpenses = <ExpenseModel>[].obs;
  final Rx<DateTime?> fromDate = Rx<DateTime?>(null);
  final Rx<DateTime?> toDate = Rx<DateTime?>(null);
  final Rx<int?> filterByCategoryId = Rx<int?>(null);

  final RxMap<int, ReportData> reportDataMap = <int, ReportData>{}.obs;
  double get totalReportAmount => reportDataMap.values
      .fold(0.0, (sum, item) => sum + item.totalAmount);

  // Form Controllers
  final formKey = GlobalKey<FormState>();
  final amountController = TextEditingController();
  final notesController = TextEditingController();
  final Rx<int?> selectedCategoryId = Rx<int?>(null);
  final Rx<DateTime> selectedDate = DateTime
      .now()
      .obs;
  final RxBool deductFromFund = true.obs;

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
      // --- بداية الإصلاح ---
      // قم بتطبيق الفلترة دائمًا بعد محاولة الجلب، سواء نجحت أم فشلت
      // هذا يضمن أن filteredExpenses يتم تحديثها دائمًا
      _filterExpenses();
      // --- نهاية الإصلاح ---
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
  void addExpense() async {
    if (formKey.currentState!.validate()) {
      final newExpense = ExpenseModel(
        categoryId: selectedCategoryId.value!,
        amount: double.parse(amountController.text),
        expenseDate: selectedDate.value,
        notes: notesController.text,
      );

      try {
        final expenseId =
        await _repository.addExpense(newExpense, deductFromFund.value);

        // تحديث البيانات بعد النجاح
        await fetchAllExpenses();
        if (deductFromFund.value) {
          Get.find<HomeController>().refreshStats(); // تحديث إحصائيات الصندوق
        }

        // إعادة تعيين الحقول وإغلاق الشاشة
        _resetForm();
        Get.back();

        Get.snackbar(
          'نجاح',
          'تم تسجيل المصروف بنجاح. رقم السند: $expenseId',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } catch (e) {
        Get.snackbar(
          'فشل العملية',
          'حدث خطأ غير متوقع: ${e.toString()}',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  /// دالة لإعادة تعيين حقول الإدخال
  void _resetForm() {
    amountController.clear();
    notesController.clear();
    selectedCategoryId.value = null;
    selectedDate.value = DateTime.now();
    deductFromFund.value = true;
  }

  /// إضافة بند مصروف جديد
  Future<void> addCategory(String name) async {
    if (name
        .trim()
        .isEmpty) {
      Get.snackbar('خطأ', 'اسم البند لا يمكن أن يكون فارغًا');
      return;
    }
    await _repository.addCategory(name);
    await fetchAllCategories(); // تحديث قائمة البنود
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
      _filtered.retainWhere((exp) =>
      exp.categoryId == filterByCategoryId.value);
    }

    // الفلترة حسب تاريخ البداية
    if (fromDate.value != null) {
      _filtered.retainWhere((exp) =>
      exp.expenseDate.isAtSameMomentAs(fromDate.value!) ||
          exp.expenseDate.isAfter(fromDate.value!));
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
    if (newName
        .trim()
        .isEmpty) {
      Get.snackbar('خطأ', 'اسم البند لا يمكن أن يكون فارغًا');
      return;
    }
    try {
      await _repository.updateCategory(id, newName);
      await fetchAllCategories(); // تحديث قائمة البنود
      Get.snackbar(
          'نجاح', 'تم تعديل اسم البند بنجاح', backgroundColor: Colors.blue,
          colorText: Colors.white);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل تعديل البند: ${e.toString()}',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  /// حذف بند مصروف
  Future<void> deleteCategory(int id) async {
    try {
      await _repository.deleteCategory(id);
      await fetchAllCategories(); // تحديث قائمة البنود
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