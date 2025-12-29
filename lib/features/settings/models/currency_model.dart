// File: lib/features/settings/models/currency_model.dart

/// كلاس يمثل بيانات العملة (الرمز، الاسم، والشعار)
class CurrencyModel {
  final String code; // الكود الدولي (مثال: SAR, YER, USD)
  final String name; // الاسم المعروض (مثال: ريال سعودي)
  final String symbol; // الرمز (مثال: ر.س)

  const CurrencyModel({
    required this.code,
    required this.name,
    required this.symbol,
  });

  /// قائمة بالعملات المدعومة والمقترحة في التطبيق
  static const List<CurrencyModel> availableCurrencies = [
    CurrencyModel(code: 'SAR', name: 'ريال سعودي', symbol: 'ر.س'),
    CurrencyModel(code: 'YER', name: 'ريال يمني', symbol: 'ر.ي'),
    CurrencyModel(code: 'USD', name: 'دولار أمريكي', symbol: '\$'),
    CurrencyModel(code: 'AED', name: 'درهم إماراتي', symbol: 'د.إ'),
    CurrencyModel(code: 'EGP', name: 'جنيه مصري', symbol: 'ج.م'),
    CurrencyModel(code: 'QAR', name: 'ريال قطري', symbol: 'ر.ق'),
    CurrencyModel(code: 'KWD', name: 'دينار كويتي', symbol: 'د.ك'),
    CurrencyModel(code: 'OMR', name: 'ريال عماني', symbol: 'ر.ع'),
    CurrencyModel(code: 'BHD', name: 'دينار بحريني', symbol: '.د.ب'),
    CurrencyModel(code: 'EUR', name: 'يورو', symbol: '€'),
  ];

  /// التحقق من تساوي العملات بناءً على الكود
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CurrencyModel &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}
