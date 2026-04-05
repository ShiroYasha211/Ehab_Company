import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ehab_company_admin/features/warehouses/data/models/warehouse_model.dart';
import 'package:ehab_company_admin/features/warehouses/data/repositories/settlement_repository.dart';
import 'package:ehab_company_admin/features/warehouses/presentation/controllers/warehouse_controller.dart';

class SettlementController extends GetxController {
  final SettlementRepository _repository = SettlementRepository();
  final WarehouseController _warehouseController = Get.find<WarehouseController>();

  // حالة الشاشة الحالية
  final RxList<Map<String, dynamic>> currentStock = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  
  // بيانات التسوية الحالية
  final Rx<WarehouseModel?> selectedWarehouse = Rx<WarehouseModel?>(null);
  
  // مصفوفة العناصر المعدلة يدوياً
  // { 'productId': int, 'sold': double, 'returned': double, ...financials }
  final RxMap<int, Map<String, dynamic>> entryData = <int, Map<String, dynamic>>{}.obs;

  Future<void> selectWarehouse(WarehouseModel warehouse) async {
    selectedWarehouse.value = warehouse;
    await fetchStock(warehouse.id!);
  }

  Future<void> fetchStock(int warehouseId) async {
    try {
      isLoading(true);
      final stock = await _warehouseController.getWarehouseStock(warehouseId);
      currentStock.assignAll(stock);
      
      // تهيئة بيانات الإدخال
      entryData.clear();
      for (var item in stock) {
        entryData[item['productId']] = {
          'sold': 0.0,
          'returned': 0.0,
          'cashAmount': 0.0,
          'cashFundId': null,
          'bankAmount': 0.0,
          'bankFundId': null,
          'bankDetails': '',
          'transferAmount': 0.0,
          'transferFundId': null,
          'transferDetails': '',
          'creditAmount': 0.0,
          'creditTarget': 'rep', // 'rep' or 'customer'
          'customerId': null,
        };
      }
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في جلب الأرصدة: $e', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading(false);
    }
  }

  void updateEntry(int productId, {
    double? sold, 
    double? returned,
    double? cashAmount,
    int? cashFundId,
    double? bankAmount,
    int? bankFundId,
    String? bankDetails,
    double? transferAmount,
    int? transferFundId,
    String? transferDetails,
    double? creditAmount,
    String? creditTarget,
    int? customerId,
  }) {
    if (entryData.containsKey(productId)) {
      final data = entryData[productId]!;
      if (sold != null) data['sold'] = sold;
      if (returned != null) data['returned'] = returned;
      if (cashAmount != null) data['cashAmount'] = cashAmount;
      if (cashFundId != null) data['cashFundId'] = cashFundId;
      if (bankAmount != null) data['bankAmount'] = bankAmount;
      if (bankFundId != null) data['bankFundId'] = bankFundId;
      if (bankDetails != null) data['bankDetails'] = bankDetails;
      if (transferAmount != null) data['transferAmount'] = transferAmount;
      if (transferFundId != null) data['transferFundId'] = transferFundId;
      if (transferDetails != null) data['transferDetails'] = transferDetails;
      if (creditAmount != null) data['creditAmount'] = creditAmount;
      if (creditTarget != null) data['creditTarget'] = creditTarget;
      if (customerId != null) data['customerId'] = customerId;
      
      entryData.refresh();
    }
  }

  /// التحقق من أن مجموع المباع والمرتجع لا يتجاوز العهدة الأصلية لصنف معين
  bool isItemValid(int productId) {
    if (!entryData.containsKey(productId)) return true;
    final item = currentStock.firstWhereOrNull((s) => s['productId'] == productId);
    if (item == null) return true;
    
    final initial = (item['quantity'] as num).toDouble();
    final entry = entryData[productId]!;
    return (entry['sold']! as double) + (entry['returned']! as double) <= (initial + 0.0001);
  }

  /// التحقق من أن المبالغ المحصلة والآجلة تغطي قيمة المبيعات لهذا المنتج
  bool isItemPaymentComplete(int productId) {
    if (!entryData.containsKey(productId)) return true;
    final item = currentStock.firstWhereOrNull((s) => s['productId'] == productId);
    if (item == null) return true;
    
    final entry = entryData[productId]!;
    final sold = (entry['sold'] as double);
    if (sold <= 0) return true;

    final salePrice = (item['salePrice'] as num).toDouble();
    final expected = sold * salePrice;
    
    final totalPaid = (entry['cashAmount'] as double) + 
                      (entry['bankAmount'] as double) + 
                      (entry['transferAmount'] as double) + 
                      (entry['creditAmount'] as double);
    
    // نسمح بفرق بسيط جداً ناتج عن التقريب
    return (totalPaid - expected).abs() < 0.01;
  }

  /// حساب المتبقي المطلوب تحصيله لصنف معين
  double getItemRemainingToPay(int productId) {
    if (!entryData.containsKey(productId)) return 0;
    final item = currentStock.firstWhereOrNull((s) => s['productId'] == productId);
    if (item == null) return 0;
    
    final entry = entryData[productId]!;
    final expected = (entry['sold'] as double) * (item['salePrice'] as num).toDouble();
    final totalPaid = (entry['cashAmount'] as double) + 
                      (entry['bankAmount'] as double) + 
                      (entry['transferAmount'] as double) + 
                      (entry['creditAmount'] as double);
    
    return expected - totalPaid;
  }

  /// التحقق الشامل من صحة كافة مدخلات الأصناف واكتمال تحصيلها
  bool get areAllItemsValid {
    for (var productId in entryData.keys) {
      if (!isItemValid(productId)) return false;
      if (!isItemPaymentComplete(productId)) return false;
    }
    return true;
  }

  // حسابات الإجماليات اللحظية المجمعة
  double get totalSalesValue {
    double total = 0;
    for (var item in currentStock) {
      final pid = item['productId'];
      final sold = entryData[pid]?['sold'] ?? 0.0;
      total += sold * (item['salePrice'] as num).toDouble();
    }
    return total;
  }

  double get totalReturnedValue {
    double total = 0;
    for (var item in currentStock) {
      final pid = item['productId'];
      final returned = entryData[pid]?['returned'] ?? 0.0;
      total += returned * (item['salePrice'] as num).toDouble();
    }
    return total;
  }

  double get totalCashAmount => entryData.values.fold(0.0, (sum, item) => sum + (item['cashAmount'] as double));
  double get totalBankAmount => entryData.values.fold(0.0, (sum, item) => sum + (item['bankAmount'] as double));
  double get totalTransferAmount => entryData.values.fold(0.0, (sum, item) => sum + (item['transferAmount'] as double));
  double get totalCreditAmount => entryData.values.fold(0.0, (sum, item) => sum + (item['creditAmount'] as double));

  Future<void> submitSettlement({
    required double totalCredit,
    required double amountPaid,
    String? paymentMethod,
    int? fundId,
    bool isStockCleared = false,
    bool isCreditToCustomers = false,
    String? notes,
  }) async {
    if (selectedWarehouse.value == null) return;

    try {
      isLoading(true);
      
      List<SettlementItemInput> items = [];
      for (var item in currentStock) {
        final pid = item['productId'];
        final entry = entryData[pid]!;
        
        // التحقق من منطقية الأرقام
        final initial = (item['quantity'] as num).toDouble();
        if (!isItemValid(pid)) {
          throw Exception('الكمية المدخلة للمنتج ${item['productName']} تتجاوز المتوفر في العهدة');
        }

        items.add(SettlementItemInput(
          productId: pid,
          initialQty: initial,
          initialQtyInBaseUnit: initial, // هنا نفترض الإدخال بالوحدة الكبرى حالياً
          soldQty: (entry['sold'] as double),
          soldQtyInBaseUnit: (entry['sold'] as double),
          returnedQty: (entry['returned'] as double),
          returnedQtyInBaseUnit: (entry['returned'] as double),
          salePrice: (item['salePrice'] as num).toDouble(),
          unitId: item['unitId'],
          cashAmount: (entry['cashAmount'] as double),
          cashFundId: entry['cashFundId'],
          bankAmount: (entry['bankAmount'] as double),
          bankFundId: entry['bankFundId'],
          bankDetails: entry['bankDetails'],
          transferAmount: (entry['transferAmount'] as double),
          transferFundId: entry['transferFundId'],
          transferDetails: entry['transferDetails'],
          creditAmount: (entry['creditAmount'] as double),
          creditTarget: entry['creditTarget'],
          customerId: entry['customerId'],
        ));
      }

      await _repository.processSettlement(
        warehouseId: selectedWarehouse.value!.id!,
        totalSales: totalSalesValue,
        totalReturned: totalReturnedValue,
        totalCredit: totalCreditAmount, // استخدام الإجمالي المحسوب من الأصناف
        amountPaid: totalCashAmount + totalBankAmount + totalTransferAmount, // المبالغ المحصلة فعلياً
        deficit: 0,
        settlementDate: DateTime.now(),
        notes: notes,
        paymentMethod: 'multiple', // تم تغييرها لتعدد طرق الدفع
        fundId: null, // لم يعد هناك صندوق واحد رئيسي
        isStockCleared: isStockCleared,
        isCreditToCustomers: true, // نفترض التفعيل إذا وجد تحصيل للعملاء
        items: items,
      );

      Get.back(); // العودة من شاشة التسوية
      Get.snackbar('نجاح', 'تمت عملية التسوية بنجاح', backgroundColor: Colors.green, colorText: Colors.white);
      
      // تحديث بيانات المخازن
      _warehouseController.fetchAllWarehouses();
      
    } catch (e) {
      Get.snackbar('خطأ', 'فشل تنفيذ التسوية: $e', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading(false);
    }
  }
}
