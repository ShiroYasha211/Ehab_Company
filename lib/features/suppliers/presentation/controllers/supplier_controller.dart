// File: lib/features/suppliers/presentation/controllers/supplier_controller.dart

import 'package:ehab_company_admin/features/suppliers/data/models/supplier_model.dart';import 'package:ehab_company_admin/features/suppliers/data/repositories/supplier_repository.dart';
import 'package:flutter/material.dart' hide DateRangePickerDialog;
import 'package:get/get.dart';
import 'package:ehab_company_admin/core/services/supplier_report_service.dart'; // <-- إضافة هذا السطر
import 'package:ehab_company_admin/features/fund/presentation/widgets/date_range_picker_dialog.dart'; // <-- إضافة هذا السطر
import 'package:ehab_company_admin/features/suppliers/data/models/supplier_model.dart';


import '../../data/models/supplier_transaction_model.dart';

enum SupplierFilter { all, hasBalance, noBalance }

class SupplierController extends GetxController {
  final SupplierRepository _repository = SupplierRepository();
  SupplierRepository get repository => _repository;
  final RxList<SupplierModel> suppliers = <SupplierModel>[].obs;
  final RxList<SupplierModel> _allSuppliers = <SupplierModel>[].obs;
  final RxList<SupplierModel> filteredSuppliers = <SupplierModel>[].obs; // قائمة للعرض
  final RxBool isLoading = true.obs;

  // --- بداية الإضافة: متغيرات البحث والفلترة ---
  final RxString searchQuery = ''.obs;
  final Rx<SupplierFilter> currentFilter = SupplierFilter.all.obs;

  // --- نهاية الإضافة ---

  @override
  void onInit() {
    super.onInit();
    fetchAllSuppliers();

    debounce(searchQuery, (_) => _filterSuppliers(),
        time: const Duration(milliseconds: 300));
    ever(currentFilter, (_) => _filterSuppliers());
  }

  Future<void> fetchAllSuppliers() async {
    try {
      isLoading(true);
      final supplierList = await _repository.getAllSuppliers();

      _allSuppliers.assignAll(supplierList);
      _filterSuppliers(); // تطبيق الفلترة بعد جلب البيانات
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في جلب الموردين: $e');
    } finally {
      isLoading(false);
    }
  }

  void _filterSuppliers() {
    List<SupplierModel> _filtered = List.from(_allSuppliers);

    // 1. تطبيق فلتر الرصيد
    if (currentFilter.value == SupplierFilter.hasBalance) {
      _filtered.retainWhere((s) => s.balance > 0);
    } else if (currentFilter.value == SupplierFilter.noBalance) {
      _filtered.retainWhere((s) => s.balance == 0);
    }

    // 2. تطبيق فلتر البحث
    final query = searchQuery.value.toLowerCase().trim();
    if (query.isNotEmpty) {
      _filtered.retainWhere((supplier) {
        final nameMatches = supplier.name.toLowerCase().contains(query);
        final phoneMatches = supplier.phone?.toLowerCase().contains(query) ??
            false;
        return nameMatches || phoneMatches;
      });
    }

    filteredSuppliers.assignAll(_filtered);
  }

  // --- نهاية الإضافة ---
  Future<void> addSupplier({
    required String name,
    String? phone,
    String? address,
    String? email,
    String? company,
    String? commercialRecord,
    String? notes,
  }) async {
    if (name.isEmpty) {
      Get.snackbar('خطأ', 'اسم المورد لا يمكن أن يكون فارغًا');
      return;
    }
    final newSupplier = SupplierModel(
      name: name,
      phone: phone,
      address: address,
      email: email,
      company: company,
      commercialRecord: commercialRecord,
      notes: notes,
      createdAt: DateTime.now(),
    );
    try {
      await _repository.addSupplier(newSupplier);
      await fetchAllSuppliers(); // تحديث القائمة
      Get.back(); // إغلاق شاشة الإضافة
      Get.snackbar(
          'نجاح', 'تمت إضافة المورد بنجاح', backgroundColor: Colors.green,
          colorText: Colors.white);
    } catch (e) {
      Get.snackbar(
          'خطأ', 'فشل في إضافة المورد: $e', backgroundColor: Colors.red,
          colorText: Colors.white);
    }
  }

  // --- نهاية التعديل ---

  Future<void> executeSupplierTransaction({
    required SupplierModel supplier,
    required SupplierTransactionType type,
    required double amount,
    required DateTime transactionDate,
    required bool affectsFund,
    String? notes,
  }) async {
    // --- بداية الحل الجديد والمُحسّن ---

    // 1. التحقق فقط في حالة "الدفعة النقدية"
    if (type == SupplierTransactionType.PAYMENT) {
      // 2. إذا كان رصيد المورد صفرًا أو مدينًا (أقل من صفر)
      if (supplier.balance <= 0) {
        Get.snackbar(
          'لا يمكن إتمام الدفعة',
          'رصيد المورد الحالي (${supplier
              .balance} ريال) لا يسمح بدفعات نقدية له.',
          backgroundColor: Colors.orange.shade800,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
        return; // إيقاف العملية
      }

      // 3. إذا كان مبلغ الدفعة أكبر من الرصيد الدائن المستحق للمورد
      if (amount > supplier.balance) {
        Get.snackbar(
          'مبلغ غير صحيح',
          'مبلغ الدفعة (${amount} ريال) أكبر من الرصيد المستحق للمورد (${supplier
              .balance} ريال).',
          backgroundColor: Colors.orange.shade800,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
        return; // إيقاف العملية
      }
    }
    // --- نهاية الحل الجديد والمُحسّن ---
    try {
      final newTransaction = SupplierTransactionModel(
        supplierId: supplier.id!,
        type: type,
        amount: amount,
        transactionDate: transactionDate,
        affectsFund: affectsFund,
        notes: notes,
      );

      final transactionId = await _repository.addSupplierTransaction(
          newTransaction);

      // تحديث قائمة الموردين لجلب الأرصدة الجديدة
      await fetchAllSuppliers();

      Get.back(); // العودة من شاشة الإضافة

      Get.snackbar(
        'نجاح العملية',
        'تم تسجيل الحركة المالية بنجاح. رقم السند: $transactionId',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'فشل العملية',
        'حدث خطأ غير متوقع: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

// --- نهاية الإضافة ---

  Future<void> updateSupplier({
    required int id,
    required DateTime createdAt,
    required double balance,
    required String name,
    String? phone,
    String? address,
    String? company,
    String? commercialRecord,
    String? notes,
  }) async {
    if (name.isEmpty) {
      Get.snackbar('خطأ', 'اسم المورد لا يمكن أن يكون فارغًا');
      return;
    }

    final updatedSupplier = SupplierModel(
      id: id,
      createdAt: createdAt,
      // الحفاظ على تاريخ الإنشاء الأصلي
      balance: balance,
      // الحفاظ على الرصيد الأصلي
      name: name,
      phone: phone,
      address: address,
      company: company,
      commercialRecord: commercialRecord,
      notes: notes,
    );

    try {
      await _repository.updateSupplier(updatedSupplier);
      await fetchAllSuppliers(); // تحديث القائمة الرئيسية
      Get.back(); // العودة من شاشة التعديل

      Get.snackbar(
        'نجاح',
        'تم تعديل بيانات المورد بنجاح.',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في تعديل المورد: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  // --- بداية الإضافة: دالة لمعالجة فاتورة الشراء ---
  /// تستدعى هذه الدالة بعد حفظ فاتورة شراء بنجاح
  /// لتقوم بتحديث رصيد المورد في كشف الحساب
  Future<void> handlePurchaseInvoiceCreation({
    required int supplierId,
    required int invoiceId,
    required double remainingAmount,
    required DateTime invoiceDate,
  }) async {
    if (remainingAmount <= 0) {
      // إذا لم يكن هناك مبلغ متبق، فقط قم بتحديث القائمة
      await fetchAllSuppliers();
      return;
    }
    // إذا كان هناك مبلغ متبق، قم بإنشاء حركة في كشف الحساب
    final transaction = SupplierTransactionModel(
      supplierId: supplierId,
      type: SupplierTransactionType.PURCHASE,
      // النوع الجديد
      amount: remainingAmount,
      transactionDate: invoiceDate,
      affectsFund: false,
      notes: 'فاتورة شراء آجلة رقم: $invoiceId',
    );

    // هنا نستخدم repository الخاص بالموردين لإضافة الحركة وتحديث الرصيد
    await _repository.addSupplierTransaction(transaction);

    // بعد
    await fetchAllSuppliers();
  }

  // --- بداية التعديل: تعديل دالة الحذف بالكامل ---

  /// يبدأ عملية حذف المورد مع التحقق من العلاقات المرتبطة به
  Future<void> deleteSupplier(SupplierModel supplier) async {
    // 1. التحقق مما إذا كان للمورد أي علاقات (فواتير أو سندات)
    final bool hasRelations = await _repository.checkSupplierHasRelations(
        supplier.id!);

    if (hasRelations) {
      // 2. إذا وجدت علاقات، اعرض ديالوج التحذير الشديد
      _showStrongWarningDialog(supplier);
    } else {
      // 3. إذا لم توجد علاقات، اعرض ديالوج الحذف العادي
      _showSimpleDeleteDialog(supplier);
    }
  }

  /// ديالوج الحذف العادي (للموردين الذين ليس لديهم معاملات)
  void _showSimpleDeleteDialog(SupplierModel supplier) {
    Get.defaultDialog(
        title: 'تأكيد الحذف',
        middleText: 'هل أنت متأكد من رغبتك في حذف المورد "${supplier.name}"؟',
        textConfirm: 'حذف',
        textCancel: 'إلغاء',
        confirmTextColor: Colors.white,
        onConfirm
        : () {
          Get.back(); // أغلق الديالوج
          _performDelete(supplier.id!);
        },
    );
  }

  /// ديالوج التحذير الشديد (للموردين الذين لديهم معاملات)
  void _showStrongWarningDialog(SupplierModel supplier) {
    Get.defaultDialog(
        title: '⚠️ تحذيرخطير!',
        titleStyle: TextStyle(
            color: Colors.red.shade700, fontWeight: FontWeight.bold),
        content: const Column(
          children: [ Text(
          'هذا المورد لديه فواتير أو حركات مالية مسجلة.',
          textAlign: TextAlign.center,
        ), SizedBox(height: 16),
        Text(
          'حذف المورد سيؤدي إلى فقدان ربط هذه الفواتير والسندات به، وهو إجراء غير قابل للتراجع. هل أنت متأكد تمامًا من رغبتك في المتابعة؟',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.red),
        ),
          ],
        ),
        confirm: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () {
            Get.back(); // أغلق الديالوج
            _performDelete(supplier.id!);
          },
          child: const Text('نعم، أحذف المورد على مسؤوليتي'),
        ),
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: const Text('إلغاء'),
      ),
    );
  }

  /// دالة مساعدة لتنفيذ الحذف الفعلي بعد التأكيد
  Future<void> _performDelete(int id) async {
    try {
      await _repository.deleteSupplier(id);
      _allSuppliers.removeWhere((supplier) => supplier.id == id);
      _filterSuppliers(); // تحديث الواجهة
      Get.snackbar(
          'نجاح',
          'تم حذف المورد بنجاح.',
          backgroundColor: Colors.blue, colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في حذف المورد: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  void printSupplierStatement(SupplierModel supplier) {
    // 1. عرض ديالوج اختيار فترة التقرير
    Get.dialog(
      DateRangePickerDialog(
        onConfirm: (from, to) async {
          // 2. بعد أن يؤكد المستخدم، قم بإنشاء التقرير
          try {
            Get.dialog(
              const Center(child: CircularProgressIndicator()),
              barrierDismissible: false,
            );

            // 3. جلب بيانات كشف الحساب (الرصيد الافتتاحي والحركات)
            final reportData = await _repository.getSupplierStatementData(
              supplierId: supplier.id!,
              from: from,
              to: to,
            );

            if (Get.isDialogOpen!) Get.back(); // إغلاق مؤشر التحميل

            // 4. طباعة التقرير باستخدام البيانات التي تم جلبها
            await SupplierReportService.printSupplierStatement(
              supplier: supplier, // تمرير بيانات المورد
              openingBalance: reportData['openingBalance'], // تمرير الرصيد الافتتاحي
              transactions: reportData['transactions'], // تمرير قائمة الحركات
            );
          } catch (e) {
            if (Get.isDialogOpen!) Get.back(); // إغلاق مؤشر التحميل في حال حدوث خطأ
            Get.snackbar('خطأ', 'فشل في إنشاء كشف الحساب: $e');
          }
        },
      ),
    );
  }
// --- نهاية التعديل ---
}
