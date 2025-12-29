// File: lib/core/services/settings_service.dart
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// سيرفس لإدارة وحفظ إعدادات التطبيق بشكل دائم
class SettingsService extends GetxService {
  late SharedPreferences _prefs;

  // --- مفاتيح التخزين ---
  static const String _primaryCurrencyNameKey = 'primaryCurrencyName';
  static const String _primaryCurrencySymbolKey = 'primaryCurrencySymbol';
  static const String _localCurrencyNameKey = 'localCurrencyName';
  static const String _localCurrencySymbolKey = 'localCurrencySymbol';
  static const String _exchangeRateKey = 'exchangeRate';
  static const String _showBothCurrenciesInInvoiceKey = 'showBothCurrencies';

  // --- متغيرات الحالة التفاعلية (GetX) ---
  final RxString primaryCurrencyName = 'ريال سعودي'.obs;
  final RxString primaryCurrencySymbol = 'ر.س'.obs;
  final RxString localCurrencyName = 'ريال يمني'.obs;
  final RxString localCurrencySymbol = 'ر.ي'.obs;

  // --- بداية التعديل: جعل سعر الصرف يقبل قيمة null ---
  final Rx<double?> exchangeRate = Rx<double?>(null);
  // --- نهاية التعديل ---

  final RxBool showBothCurrenciesInInvoice = true.obs;

  /// دالة لتهيئة السيرفس وجلب الإعدادات المحفوظة
  Future<SettingsService> init() async {
    _prefs = await SharedPreferences.getInstance();

    primaryCurrencyName.value = _prefs.getString(_primaryCurrencyNameKey) ?? 'ريال سعودي';
    primaryCurrencySymbol.value = _prefs.getString(_primaryCurrencySymbolKey) ?? 'ر.س';
    localCurrencyName.value = _prefs.getString(_localCurrencyNameKey) ?? 'ريال يمني';
    localCurrencySymbol.value = _prefs.getString(_localCurrencySymbolKey) ?? 'ر.ي';

    // --- بداية التعديل: قراءة سعر الصرف الذي قد يكون null ---
    // إذا لم نجد قيمة، ستبقى null، وهذا هو المطلوب
    exchangeRate.value = _prefs.getDouble(_exchangeRateKey);
    // --- نهاية التعديل ---

    showBothCurrenciesInInvoice.value = _prefs.getBool(_showBothCurrenciesInInvoiceKey) ?? true;

    // لضمان تناسق البيانات عند بدء التشغيل
    if (areCurrenciesTheSame) {
      exchangeRate.value = 1.0;
    }

    return this;
  }

  // --- دوال لتحديث وحفظ الإعدادات ---

  Future<void> updatePrimaryCurrency({required String name, required String symbol}) async {
    await _prefs.setString(_primaryCurrencyNameKey, name);
    await _prefs.setString(_primaryCurrencySymbolKey, symbol);
    primaryCurrencyName.value = name;
    primaryCurrencySymbol.value = symbol;
  }

  Future<void> updateLocalCurrency({required String name, required String symbol}) async {
    await _prefs.setString(_localCurrencyNameKey, name);
    await _prefs.setString(_localCurrencySymbolKey, symbol);
    localCurrencyName.value = name;
    localCurrencySymbol.value = symbol;
  }

  // --- بداية التعديل: تحديث دالة حفظ سعر الصرف ---
  Future<void> updateExchangeRate(double? rate) async {
    if (rate != null) {
      await _prefs.setDouble(_exchangeRateKey, rate);
    } else {
      // إذا كانت القيمة null، قم بإزالتها من التخزين
      await _prefs.remove(_exchangeRateKey);
    }
    exchangeRate.value = rate;
  }
  // --- نهاية التعديل ---

  Future<void> updateShowBothCurrencies(bool show) async {
    await _prefs.setBool(_showBothCurrenciesInInvoiceKey, show);
    showBothCurrenciesInInvoice.value = show;
  }

  /// دالة للتحقق مما إذا كانت العملة الأساسية هي نفسها المحلية
  bool get areCurrenciesTheSame {
    return primaryCurrencyName.value == localCurrencyName.value && primaryCurrencySymbol.value == localCurrencySymbol.value;
  }
}
