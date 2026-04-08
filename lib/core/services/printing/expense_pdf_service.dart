// File: lib/core/services/printing/expense_pdf_service.dart

import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart' as intl;
import 'pdf_base_service.dart';

class ExpensePdfService {
  static Future<void> printExpenseReport(List<Map<String, dynamic>> expenses, {String? categoryName, String? dateRange}) async {
    final pdf = pw.Document();

    final resources = await PdfBaseService.loadResources();
    final pw.Font ttf = resources['ttf'];
    final pw.Font boldTtf = resources['boldTtf'];
    final pw.MemoryImage logo = resources['logo'];

    final double totalAmount = expenses.fold(0.0, (prev, e) => prev + (e['amount'] as num).toDouble());
    
    // تجميع المصروفات حسب الفئة للجدول الملخص
    final Map<String, double> categoryTotals = {};
    for (var e in expenses) {
      final cat = e['categoryName'] ?? 'غير محدد';
      categoryTotals[cat] = (categoryTotals[cat] ?? 0.0) + (e['amount'] as num).toDouble();
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: ttf, bold: boldTtf),
        header: (context) => PdfBaseService.buildHeader(logo: logo, boldTtf: boldTtf, ttf: ttf),
        footer: (context) => PdfBaseService.buildFooter(context, ttf),
        build: (context) => [
          _buildReportTitle(categoryName, dateRange),
          pw.SizedBox(height: 20),
          _buildCategorySummary(categoryTotals),
          pw.SizedBox(height: 20),
          _buildExpensesTable(expenses),
          pw.SizedBox(height: 20),
          _buildFinalTotal(totalAmount),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/expense_report.pdf');
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }

  static pw.Widget _buildReportTitle(String? category, String? range) {
    return pw.Column(
      children: [
        pw.SizedBox(height: 15),
        PdfBaseService.safeText('تقرير المصروفات التحليلي', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
        if (category != null) PdfBaseService.safeText('الفئة المستهدفة: $category', style: const pw.TextStyle(fontSize: 11)),
        if (range != null) PdfBaseService.safeText('فترة التقرير: $range', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        pw.SizedBox(height: 5),
        PdfBaseService.safeText('تاريخ الطباعة: ${intl.DateFormat('yyyy-MM-dd | hh:mm a').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
      ],
    );
  }

  static pw.Widget _buildCategorySummary(Map<String, double> totals) {
    final sortedCategories = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        PdfBaseService.safeText('ملخص بند المصروفات:', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
        pw.SizedBox(height: 8),
        pw.Table.fromTextArray(
          headers: ['الإجمالي', 'بند المصروف'],
          data: sortedCategories.map((e) => [
            PdfBaseService.formatCurrency(e.value),
            PdfBaseService.sanitize(e.key),
          ]).toList(),
          cellAlignment: pw.Alignment.centerRight,
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
          rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200))),
          cellStyle: const pw.TextStyle(fontSize: 9),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(3),
          },
        ),
      ],
    );
  }

  static pw.Widget _buildExpensesTable(List<Map<String, dynamic>> expenses) {
    final headers = ['المبلغ', 'مصدر الدفع', 'الملاحظات', 'الفئة', 'التاريخ', '#'];
    
    final data = List.generate(expenses.length, (index) {
      final e = expenses[index];
      final source = e['fundName'] ?? e['supplierName'] ?? '-';

      String dateStr = '-';
      try {
        final dynamic dateVal = e['expenseDate'];
        if (dateVal is DateTime) {
          dateStr = '${intl.DateFormat('yyyy-MM-dd').format(dateVal)} | ${intl.DateFormat('hh:mm a').format(dateVal)}';
        } else if (dateVal != null) {
          final dt = DateTime.parse(dateVal.toString());
          dateStr = '${intl.DateFormat('yyyy-MM-dd').format(dt)} | ${intl.DateFormat('hh:mm a').format(dt)}';
        }
      } catch (_) {}

      return [
        PdfBaseService.sanitize(intl.NumberFormat.decimalPattern('ar').format((e['amount'] as num).toDouble())),
        PdfBaseService.sanitize(source),
        PdfBaseService.sanitize(e['notes'] ?? '-'),
        PdfBaseService.sanitize(e['categoryName'] ?? '-'),
        PdfBaseService.sanitize(dateStr),
        (index + 1).toString(),
      ];
    });

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        PdfBaseService.safeText('تفاصيل الحركات:', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
        pw.SizedBox(height: 8),
        pw.Table.fromTextArray(
          headers: headers,
          data: data,
          cellAlignment: pw.Alignment.centerRight,
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9.5),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo900),
          rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200))),
          cellStyle: const pw.TextStyle(fontSize: 8.5),
          oddRowDecoration: const pw.BoxDecoration(color: PdfColors.indigo50),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(3.5),
            3: const pw.FlexColumnWidth(2),
            4: const pw.FlexColumnWidth(1.8),
            5: const pw.FixedColumnWidth(20),
          },
        ),
      ],
    );
  }

  static pw.Widget _buildFinalTotal(double total) {
    return pw.Container(
      alignment: pw.Alignment.centerLeft,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          PdfBaseService.safeText('إجمالي المصروفات الكلي:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(width: 10),
          PdfBaseService.safeText(PdfBaseService.formatCurrency(total), 
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
        ],
      ),
    );
  }
}
