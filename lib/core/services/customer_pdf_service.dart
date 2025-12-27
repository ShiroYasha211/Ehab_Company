// File: lib/core/services/customer_pdf_service.dart

import 'dart:io';
import 'package:ehab_company_admin/features/customers/data/models/customer_model.dart';
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart' as intl;

class CustomerPdfService {
  static Future<void> printCustomersReport(
      List<CustomerModel> customers) async {
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
    final double totalDebt = customers.fold(
        0, (previousValue, customer) => previousValue + customer.balance);
    final int indebtedCustomersCount =
        customers
            .where((c) => c.balance > 0)
            .length;

    // 3. بناء صفحات التقرير
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: ttf, bold: boldTtf),
        header: (context) => _buildHeader(logoImage),
        build: (context) =>
        [
          _buildReportTitle(),
          pw.SizedBox(height: 20),
          _buildFinancialSummary(totalDebt, indebtedCustomersCount),
          pw.SizedBox(height: 20),
          _buildCustomersTable(customers),
        ],
        footer: (context) => _buildFooter(context),
      ),
    );

    // 4. حفظ وفتح الملف
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/customers_report.pdf');
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
          'تقرير أرصدة العملاء',
          style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey800),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'تاريخ التقرير: ${intl.DateFormat('yyyy-MM-dd').format(
              DateTime.now())}',
          style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
        ),
      ],
    );
  }

  static pw.Widget _buildFinancialSummary(double totalDebt,
      int indebtedCustomersCount) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
          color: PdfColors.blue.shade(0.05), // لون أزرق خفيف
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColors.blue200)
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('إجمالي الديون المستحقة', totalDebt),
          _buildSummaryItem(
              'عدد العملاء المدينين', indebtedCustomersCount.toDouble(),
              isCurrency: false),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryItem(String label, double value,
      {bool isCurrency = true}) {
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
              color: PdfColors.blue700),
        ),
      ],
    );
  }

  static pw.Widget _buildCustomersTable(List<CustomerModel> customers) {
    final headers = ['الرصيد', 'آخر حركة', 'رقم الهاتف', 'اسم العميل'];

    final data = customers.map((customer) {
      return [
        '${intl.NumberFormat.decimalPattern('ar').format(
            customer.balance)} ريال',
        customer.lastTransactionDate != null
            ? intl.DateFormat('yyyy-MM-dd').format(
            customer.lastTransactionDate!)
            : 'لا يوجد',
        customer.phone ?? 'غير متوفر',
        customer.name,
      ];
    }).toList();

    return pw.Table.fromTextArray(
        cellAlignment: pw.Alignment.centerRight,
        headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
            fontSize: 11),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
        rowDecoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200))),
        headers: headers,
        data: data,
        columnWidths: {
          0: const pw.FlexColumnWidth(2.5), // الرصيد
          1: const pw.FlexColumnWidth(2), // آخر حركة
          2: const pw.FlexColumnWidth(2.5), // رقم الهاتف
          3: const pw.FlexColumnWidth(4), // اسم العميل
        },
        cellAlignments: { // محاذاة الأرقام والتواريخ لليسار
          0: pw.Alignment.centerLeft,
          1: pw.Alignment.centerLeft,
          2: pw.Alignment.centerLeft,
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