// File: lib/features/settings/presentation/controllers/settings_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/services/settings_service.dart';
import '../../models/currency_model.dart';

class SettingsController extends GetxController {
  final SettingsService _settingsService = Get.find<SettingsService>();
  
  // كنترولر خاص بحقل إدخال سعر الصرف لمنع إعادة الإنشاء وضمان سلاسة الإدخال
  late final TextEditingController exchangeRateController;

  // --- Getters لربط البيانات بالواجهة مباشرة ---

  /// العملة الأساسية
  CurrencyModel get primaryCurrency => _settingsService.primaryCurrency.value;

  /// هل العملة المحلية هي نفسها الأساسية؟
  bool get isLocalSameAsPrimary => _settingsService.isLocalSameAsPrimary.value;

  /// العملة المحلية
  CurrencyModel get localCurrency => _settingsService.localCurrency.value;

  /// سعر الصرف
  double get exchangeRate => _settingsService.exchangeRate.value;

  /// إظهار العملتين في الفاتورة؟
  bool get showBothCurrenciesInInvoice =>
      _settingsService.showBothCurrenciesInInvoice.value;

  @override
  void onInit() {
    super.onInit();
    // تهيئة كنترولر سعر الصرف بالقيمة الحالية مع إزالة الأصفار الزائدة بعد العلامة العشرية
    exchangeRateController = TextEditingController(
      text: _formatRate(exchangeRate),
    );
  }

  @override
  void onClose() {
    exchangeRateController.dispose();
    super.onClose();
  }

  /// دالة مساعدة لتنسيق الرقم وإزالة .0 إذا كان صحيحاً
  String _formatRate(double rate) {
    if (rate == rate.toInt()) {
      return rate.toInt().toString();
    }
    return rate.toString();
  }

  // --- دوال التحديث (Actions) ---

  /// تغيير العملة الأساسية
  Future<void> updatePrimaryCurrency(CurrencyModel currency) async {
    await _settingsService.setPrimaryCurrency(currency);
    update(); // لتحديث أي واجهة تستخدم GetBuilder بدلاً من Obx
  }

  /// تبديل خيار "العملة المحلية نفس الأساسية"
  Future<void> toggleLocalSameAsPrimary(bool value) async {
    await _settingsService.toggleLocalSameAsPrimary(value);
    // عند التبديل، قد نحتاج لتحديث نص الكنترولر للقيمة الجديدة (1.0 غالباً)
    if (value) {
      exchangeRateController.text = _formatRate(1.0);
    }
    update();
  }

  /// تغيير العملة المحلية
  Future<void> updateLocalCurrency(CurrencyModel currency) async {
    await _settingsService.setLocalCurrency(currency);
    update();
  }

  /// تحديث سعر الصرف
  Future<void> updateExchangeRate(String value) async {
    // نتأكد من تحويل النص لرقم، وفي حال الخطأ نستخدم 1.0 أو القيمة السابقة
    double? rate = double.tryParse(value);
    if (rate != null) {
      await _settingsService.setExchangeRate(rate);
      update();
    }
  }

  /// تبديل خيار عرض العملتين
  Future<void> toggleShowBothCurrencies(bool value) async {
    await _settingsService.setShowBothCurrencies(value);
    update();
  }
}
