// File: lib/features/home/presentation/controllers/home_controller.dart

import 'package:ehab_company_admin/features/fund/data/repositories/fund_repository.dart';
import 'package:ehab_company_admin/features/products/data/repositories/product_repository.dart';
import 'package:ehab_company_admin/features/purchases/data/repositories/purchase_repository.dart';
import 'package:ehab_company_admin/features/suppliers/data/repositories/supplier_repository.dart';
import 'package:get/get.dart';

class HomeController extends GetxController { // <-- تم حذف "with WidgetsBindingObserver"
  // Repositories
  final ProductRepository _productRepo = ProductRepository();
  final SupplierRepository _supplierRepo = SupplierRepository();
  final PurchaseRepository _purchaseRepo = PurchaseRepository();
  final FundRepository _fundRepo = FundRepository();

  // Rx Variables for Stats
  final RxDouble totalInventoryValue = 0.0.obs;
  final RxDouble totalSuppliersDebt = 0.0.obs;
  final RxDouble totalPurchasesDue = 0.0.obs;
  final RxDouble currentFundBalance = 0.0.obs;
  final RxInt totalProductsCount = 0.obs;
  final RxBool isLoading = true.obs;

  // في onInit، سنغير الاستدعاء
  @override
  void onInit() {
    super.onInit();
    refreshStats(); // استدعاء الدالة الجديدة
  }

  // تم حذف دالة didChangeAppLifecycleState بالكامل

  Future<void> refreshStats({bool showSnackbar = false}) async {
    isLoading(true); // تفعيل مؤشر التحميل

    try {
      final results = await Future.wait([
        _productRepo.getTotalInventoryValue(),
        _supplierRepo.getTotalBalance(),
        _purchaseRepo.getTotalRemainingAmount(),
        _fundRepo.getFundBalance(1),
        _productRepo.getProductsCount(),
      ]);

      totalInventoryValue.value = results[0] as double;
      totalSuppliersDebt.value = results[1] as double;
      totalPurchasesDue.value = results[2] as double;
      currentFundBalance.value = results[3] as double;
      totalProductsCount.value = results[4] as int;

      // إظهار رسالة نجاح بسيطة في الأسفل (فقط إذا كان التحديث يدوياً)
      if (showSnackbar) {
        Get.rawSnackbar(
          message: 'تم تحديث البيانات بنجاح',
          duration: const Duration(seconds: 1),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.primaryColor.withOpacity(0.7),
        );
      }
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في تحديث إحصائيات لوحة التحكم: $e');
    } finally {
      isLoading(false); // إيقاف مؤشر التحميل
    }
  }


}
