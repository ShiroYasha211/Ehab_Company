// File: lib/features/purchases/presentation/controllers/purchase_returns_controller.dart

import 'package:ehab_company_admin/features/suppliers/data/models/supplier_model.dart';
import 'package:ehab_company_admin/features/suppliers/presentation/controllers/supplier_controller.dart';
import 'package:ehab_company_admin/features/purchases/data/repositories/purchase_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PurchaseReturnsController extends GetxController {
  final PurchaseRepository _repository = PurchaseRepository();
  final SupplierController supplierController = Get.find<SupplierController>();

  final RxList<Map<String, dynamic>> returns = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = true.obs;
  final RxInt touchedIndex = (-1).obs; 

  // فلاتر البحث المتقدمة
  final Rx<DateTime?> startDate = Rx<DateTime?>(null);
  final Rx<DateTime?> endDate = Rx<DateTime?>(null);
  final Rx<SupplierModel?> selectedSupplier = Rx<SupplierModel?>(null);
  final RxString searchQuery = ''.obs;
  final TextEditingController searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    // مراقبة التغييرات في الفلاتر لتحديث القائمة تلقائياً
    ever(startDate, (_) => fetchReturns());
    ever(endDate, (_) => fetchReturns());
    ever(selectedSupplier, (_) => fetchReturns());
    debounce(searchQuery, (_) => fetchReturns(), time: const Duration(milliseconds: 500));
    
    fetchReturns();
  }

  Future<void> fetchReturns() async {
    try {
      isLoading(true);
      final data = await _repository.getAllReturns(
        startDate: startDate.value,
        endDate: endDate.value,
        supplierId: selectedSupplier.value?.id,
        searchQuery: searchQuery.value,
      );
      returns.assignAll(data);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في جلب سجل مرتجعات المشتريات: $e');
    } finally {
      isLoading(false);
    }
  }

  void clearFilters() {
    startDate.value = null;
    endDate.value = null;
    selectedSupplier.value = null;
    searchQuery.value = '';
    searchController.clear();
  }

  // --- دوال التحليل البياني ---

  /// تجميع المرتجعات حسب التاريخ (للرسم البياني الخطي)
  Map<String, double> get returnsDailyTrend {
    final Map<String, double> trend = {};
    for (var item in returns) {
      final dateStr = item['returnDate'].toString().split(' ')[0]; // YYYY-MM-DD
      final value = (item['totalReturnedValue'] as num).toDouble();
      trend[dateStr] = (trend[dateStr] ?? 0.0) + value;
    }
    // ترتيب الأيام زمنياً
    final sortedKeys = trend.keys.toList()..sort();
    return {for (var k in sortedKeys) k: trend[k]!};
  }

  /// تجميع المرتجعات حسب السبب (للرسم البياني الدائري)
  Map<String, double> get returnsByReason {
    final Map<String, double> reasons = {};
    for (var item in returns) {
      final reason = item['reason']?.toString() ?? 'إرجاع عام';
      final value = (item['totalReturnedValue'] as num).toDouble();
      reasons[reason] = (reasons[reason] ?? 0.0) + value;
    }
    return reasons;
  }

  /// قائمة كبار الموردين المرتجعين (Top 5)
  List<Map<String, dynamic>> get topReturners {
    final Map<String, double> supplierValue = {};
    final Map<String, String> supplierNames = {};

    for (var item in returns) {
      final name = item['supplierName'] ?? 'مورد غير محدد';
      final id = item['supplierId'].toString();
      final value = (item['totalReturnedValue'] as num).toDouble();
      
      supplierValue[id] = (supplierValue[id] ?? 0.0) + value;
      supplierNames[id] = name;
    }

    final sortedIds = supplierValue.keys.toList()
      ..sort((a, b) => supplierValue[b]!.compareTo(supplierValue[a]!));

    return sortedIds.take(5).map((id) => {
      'name': supplierNames[id],
      'value': supplierValue[id],
    }).toList();
  }

  // إحصائيات تحليلية
  double get totalReturnsValue {
    return returns.fold(0.0, (sum, item) => sum + (item['totalReturnedValue'] as num).toDouble());
  }

  int get returnsCount => returns.length;

  double get averageReturnPrice {
    if (returns.isEmpty) return 0.0;
    return totalReturnsValue / returns.length;
  }
}
