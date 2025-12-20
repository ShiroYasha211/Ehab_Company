// File: lib/features/financial_docs/presentation/screens/financial_docs_binding.dart

import 'package:ehab_company_admin/features/customers/presentation/controllers/customer_controller.dart';
import 'package:ehab_company_admin/features/suppliers/presentation/controllers/supplier_controller.dart';
import 'package:get/get.dart';

class FinancialDocsBinding extends Bindings {
  @override
  void dependencies() {
    // تهيئة الـ Controllers اللازمة لقسم الفواتير والسندات
    Get.lazyPut<SupplierController>(() => SupplierController());
    Get.lazyPut<CustomerController>(() => CustomerController());
  }
}
