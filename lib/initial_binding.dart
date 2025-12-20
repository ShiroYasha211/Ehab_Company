// File: lib/initial_binding.dart

import 'package:ehab_company_admin/features/categories/presentation/controllers/category_controller.dart';
import 'package:ehab_company_admin/features/customers/presentation/controllers/customer_controller.dart';
import 'package:ehab_company_admin/features/products/presentation/controllers/product_controller.dart';
import 'package:ehab_company_admin/features/suppliers/presentation/controllers/supplier_controller.dart';
import 'package:ehab_company_admin/features/units/presentation/controllers/unit_controller.dart';
import 'package:get/get.dart';

import 'features/home/presentation/controllers/home_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // استخدم `put` مع `permanent: true` للـ Controllers التي يجب أن تبقى دائمًا في الذاكرة

    // --- 1. قم بإنشاء الـ Controllers التي لا تعتمد على شيء أولاً ---
    Get.put<SupplierController>(SupplierController(), permanent: true);
    Get.put<CategoryController>(CategoryController(), permanent: true);
    Get.put<UnitController>(UnitController(), permanent: true);

    // --- 2. الآن، قم بإنشاء الـ Controllers التي تعتمد على ما سبق ---
    // ProductController يعتمد على CategoryController و UnitController، لذا يجب أن يأتي بعدهما.
    Get.put<ProductController>(ProductController(), permanent: true);
    Get.lazyPut<HomeController>(() => HomeController(), fenix: true);
    Get.lazyPut<CustomerController>(() => CustomerController(), fenix: true);
  }
}
