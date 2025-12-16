// File: lib/features/expenses/presentation/screens/expenses_binding.dart

import 'package:ehab_company_admin/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:get/get.dart';

class ExpensesBinding extends Bindings {
  @override
  void dependencies() {
    // استخدم lazyPut لإنشاء الـ Controller فقط عند الحاجة إليه لأول مرة
    Get.lazyPut<ExpenseController>(() => ExpenseController());
  }
}
