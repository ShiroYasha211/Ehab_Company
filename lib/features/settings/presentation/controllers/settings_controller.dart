// File: lib/features/settings/presentation/controllers/settings_controller.dart
import 'package:get/get.dart';
import '../../../../core/services/settings_service.dart';
import '../../models/currency_model.dart';

class SettingsController extends GetxController {
  final SettingsService _settingsService = Get.find<SettingsService>();

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
    // نظراً لأن المتغيرات في السيرفس هي Rx، نحتاج للاستماع لها لتحديث الواجهة
    // GetX Obx في الواجهة سيتكفل بالأمر، ولكن هنا قد نحتاج لبعض المنطق الإضافي مستقبلاً
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
