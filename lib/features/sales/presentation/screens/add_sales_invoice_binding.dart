// File: lib/features/sales/presentation/screens/add_sales_invoice_binding.dart


import 'package:ehab_company_admin/features/sales/presentation/controllers/add_sales_invoice_controller.dart';
import 'package:get/get.dart';

class AddSalesInvoiceBinding extends Bindings {
  @override
  void dependencies() {
    // --- بداية التعديل: الاعتماد على الـ Controllers الموجودة بالفعل ---

    // تأكد من أن ProductController و CustomerController قد تم تهيئتهما
    // في مكان آخر (مثل شاشة المنتجات أو العملاء الرئيسية) قبل الوصول إلى هنا.
    // GetX ذكي بما فيه الكفاية للعثور عليهما.

    // 1. لا تقم بإنشاء Controllers جديدة هنا
    // Get.lazyPut<ProductController>(() => ProductController()); // <-- حذف هذا السطر
    // Get.lazyPut<CustomerController>(() => CustomerController()); // <-- حذف هذا السطر

    // 2. قم فقط بإنشاء الـ Controller الخاص بهذه الشاشة
    Get.lazyPut<AddSalesInvoiceController>(() => AddSalesInvoiceController());

    // --- نهاية التعديل ---
  }
}
