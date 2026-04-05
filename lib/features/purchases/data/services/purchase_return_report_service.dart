// File: lib/features/purchases/data/services/purchase_return_report_service.dart

import 'package:ehab_company_admin/core/services/settings_service.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart' as intl;

class PurchaseReturnReportService {
  static Future<void> generateAndPreviewReport({
    required List<Map<String, dynamic>> returns,
    DateTime? startDate,
    DateTime? endDate,
    String? supplierName,
  }) async {
    final pdf = pw.Document();
    
    // تحميل الخطوط لدعم اللغة العربية
    final font = await rootBundle.load("assets/fonts/Tajawal-Regular.ttf");
    final boldFont = await rootBundle.load("assets/fonts/Tajawal-Bold.ttf");
    final ttf = pw.Font.ttf(font);
    final boldTtf = pw.Font.ttf(boldFont);

    // تحميل الشعار
    final logoImage = pw.MemoryImage(
      (await rootBundle.load('assets/images/logo.png')).buffer.asUint8List(),
    );

    final settings = Get.find<SettingsService>();
    final symbol = settings.primaryCurrency.value.symbol;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: ttf, bold: boldTtf),
        header: (context) => _buildHeader(logoImage),
        build: (context) => [
          _buildReportTitle(startDate, endDate, supplierName),
          pw.SizedBox(height: 20),
          _buildSummaryCards(returns, symbol),
          pw.SizedBox(height: 20),
          _buildReturnsTable(returns, symbol),
        ],
        footer: (context) => _buildFooter(context),
      ),
    );

    // عرض معاينة الطباعة
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'تقرير_مرتجعات_المشتريات_${intl.DateFormat('yyyy_MM_dd').format(DateTime.now())}.pdf',
    );
  }

  static pw.Widget _buildHeader(pw.MemoryImage logo) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 1)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('شركة إيهاب للتجارة العامة', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.Text('قسم إدارة المشتريات والمرتجعات', style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
          pw.SizedBox(height: 40, width: 40, child: pw.Image(logo)),
        ],
      ),
    );
  }

  static pw.Widget _buildReportTitle(DateTime? start, DateTime? end, String? supplier) {
    String dateRange = 'كافة الفترات';
    if (start != null) {
      dateRange = '${intl.DateFormat('yyyy-MM-dd').format(start)} ${end != null ? 'إلى ${intl.DateFormat('yyyy-MM-dd').format(end)}' : ''}';
    }

    return pw.Center(
      child: pw.Column(
        children: [
          pw.SizedBox(height: 10),
          pw.Text('تقرير حركة مرتجعات المشتريات التفصيلي', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
          pw.SizedBox(height: 5),
          pw.Text('لفترة: $dateRange', style: const pw.TextStyle(fontSize: 10)),
          if (supplier != null)
             pw.Text('المورد: $supplier', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryCards(List<Map<String, dynamic>> returns, String symbol) {
    final totalValue = returns.fold(0.0, (sum, item) => sum + (item['totalReturnedValue'] as num).toDouble());
    
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
      children: [
        _buildStatBox('إجمالي قيمة مرتجعات المشتريات', '${totalValue.toStringAsFixed(2)} $symbol', PdfColors.blue800),
        _buildStatBox('إجمالي عدد العمليات', '${returns.length}', PdfColors.grey800),
      ],
    );
  }

  static pw.Widget _buildStatBox(String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 1),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
          pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  static pw.Widget _buildReturnsTable(List<Map<String, dynamic>> returns, String symbol) {
    final headers = ['القيمة', 'السبب', 'المورد', 'التاريخ', '#'];
    
    final data = returns.asMap().entries.map((entry) {
      final i = entry.key + 1;
      final item = entry.value;
      final date = intl.DateFormat('yyyy-MM-dd').format(DateTime.parse(item['returnDate']));
      
      return [
        '${(item['totalReturnedValue'] as num).toDouble().toStringAsFixed(2)} $symbol',
        item['reason'] ?? 'إرجاع عام',
        item['supplierName'] ?? 'غير محدد',
        date,
        '$i',
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
      cellStyle: const pw.TextStyle(fontSize: 9),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(3),
        3: const pw.FlexColumnWidth(2),
        4: const pw.FlexColumnWidth(0.5),
      },
      cellAlignment: pw.Alignment.centerRight,
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        'صفحة ${context.pageNumber} من ${context.pagesCount} - تم توليد التقارير عبر نظام إيهاب الذكي',
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
      ),
    );
  }
}
