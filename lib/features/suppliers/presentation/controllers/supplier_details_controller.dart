// File: lib/features/suppliers/presentation/controllers/supplier_details_controller.dart

import 'package:ehab_company_admin/features/suppliers/data/models/supplier_model.dart';
import 'package:ehab_company_admin/features/suppliers/data/models/supplier_transaction_model.dart';
import 'package:ehab_company_admin/features/suppliers/data/repositories/supplier_transactions_repository.dart';
import 'package:ehab_company_admin/features/suppliers/presentation/controllers/supplier_controller.dart';
import 'package:get/get.dart';

class SupplierDetailsController extends GetxController {
  final Rx<SupplierModel> supplier;
  final SupplierTransactionsRepository _repository = SupplierTransactionsRepository();

  final RxList<SupplierTransactionModel> transactions = <SupplierTransactionModel>[].obs;
  final RxBool isLoading = true.obs;

  SupplierDetailsController(SupplierModel initialSupplier) : supplier = initialSupplier.obs;

  @override
  void onInit() {
    super.onInit();
    fetchTransactions();

    // الاستماع للتغييرات في القائمة الرئيسية لتحديث بيانات المورد الحالي لحظيًا
    final mainController = Get.find<SupplierController>();
    ever(mainController.filteredSuppliers, (updatedList) {
      // ابحث عن النسخة المحدثة من المورد الحالي في القائمة الجديدة
      final updatedSupplier = updatedList.firstWhere(
            (s) => s.id == supplier.value.id,
        orElse: () => supplier.value,
      );
      // قم بتحديث كائن المورد التفاعلي، مما يؤدي إلى تحديث الواجهة تلقائيًا
      supplier.value = updatedSupplier;
    });
  }

  Future<void> fetchTransactions() async {
    try {
      isLoading(true);
      final transactionList = await _repository.getTransactionsForSupplier(supplier.value.id!);
      transactions.assignAll(transactionList);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في جلب حركات المورد: $e');
    } finally {
      isLoading(false);
    }
  }

    }
