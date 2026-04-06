// File: lib/features/activities/presentation/controllers/operations_controller.dart

import 'package:flutter/material.dart';
import '../../data/models/operation_model.dart';
import '../../data/repositories/operation_repository.dart';
import '../widgets/operation_detail_bottom_sheet.dart';
import 'package:get/get.dart';

class OperationsController extends GetxController {
  final OperationRepository _repository = OperationRepository();

  final RxList<OperationModel> operations = <OperationModel>[].obs;
  final RxBool isLoading = false.obs;

  // فلاتر البحث
  final Rx<DateTime?> fromDate = Rx<DateTime?>(null);
  final Rx<DateTime?> toDate = Rx<DateTime?>(null);
  final RxList<OperationType> selectedTypes = <OperationType>[].obs;
  final RxString selectedEmployee = "".obs;
  final Rx<double?> minAmount = Rx<double?>(null);
  final Rx<double?> maxAmount = Rx<double?>(null);

  // قائمة الموظفين المتاحة للفلترة
  final RxList<String> availableEmployees = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    // جعل الفترة الزمنية مفتوحة افتراضياً
    fromDate.value = null;
    toDate.value = null;
    
    loadEmployees();
    loadOperations();
  }

  Future<void> loadEmployees() async {
    availableEmployees.value = await _repository.getUniqueEmployees();
  }

  Future<void> loadOperations() async {
    isLoading.value = true;
    try {
      final list = await _repository.getUnifiedOperations(
        from: fromDate.value,
        to: toDate.value,
        types: selectedTypes.isEmpty ? null : selectedTypes,
        employeeName: selectedEmployee.value.isEmpty ? null : selectedEmployee.value,
        minAmount: minAmount.value,
        maxAmount: maxAmount.value,
      );
      operations.assignAll(list);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل تحميل العمليات: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void resetFilters() {
    fromDate.value = null;
    toDate.value = null;
    selectedTypes.clear();
    selectedEmployee.value = "";
    minAmount.value = null;
    maxAmount.value = null;
    loadOperations();
  }

  void toggleType(OperationType type) {
    if (selectedTypes.contains(type)) {
      selectedTypes.remove(type);
    } else {
      selectedTypes.add(type);
    }
  }

  bool isAnyFilterApplied() {
    return selectedTypes.isNotEmpty || 
           selectedEmployee.value.isNotEmpty || 
           minAmount.value != null || 
           maxAmount.value != null;
  }

  /// فتح نافذة تفاصيل العملية
  Future<void> showOperationDetails(OperationModel operation) async {
    isLoading.value = true;
    try {
      final details = await _repository.getOperationFullDetails(operation);
      Get.bottomSheet(
        OperationDetailBottomSheet(details: details),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
      );
    } catch (e) {
      Get.snackbar('خطأ', 'فشل جلب التفاصيل: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
