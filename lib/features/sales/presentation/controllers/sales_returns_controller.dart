// File: lib/features/sales/presentation/controllers/sales_returns_controller.dart

import 'package:ehab_company_admin/features/customers/data/models/customer_model.dart';
import 'package:ehab_company_admin/features/customers/presentation/controllers/customer_controller.dart';
import 'package:ehab_company_admin/features/sales/data/repositories/sales_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SalesReturnsController extends GetxController {
  final SalesRepository _repository = SalesRepository();
  final CustomerController customerController = Get.find<CustomerController>();

  final RxList<Map<String, dynamic>> returns = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = true.obs;
  final RxInt touchedIndex = (-1).obs; // مؤشر الجزء المختار في الرسم البياني

  // فلاتر البحث المتقدمة
  final Rx<DateTime?> startDate = Rx<DateTime?>(null);
  final Rx<DateTime?> endDate = Rx<DateTime?>(null);
  final Rx<CustomerModel?> selectedCustomer = Rx<CustomerModel?>(null);
  final RxString searchQuery = ''.obs;
  final TextEditingController searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    // مراقبة التغييرات في الفلاتر لتحديث القائمة تلقائياً
    ever(startDate, (_) => fetchReturns());
    ever(endDate, (_) => fetchReturns());
    ever(selectedCustomer, (_) => fetchReturns());
    debounce(searchQuery, (_) => fetchReturns(), time: const Duration(milliseconds: 500));
    
    fetchReturns();
  }

  Future<void> fetchReturns() async {
    try {
      isLoading(true);
      final data = await _repository.getAllReturns(
        startDate: startDate.value,
        endDate: endDate.value,
        customerId: selectedCustomer.value?.id,
        searchQuery: searchQuery.value,
      );
      returns.assignAll(data);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في جلب سجل المرتجعات: $e');
    } finally {
      isLoading(false);
    }
  }

  void clearFilters() {
    startDate.value = null;
    endDate.value = null;
    selectedCustomer.value = null;
    searchQuery.value = '';
    searchController.clear();
  }

  // --- دوال التحليل البياني (Phase 2 Insights) ---

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

  /// قائمة كبار المرتجعين (Top 5)
  List<Map<String, dynamic>> get topReturners {
    final Map<String, double> customerValue = {};
    final Map<String, String> customerNames = {};

    for (var item in returns) {
      final name = item['customerName'] ?? 'عميل غير محدد';
      final id = item['customerId'].toString();
      final value = (item['totalReturnedValue'] as num).toDouble();
      
      customerValue[id] = (customerValue[id] ?? 0.0) + value;
      customerNames[id] = name;
    }

    final sortedIds = customerValue.keys.toList()
      ..sort((a, b) => customerValue[b]!.compareTo(customerValue[a]!));

    return sortedIds.take(5).map((id) => {
      'name': customerNames[id],
      'value': customerValue[id],
    }).toList();
  }

  // إحصائيات تحليلية (Insights)
  double get totalReturnsValue {
    return returns.fold(0.0, (sum, item) => sum + (item['totalReturnedValue'] as num).toDouble());
  }

  int get returnsCount => returns.length;

  double get averageReturnPrice {
    if (returns.isEmpty) return 0.0;
    return totalReturnsValue / returns.length;
  }
}
