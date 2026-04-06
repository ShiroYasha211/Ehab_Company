// File: lib/core/services/tafqeet_service.dart

import 'package:get/get.dart';
import 'settings_service.dart';

class TafqeetService {
  static final List<String> _ones = [
    '', 'واحد', 'اثنان', 'ثلاثة', 'أربعة', 'خمسة', 'ستة', 'سبعة', 'ثمانية', 'تسعة', 'عشرة',
    'أحد عشر', 'اثنا عشر', 'ثلاثة عشر', 'أربعة عشر', 'خمسة عشر', 'ستة عشر', 'سبعة عشر', 'ثمانية عشر', 'تسعة عشر'
  ];

  static final List<String> _tens = [
    '', '', 'عشرون', 'ثلاثون', 'أربعون', 'خمسون', 'ستون', 'سبعون', 'ثمانون', 'تسعون'
  ];

  static final List<String> _hundreds = [
    '', 'مائة', 'مائتان', 'ثلاثمائة', 'أربعمائة', 'خمسمائة', 'ستمائة', 'سبعمائة', 'ثمانمائة', 'تسعمائة'
  ];

  static String convert(double number) {
    if (number == 0) return 'صفر';

    final settings = Get.find<SettingsService>();
    String currencyName = settings.primaryCurrency.value.name;
    String subCurrencyName = _getSubCurrency(settings.primaryCurrency.value.code);

    int integerPart = number.truncate();
    int decimalPart = ((number - integerPart) * 100).round();

    String result = _convertGroup(integerPart);
    
    if (result.isNotEmpty) {
      result = 'فقط $result $currencyName';
    }

    if (decimalPart > 0) {
      String decimalResult = _convertGroup(decimalPart);
      if (result.isNotEmpty) {
        result += ' و $decimalResult $subCurrencyName';
      } else {
        result = 'فقط $decimalResult $subCurrencyName';
      }
    }

    return '$result لا غير.';
  }

  static String _convertGroup(int n) {
    if (n == 0) return '';
    
    String res = '';
    
    // المليارات
    if (n >= 1000000000) {
      int billions = n ~/ 1000000000;
      res += _formatLarge(billions, 'مليار', 'مليارات', 'ملياراً');
      n %= 1000000000;
    }
    
    // الملايين
    if (n >= 1000000) {
      if (res.isNotEmpty && n > 0) res += ' و ';
      int millions = n ~/ 1000000;
      res += _formatLarge(millions, 'مليون', 'ملايين', 'مليوناً');
      n %= 1000000;
    }
    
    // الآلاف
    if (n >= 1000) {
      if (res.isNotEmpty && n > 0) res += ' و ';
      int thousands = n ~/ 1000;
      res += _formatLarge(thousands, 'ألف', 'آلاف', 'ألفاً');
      n %= 1000;
    }
    
    // المئات والآحاد والعشرات
    if (n > 0) {
      if (res.isNotEmpty) res += ' و ';
      res += _convertThreeDigits(n);
    }
    
    return res;
  }

  static String _formatLarge(int n, String singular, String plural, String accusative) {
    if (n == 1) return singular;
    if (n == 2) return singular + 'ان';
    if (n >= 3 && n <= 10) return '${_convertThreeDigits(n)} $plural';
    return '${_convertThreeDigits(n)} $accusative';
  }

  static String _convertThreeDigits(int n) {
    String res = '';
    
    int h = n ~/ 100;
    int remaining = n %= 100;
    
    if (h > 0) {
      res += _hundreds[h];
    }
    
    if (remaining > 0) {
      if (res.isNotEmpty) res += ' و ';
      
      if (remaining < 20) {
        res += _ones[remaining];
      } else {
        int ones = remaining % 10;
        int tens = remaining ~/ 10;
        if (ones > 0) {
          res += '${_ones[ones]} و ${_tens[tens]}';
        } else {
          res += _tens[tens];
        }
      }
    }
    
    return res;
  }

  static String _getSubCurrency(String code) {
    switch (code) {
      case 'SAR': return 'هللة';
      case 'USD': return 'سنت';
      case 'YER': return 'فلس';
      default: return 'جزء';
    }
  }
}
