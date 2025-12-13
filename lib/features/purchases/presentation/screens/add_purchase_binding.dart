// File: lib/features/purchases/presentation/screens/add_purchase_binding.dart

import 'package:ehab_company_admin/features/products/presentation/controllers/product_controller.dart';
import 'package:ehab_company_admin/features/purchases/presentation/controllers/add_purchase_controller.dart';
import 'package:ehab_company_admin/features/suppliers/presentation/controllers/supplier_controller.dart';
import 'package:get/get.dart';

class AddPurchaseBinding extends Bindings {
  @override
  void dependencies() {
    // هذا الـ Binding سيقوم بتهيئة الـ Controller الخاص بالفاتورة فقط
    Get.lazyPut<AddPurchaseController>(() => AddPurchaseController());

    // --- الحل الجذري ---
    // نتأكد من أن الـ Controllers الرئيسية موجودة ومحملة بالبيانات
    // هذا الكود سيقوم بإنشاء الـ Controllers إذا لم تكن موجودة وينتظر اكتمالها
    if (!Get.isRegistered<SupplierController>()) {
      Get.put(SupplierController(), permanent: true);
    }
    if (!Get.isRegistered<ProductController>()) {
      Get.put(ProductController(), permanent: true);
    }
  }
}
