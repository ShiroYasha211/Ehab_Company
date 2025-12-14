// File: lib/features/sales/presentation/screens/add_sales_invoice_binding.dart

import 'package:ehab_company_admin/features/customers/presentation/controllers/customer_controller.dart';
import 'package:ehab_company_admin/features/sales/presentation/controllers/add_sales_invoice_controller.dart';
import 'package:get/get.dart';

import '../../../products/presentation/controllers/product_controller.dart';

class AddSalesInvoiceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AddSalesInvoiceController>(() => AddSalesInvoiceController());

    if (!Get.isRegistered<CustomerController>()) {
      Get.put(CustomerController(), permanent: true);
    }
    if (!Get.isRegistered<ProductController>()) {
      Get.put(ProductController(), permanent: true);
    }
  }
}
