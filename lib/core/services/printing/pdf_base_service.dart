// File: lib/core/services/printing/pdf_base_service.dart

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart' as intl;
import '../settings_service.dart';

class PdfBaseService {
  /// تنسيق المبالغ المالية مع رمز العملة بشكل آمن للـ PDF
  static String formatCurrency(double amount) {
    final settings = Get.find<SettingsService>();
    String currencySymbol = settings.primaryCurrency.value.symbol;
    
    // تحويل الرموز المختصرة إلى كلمات كاملة لتجنب مشاكل التداخل والـ Bidi في PDF
    if (currencySymbol == 'ر.ي' || currencySymbol == '﷼') currencySymbol = 'ريال';
    if (currencySymbol == 'ر.س') currencySymbol = 'ريال';
    if (currencySymbol == 'ر.ق') currencySymbol = 'ريال';
    if (currencySymbol == 'ر.ع') currencySymbol = 'ريال';

    final formattedAmount = intl.NumberFormat.decimalPattern('ar').format(amount);
    return sanitize('$formattedAmount $currencySymbol');
  }

  /// تحميل الموارد الأساسية (الخطوط والشعار)
  static Future<Map<String, dynamic>> loadResources() async {
    final settings = Get.find<SettingsService>();
    
    final font = await rootBundle.load("assets/fonts/Tajawal-Regular.ttf");
    final boldFont = await rootBundle.load("assets/fonts/Tajawal-Bold.ttf");
    
    pw.MemoryImage? logoImage;
    try {
      logoImage = pw.MemoryImage(
        (await rootBundle.load(settings.companyLogoPath.value)).buffer.asUint8List(),
      );
    } catch (e) {
      // إذا فشل تحميل الشعار المخصص، حمل الشعار الافتراضي
      logoImage = pw.MemoryImage(
        (await rootBundle.load('assets/images/logo.png')).buffer.asUint8List(),
      );
    }

    return {
      'ttf': pw.Font.ttf(font),
      'boldTtf': pw.Font.ttf(boldFont),
      'logo': logoImage,
    };
  }

  /// بناء الهيدر الموحد لجميع التقارير والفواتير
  static pw.Widget buildHeader({
    required pw.MemoryImage logo,
    required pw.Font boldTtf,
    required pw.Font ttf,
    String? title,
    String? subTitle,
    pw.Widget? extra,
  }) {
    final settings = Get.find<SettingsService>();

    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.indigo900, width: 2.0)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              safeText(settings.companyName.value, 
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16, font: boldTtf, color: PdfColors.indigo900)),
              pw.SizedBox(height: 2),
              safeText('هاتف: ${settings.companyPhone.value}', 
                  style: pw.TextStyle(fontSize: 9, font: ttf, color: PdfColors.grey700)),
              safeText(settings.companyAddress.value, 
                  style: pw.TextStyle(fontSize: 9, font: ttf, color: PdfColors.grey700)),
              if (settings.companyVatNumber.value.isNotEmpty)
                safeText('الرقم الضريبي: ${settings.companyVatNumber.value}', 
                    style: pw.TextStyle(fontSize: 9, font: ttf, color: PdfColors.grey700)),
            ],
          ),
          pw.Row(
            children: [
              if (extra != null) ...[
                extra,
                pw.SizedBox(width: 10),
              ],
              pw.SizedBox(height: 60, width: 60, child: pw.Image(logo)),
            ],
          ),
        ],
      ),
    );
  }

  /// بناء الفوتر الموحد
  static pw.Widget buildFooter(pw.Context context, pw.Font ttf) {
    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: PdfColors.grey200))),
      padding: const pw.EdgeInsets.only(top: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          safeText('صفحة ${context.pageNumber} من ${context.pagesCount}', 
              style: pw.TextStyle(fontSize: 7, font: ttf, color: PdfColors.grey500)),
          safeText('طُبع بواسطة نظام ${Get.find<SettingsService>().companyName.value}', 
              style: pw.TextStyle(fontSize: 7, font: ttf, color: PdfColors.grey500)),
        ],
      ),
    );
  }

  /// بناء بطاقة إحصائية داشبورد (Metric Card)
  static pw.Widget buildStatCard(String label, String value, {PdfColor? color}) {
    return pw.Container(
      width: 120,
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfColors.grey100, width: 0.5),
      ),
      child: pw.Column(
        children: [
          pw.Container(height: 2.5, color: color ?? PdfColors.grey400, width: double.infinity),
          pw.Padding(
            padding: const pw.EdgeInsets.all(10),
            child: pw.Column(
              children: [
                safeText(label, style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600), align: pw.TextAlign.center),
                pw.SizedBox(height: 4),
                safeText(value, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: color ?? PdfColors.black), align: pw.TextAlign.center),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ودجت نص آمن يدعم الحروف العربية والرموز الخاصة
  static pw.Widget safeText(String? text, {required pw.TextStyle style, pw.TextAlign align = pw.TextAlign.right}) {
    String sanitized = sanitize(text ?? '');
    if (sanitized.trim().isEmpty) sanitized = " ";
    return pw.Text(sanitized, style: style, textAlign: align, textDirection: pw.TextDirection.rtl);
  }

  /// تطهير النصوص من الحروف التي تسبب مشاكل في مكتبة PDF
  static String sanitize(String text) {
    if (text.isEmpty) return " ";
    String cleaned = text
        .replaceAll('\u202f', ' ')
        .replaceAll('\u00a0', ' ')
        .replaceAll('\u066c', ',') // فاصلة الآلاف العربية
        .replaceAll('\u066b', '.') // الفاصلة العشرية العربية
        .replaceAll('\u2212', '-') // علامة الناقص الرياضية
        .replaceAll('\u2010', '-') // Hyphen
        .replaceAll('\u2011', '-') // Non-breaking hyphen
        .replaceAll('\u2012', '-') // Figure dash
        .replaceAll('\u2013', '-') // En-dash
        .replaceAll('\u2014', '-') // Em-dash
        .replaceAll('\ufdfca', 'ريال')
        .replaceAll('\ufdfc', 'ريال')
        .replaceAll('﷼', 'ريال')
        .replaceAll('ر.ي', 'ريال')
        .replaceAll('ر.س', 'ريال')
        // حذف كافة الرموز المتحكمة وغير المرئية
        .replaceAll(RegExp(r'[\u200B-\u200F\u202A-\u202E\uFEFF\u061C]'), '');

    final buffer = StringBuffer();
    for (final rune in cleaned.runes) {
      if (rune == 0x0A || rune == 0x0D) { buffer.writeCharCode(rune); continue; }
      if (rune >= 0x0020 && rune <= 0x007E) { buffer.writeCharCode(rune); continue; } // Basic Latin & Punctuation
      if (rune >= 0x00A0 && rune <= 0x00FF) { buffer.writeCharCode(rune); continue; } // Latin-1 Supplement
      if (rune >= 0x0600 && rune <= 0x06FF) { buffer.writeCharCode(rune); continue; } // Arabic
      if (rune >= 0x0750 && rune <= 0x077F) { buffer.writeCharCode(rune); continue; } // Arabic Supplement
      if (rune >= 0x20A0 && rune <= 0x20CF) { buffer.writeCharCode(rune); continue; } // Currency Symbols
      if (rune >= 0xFB50 && rune <= 0xFDFF) { buffer.writeCharCode(rune); continue; } // Arabic Forms-A
      if (rune >= 0xFE70 && rune <= 0xFEFF) { buffer.writeCharCode(rune); continue; } // Arabic Forms-B
    }
    return buffer.toString();
  }

  /// خلية جدول قياسية
  static pw.Widget tableCell(String text, pw.Font font, {PdfColor? color, double size = 9, pw.FontWeight? weight, double padding = 4}) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(padding),
      child: safeText(text, style: pw.TextStyle(font: font, fontSize: size, color: color, fontWeight: weight)),
    );
  }

  /// تنسيق الكميات الذكي (تفكيك الوحدات الهرمية)
  static String formatSmartQuantity(int? unitId, double totalQuantity, Map<int, dynamic> allUnits) {
    if (unitId == null) return '${totalQuantity.toInt()} قطعة';
    final dynamic mainUnit = allUnits[unitId];
    if (mainUnit == null) return '${totalQuantity.toInt()} قطعة';

    List<String> parts = [];
    _decompose(mainUnit, totalQuantity, parts, allUnits);

    if (parts.isEmpty) return '0 ${mainUnit.name}';
    return parts.join('، ');
  }

  static void _decompose(dynamic currentUnit, double amount, List<String> parts, Map<int, dynamic> allUnits) {
    if (amount <= 0) return;
    
    // معالجة الأخطاء العشرية البسيطة
    if ((amount - amount.round()).abs() < 0.0001) {
      amount = amount.roundToDouble();
    }

    if (currentUnit.childUnitId == null) {
      if (amount > 0) {
        String balance = amount == amount.toInt() ? amount.toInt().toString() : amount.toStringAsFixed(2);
        parts.add('$balance ${currentUnit.name}');
      }
      return;
    }

    int integerPart = amount.floor();
    if (integerPart > 0) {
      parts.add('$integerPart ${currentUnit.name}');
    }

    double remainder = amount - integerPart;
    if (remainder > 0.0001) {
      final childUnit = allUnits[currentUnit.childUnitId];
      if (childUnit != null) {
        double childAmount = remainder * currentUnit.conversionFactor;
        _decompose(childUnit, childAmount, parts, allUnits);
      }
    }
  }
}
