// File: lib/core/services/supplier_pdf_service.dart

import 'dart:io';
import 'package:ehab_company_admin/features/suppliers/data/models/supplier_model.dart';
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart' as intl;

class SupplierPdfService {
  static Future<void> printSuppliersReport(
      List<SupplierModel> suppliers) async {
    final pdf = pw.Document();

    // 1. تحميل الخطوط والشعار
    final font = await rootBundle.load("assets/fonts/Tajawal-Regular.ttf");
    final boldFont = await rootBundle.load("assets/fonts/Tajawal-Bold.ttf");
    final ttf = pw.Font.ttf(font);
    final boldTtf = pw.Font.ttf(boldFont);

    final logoImage = pw.MemoryImage(
      (await rootBundle.load('assets/images/logo.png')).buffer.asUint8List(),
    );

    // 2. حساب الملخصات
    final double totalDues = suppliers.fold(
        0, (previousValue, supplier) => previousValue + supplier.balance);
    final int dueSuppliersCount =
        suppliers.where((s) => s.balance > 0).length;

    // 3. بناء صفحات التقرير
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: ttf, bold: boldTtf),
        header: (context) => _buildHeader(logoImage),
        build: (context) => [
          _buildReportTitle(),
          pw.SizedBox(height: 20),
          _buildFinancialSummary(totalDues, dueSuppliersCount),
          pw.SizedBox(height: 20),
          _buildSuppliersTable(suppliers),
        ],
        footer: (context) => _buildFooter(context),
      ),
    );

    // 4. حفظ وفتح الملف
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/suppliers_report.pdf');
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }

  // --- دوال بناء أجزاء التقرير (متوافقة مع الهوية البصرية) ---

  static pw.Widget _buildHeader(pw.MemoryImage logo) {
    // (نفس دالة الهيدر من التقارير السابقة)
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 15),
      decoration: const pw.BoxDecoration(
          border:
          pw.Border(bottom: pw.BorderSide(color: PdfColors.grey, width: 1.5))),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('شركة إيهاب للتجارة',
                  style:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
              pw.SizedBox(height: 5),
              pw.Text('هاتف: 777-777-777',
                  style: const pw.TextStyle(fontSize: 10)),
              pw.Text('البريد الإلكتروني: info@ehab-company.com',
                  style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
          pw.SizedBox(height: 60, width: 60, child: pw.Image(logo)),
        ],
      ),
    );
  }

  static pw.Widget _buildReportTitle() {
    return pw.Column(
      children: [
        pw.SizedBox(height: 15),
        pw.Text(
          'تقرير أرصدة الموردين',
          style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey800),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'تاريخ التقرير: ${intl.DateFormat('yyyy-MM-dd').format(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
        ),
      ],
    );
  }

  static pw.Widget _buildFinancialSummary(
      double totalDues, int dueSuppliersCount) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
          color: PdfColors.orange.shade(0.05), // لون برتقالي خفيف للموردين
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColors.orange200)
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('إجمالي المستحقات للموردين', totalDues),
          _buildSummaryItem('عدد الموردين الدائنين', dueSuppliersCount.toDouble(), isCurrency: false),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryItem(String label, double value, {bool isCurrency = true}) {
    final formattedValue = isCurrency
        ? '${intl.NumberFormat.decimalPattern('ar').format(value)} ريال'
        : value.toInt().toString();

    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 11)),
        pw.SizedBox(height: 4),
        pw.Text(
          formattedValue,
          style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 16,
              color: PdfColors.orange800),
        ),
      ],
    );
  }

  static pw.Widget _buildSuppliersTable(List<SupplierModel> suppliers) {
    final headers = ['الرصيد المستحق', 'رقم الهاتف', 'اسم المورد'];

    final data = suppliers.map((supplier) {
      return [
        '${intl.NumberFormat.decimalPattern('ar').format(supplier.balance)} ريال',
        supplier.phone ?? 'غير متوفر',
        supplier.name,
      ];
    }).toList();

    return pw.Table.fromTextArray(
        cellAlignment: pw.Alignment.centerRight,
        headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 11),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
        rowDecoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200))),
        headers: headers,
        data: data,
        columnWidths: {
          0: const pw.FlexColumnWidth(3), // الرصيد
          1: const pw.FlexColumnWidth(3), // رقم الهاتف
          2: const pw.FlexColumnWidth(5), // اسم المورد
        },
        cellAlignments: { // محاذاة الأرقام لليسار
          0: pw.Alignment.centerLeft,
          1: pw.Alignment.centerLeft,
        }
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    // (نفس دالة التذييل من التقارير السابقة)
    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        'صفحة ${context.pageNumber} من ${context.pagesCount} - © شركة إيهاب',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
      ),
    );
  }
}

