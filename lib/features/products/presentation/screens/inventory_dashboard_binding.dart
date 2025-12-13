// File: lib/features/products/presentation/screens/inventory_dashboard_binding.dart

import 'package:ehab_company_admin/features/categories/presentation/controllers/category_controller.dart';
import 'package:ehab_company_admin/features/products/presentation/controllers/product_controller.dart';
import 'package:get/get.dart';

import '../../../units/presentation/controllers/unit_controller.dart';

class InventoryDashboardBinding extends Bindings {
  @override
  void dependencies() {
    // استخدام lazyPut لإنشاء الكنترولرات فقط عند أول استخدام لها
    // هذا أفضل من ناحية الأداء واستهلاك الذاكرة
    Get.lazyPut<ProductController>(() => ProductController());
    Get.lazyPut<CategoryController>(() => CategoryController());
    Get.lazyPut<UnitController>(() => UnitController());

  }
}
