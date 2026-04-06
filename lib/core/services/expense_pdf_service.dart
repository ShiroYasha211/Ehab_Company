// File: lib/core/services/expense_pdf_service.dart

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart' as intl;
import 'tafqeet_service.dart';

import 'settings_service.dart';

class ExpensePdfService {
  static Future<void> printExpenseReport({
    required Map<String, dynamic> reportData,
    required DateTime from,
    required DateTime to,
  }) async {
    final pdf = pw.Document();

    // 1. تحميل الخطوط والشعار (نفس الكود الموحد)
    final font = await rootBundle.load("assets/fonts/Tajawal-Regular.ttf");
    final boldFont = await rootBundle.load("assets/fonts/Tajawal-Bold.ttf");
    final ttf = pw.Font.ttf(font);
    final boldTtf = pw.Font.ttf(boldFont);

    final logoImage = pw.MemoryImage(
      (await rootBundle.load('assets/images/logo.png')).buffer.asUint8List(),
    );

    // 2. استخراج البيانات
    final List<Map<String, dynamic>> expenses = reportData['expenses'];
    final double grandTotal = reportData['grandTotal'];

    // 3. بناء صفحات التقرير
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: ttf, bold: boldTtf),
        header: (context) => _buildHeader(logoImage, ttf, boldTtf),
        build: (context) => [
          _buildReportTitle(from, to, ttf, boldTtf),
          pw.SizedBox(height: 20),
          _buildGrandTotalSummary(grandTotal, ttf, boldTtf), // ملخص الإجمالي الكلي
          pw.SizedBox(height: 20),
          _buildExpensesTable(expenses, ttf, boldTtf), // جدول المصروفات المجمعة
        ],
        footer: (context) => _buildFooter(context, ttf),
      ),
    );

    // 4. حفظ وفتح الملف
    final dir = await getApplicationDocumentsDirectory();
    final fileName =
        'expenses_report_${intl.DateFormat('yyyy-MM-dd').format(from)}_to_${intl.DateFormat('yyyy-MM-dd').format(to)}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }

  // --- دوال بناء أجزاء التقرير (متوافقة مع الهوية البصرية) ---

  static pw.Widget _buildHeader(pw.MemoryImage logo, pw.Font ttf, pw.Font boldTtf) {
    // (نفس دالة الهيدر من التقارير السابقة)
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 15),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey, width: 1.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'شركة إيهاب للتجارة',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 18,
                  font: boldTtf,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'هاتف: 777-777-777',
                style: pw.TextStyle(fontSize: 10, font: ttf),
              ),
              pw.Text(
                'البريد الإلكتروني: info@ehab-company.com',
                style: pw.TextStyle(fontSize: 10, font: ttf),
              ),
            ],
          ),
          pw.SizedBox(height: 60, width: 60, child: pw.Image(logo)),
        ],
      ),
    );
  }

  static pw.Widget _buildReportTitle(DateTime from, DateTime to, pw.Font ttf, pw.Font boldTtf) {
    return pw.Column(
      children: [
        pw.SizedBox(height: 15),
        pw.Text(
          'تقرير المصروفات',
          style: pw.TextStyle(
            fontSize: 22,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blueGrey800,
            font: boldTtf,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'للفترة من: ${intl.DateFormat('yyyy-MM-dd').format(from)}   إلى: ${intl.DateFormat('yyyy-MM-dd').format(to)}',
          style: pw.TextStyle(fontSize: 11, color: PdfColors.grey600, font: ttf),
        ),
      ],
    );
  }

  static pw.Widget _buildGrandTotalSummary(double grandTotal, pw.Font ttf, pw.Font boldTtf) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.red.shade(0.05), // لون أحمر خفيف للمصروفات
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.red200),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                'إجمالي المصروفات للفترة: ',
                style:
                    pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, font: boldTtf),
              ),
              pw.Text(
                '${_sanitize(intl.NumberFormat.decimalPattern('ar').format(grandTotal))} ${Get.find<SettingsService>().primaryCurrency.value.symbol}',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 16,
                  color: PdfColors.red700,
                  font: boldTtf,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Align(
            alignment: pw.Alignment.center,
            child: pw.Text(
              _sanitize(TafqeetService.convert(grandTotal)),
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, font: boldTtf),
            ),
          ),
        ],
      ),
    );
  }

  // --- بداية التعديل: تحديث بناء الجدول ليتوافق مع الإصدار الحديث ---
  static pw.Widget _buildExpensesTable(List<Map<String, dynamic>> expenses, pw.Font ttf, pw.Font boldTtf) {
    // --- بداية التعديل: تعديل تصميم الجدول ---

    // 1. إضافة عمود "بند المصروف" و"الصندوق/المصدر" و"المورد" إلى الهيدر
    final headers = ['المبلغ', 'الوصف', 'التاريخ', 'بند المصروف', 'الصندوق', 'المورد'];

    // 2. بناء الصفوف مباشرة بدون التحقق من البند
    final data = expenses.map((expense) {
      return [
        _sanitize('${intl.NumberFormat.decimalPattern('ar').format(expense['amount'])} ${Get.find<SettingsService>().primaryCurrency.value.symbol}'),
        expense['notes'] ?? '',
        intl.DateFormat(
          'yyyy-MM-dd',
        ).format(DateTime.parse(expense['expenseDate'])),
        expense['categoryName'],
        expense['fundName'] ?? 'الصندوق الرئيسي',
        expense['supplierName'] ?? '-', // <-- إضافة اسم المورد كبيانات في العمود السادس
      ];
    }).toList();

    // 3. استخدام TableHelper.fromTextArray لسهولة البناء
    return pw.Table.fromTextArray(
      cellAlignment: pw.Alignment.centerRight,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        fontSize: 11,
        font: boldTtf,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
      rowDecoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200)),
      ),
      headers: headers,
      data: data,
      // 4. تحديد عرض الأعمدة الجديدة
      columnWidths: {
        0: const pw.FlexColumnWidth(2), // المبلغ
        1: const pw.FlexColumnWidth(3), // الوصف
        2: const pw.FlexColumnWidth(2), // التاريخ
        3: const pw.FlexColumnWidth(2.5), // بند المصروف
        4: const pw.FlexColumnWidth(2.5), // الصندوق
        5: const pw.FlexColumnWidth(2.5), // المورد
      },
      cellStyle: pw.TextStyle(font: ttf, fontSize: 10),
      cellAlignments: {
        // محاذاة الأرقام والتواريخ لليسار
        0: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
      },
    );
    // --- نهاية التعديل ---
  }

  // --- نهاية التعديل ---

  static pw.Widget _buildFooter(pw.Context context, pw.Font ttf) {
    // (نفس دالة التذييل من التقارير السابقة)
    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        'صفحة ${context.pageNumber} من ${context.pagesCount} - © شركة إيهاب',
        style: pw.TextStyle(fontSize: 10, color: PdfColors.grey, font: ttf),
      ),
    );
  }
  // دالة تنقية النصوص من المحافير التي قد تسبب انهيار محرك الـ PDF
  static String _sanitize(String text) {
    return text
        .replaceAll('\u202f', ' ') // Narrow No-Break Space
        .replaceAll('\u00a0', ' ') // No-Break Space
        .replaceAll('\u066c', ',') // Arabic Thousands Separator
        .replaceAll('\u066b', '.') // Arabic Decimal Separator
        .replaceAll(RegExp(r'[\u200e\u200f\u061c\u202a-\u202e\u2066-\u2069]'), ''); // BiDi Marks
  }
}

