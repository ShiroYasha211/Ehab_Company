// File: lib/core/services/settings_service.dart
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/settings/models/currency_model.dart';

class SettingsService extends GetxService {
  late SharedPreferences _prefs;

  // --- مفاتيح التخزين (Keys) ---
  static const String _primaryCurrencyCodeKey = 'primary_currency_code';
  static const String _localCurrencyCodeKey = 'local_currency_code';
  static const String _isLocalSameAsPrimaryKey = 'is_local_same_as_primary';
  static const String _exchangeRateKey = 'exchange_rate';
  static const String _showBothCurrenciesKey = 'show_both_currencies';
  static const String _companyNameKey = 'company_name';
  static const String _companyPhoneKey = 'company_phone';
  static const String _companyAddressKey = 'company_address';
  static const String _companyEmailKey = 'company_email';
  static const String _companyVatNumberKey = 'company_vat_number';
  static const String _companyLogoPathKey = 'company_logo_path';

  // --- القيم الافتراضية ---
  static final CurrencyModel _defaultCurrency = CurrencyModel
      .availableCurrencies
      .firstWhere(
        (c) => c.code == 'SAR',
      ); // --- متغيرات الحالة (Reactive Variables) ---
  /// العملة الأساسية للنظام
  final Rx<CurrencyModel> primaryCurrency = _defaultCurrency.obs;

  /// هل العملة المحلية مطابقة للأساسية؟
  final RxBool isLocalSameAsPrimary = true.obs;

  /// العملة المحلية (تستخدم فقط إذا كانت مختلفة عن الأساسية)
  final Rx<CurrencyModel> localCurrency = _defaultCurrency.obs;

  /// سعر الصرف (مقابل العملة الأساسية)
  final RxDouble exchangeRate = 1.0.obs;

  /// هل نعرض العملتين في الفاتورة؟
  final RxBool showBothCurrenciesInInvoice = false.obs;

  // --- بيانات الشركة (Company Profile) ---
  final RxString companyName = 'شركة إيهاب للتجارة العامة'.obs;
  final RxString companyPhone = '777-777-777'.obs;
  final RxString companyAddress = 'صنعاء - اليمن'.obs;
  final RxString companyEmail = 'info@ehab-company.com'.obs;
  final RxString companyVatNumber = ''.obs;
  final RxString companyLogoPath = 'assets/images/logo.png'.obs;

  /// تهيئة الخدمة واسترجاع البيانات المحفوظة
  Future<SettingsService> init() async {
    _prefs = await SharedPreferences.getInstance();

    // 1. تحميل العملة الأساسية
    String? primaryCode = _prefs.getString(_primaryCurrencyCodeKey);
    primaryCurrency.value = _getCurrencyByCode(primaryCode) ?? _defaultCurrency;

    // 2. تحميل إعداد "تطابق العملات"
    isLocalSameAsPrimary.value =
        _prefs.getBool(_isLocalSameAsPrimaryKey) ?? true;

    // 3. تحميل العملة المحلية
    if (isLocalSameAsPrimary.value) {
      localCurrency.value = primaryCurrency.value;
      exchangeRate.value = 1.0;
    } else {
      String? localCode = _prefs.getString(_localCurrencyCodeKey);
      localCurrency.value = _getCurrencyByCode(localCode) ?? _defaultCurrency;
      exchangeRate.value = _prefs.getDouble(_exchangeRateKey) ?? 1.0;
    }

    // 4. تحميل إعداد عرض العملتين
    showBothCurrenciesInInvoice.value =
        _prefs.getBool(_showBothCurrenciesKey) ?? false;

    // 5. تحميل بيانات الشركة
    companyName.value = _prefs.getString(_companyNameKey) ?? 'شركة إيهاب للتجارة العامة';
    companyPhone.value = _prefs.getString(_companyPhoneKey) ?? '777-777-777';
    companyAddress.value = _prefs.getString(_companyAddressKey) ?? 'صنعاء - اليمن';
    companyEmail.value = _prefs.getString(_companyEmailKey) ?? 'info@ehab-company.com';
    companyVatNumber.value = _prefs.getString(_companyVatNumberKey) ?? '';
    companyLogoPath.value = _prefs.getString(_companyLogoPathKey) ?? 'assets/images/logo.png';

    return this;
  }

  /// دالة مساعدة لجلب كائن العملة من الكود
  CurrencyModel? _getCurrencyByCode(String? code) {
    if (code == null) return null;
    try {
      return CurrencyModel.availableCurrencies.firstWhere(
        (c) => c.code == code,
      );
    } catch (e) {
      return null;
    }
  }

  // --- دوال التحديث (Actions) ---

  /// تحديث العملة الأساسية
  Future<void> setPrimaryCurrency(CurrencyModel currency) async {
    primaryCurrency.value = currency;
    await _prefs.setString(_primaryCurrencyCodeKey, currency.code);

    // إذا كانت العملات متطابقة، نحدث المحلية تلقائياً لتوافق الأساسية
    if (isLocalSameAsPrimary.value) {
      setLocalCurrency(currency); // سيقوم بتعديل المحلية وتصفير سعر الصرف
    }
  }

  /// تبديل وضع "مطابقة العملة المحلية"
  Future<void> toggleLocalSameAsPrimary(bool isSame) async {
    isLocalSameAsPrimary.value = isSame;
    await _prefs.setBool(_isLocalSameAsPrimaryKey, isSame);

    if (isSame) {
      // إذا أصبحتا متطابقتين، انسخ العملة الأساسية للمحلية وصفر سعر الصرف
      await setLocalCurrency(primaryCurrency.value);
      await setExchangeRate(1.0);
    }
  }

  /// تحديث العملة المحلية
  Future<void> setLocalCurrency(CurrencyModel currency) async {
    localCurrency.value = currency;
    await _prefs.setString(_localCurrencyCodeKey, currency.code);
  }

  /// تحديث سعر الصرف
  Future<void> setExchangeRate(double rate) async {
    exchangeRate.value = rate;
    await _prefs.setDouble(_exchangeRateKey, rate);
  }

  /// تحديث خيار عرض العملتين في الفاتورة
  Future<void> setShowBothCurrencies(bool show) async {
    showBothCurrenciesInInvoice.value = show;
    await _prefs.setBool(_showBothCurrenciesKey, show);
  }

  // --- تحديث بيانات الشركة ---

  Future<void> updateCompanyInfo({
    String? name,
    String? phone,
    String? address,
    String? email,
    String? vat,
    String? logo,
  }) async {
    if (name != null) {
      companyName.value = name;
      await _prefs.setString(_companyNameKey, name);
    }
    if (phone != null) {
      companyPhone.value = phone;
      await _prefs.setString(_companyPhoneKey, phone);
    }
    if (address != null) {
      companyAddress.value = address;
      await _prefs.setString(_companyAddressKey, address);
    }
    if (email != null) {
      companyEmail.value = email;
      await _prefs.setString(_companyEmailKey, email);
    }
    if (vat != null) {
      companyVatNumber.value = vat;
      await _prefs.setString(_companyVatNumberKey, vat);
    }
    if (logo != null) {
      companyLogoPath.value = logo;
      await _prefs.setString(_companyLogoPathKey, logo);
    }
  }
}
