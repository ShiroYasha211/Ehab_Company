// File: lib/core/services/fund_pdf_service.dart

import 'dart:io';
import 'package:ehab_company_admin/features/fund/data/models/fund_transaction_model.dart';
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart' as intl;

class FundPdfService {
  static Future<void> printFundReport({
    required Map<String, dynamic> reportData,
    required DateTime from,
    required DateTime to,
  }) async {
    final pdf = pw.Document();

    // 1. تحميل الخطوط والشعار
    final font = await rootBundle.load("assets/fonts/Tajawal-Regular.ttf");
    final boldFont = await rootBundle.load("assets/fonts/Tajawal-Bold.ttf");
    final ttf = pw.Font.ttf(font);
    final boldTtf = pw.Font.ttf(boldFont);

    final logoImage = pw.MemoryImage(
      (await rootBundle.load('assets/images/logo.png')).buffer.asUint8List(),
    );

    // 2. استخراج البيانات
    final double openingBalance = reportData['openingBalance'];
    final List<FundTransactionModel> transactions = reportData['transactions'];
    final double totalDeposits = reportData['totalDeposits'];
    final double totalWithdrawals = reportData['totalWithdrawals'];
    final double closingBalance = reportData['closingBalance'];

    // 3. بناء صفحات التقرير
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: ttf, bold: boldTtf),
        header: (context) => _buildHeader(logoImage),
        build: (context) => [
          _buildReportTitle(from, to),
          pw.SizedBox(height: 20),
          _buildFinancialSummary(openingBalance, totalDeposits, totalWithdrawals, closingBalance),
          pw.SizedBox(height: 20),
          _buildTransactionsTable(transactions, openingBalance),
        ],
        footer: (context) => _buildFooter(context),
      ),
    );

    // 4. حفظ وفتح الملف
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/fund_report_${intl.DateFormat('yyyy-MM-dd').format(from)}_to_${intl.DateFormat('yyyy-MM-dd').format(to)}.pdf');
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }

  // --- دوال بناء أجزاء التقرير ---

  static pw.Widget _buildHeader(pw.MemoryImage logo) {
    // (نفس دالة الهيدر من التقارير السابقة)
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 15),
      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey, width: 1.5))),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('شركة إيهاب للتجارة', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
              pw.SizedBox(height: 5),
              pw.Text('هاتف: 777-777-777', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('البريد الإلكتروني: info@ehab-company.com', style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
          pw.SizedBox(height: 60, width: 60, child: pw.Image(logo)),
        ],
      ),
    );
  }

  static pw.Widget _buildReportTitle(DateTime from, DateTime to) {
    return pw.Column(
      children: [
        pw.SizedBox(height: 15),

        pw.Text(
          'تقرير حركة الصندوق',
          style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'للفترة من: ${intl.DateFormat('yyyy-MM-dd').format(from)}   إلى: ${intl.DateFormat('yyyy-MM-dd').format(to)}',
          style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
        ),
      ],
    );
  }

  static pw.Widget _buildFinancialSummary(double opening, double deposits, double withdrawals, double closing) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('الرصيد الافتتاحي', opening),
          _buildSummaryItem('إجمالي الوارد', deposits, color: PdfColors.green),
          _buildSummaryItem('إجمالي الصادر', withdrawals, color: PdfColors.red),
          _buildSummaryItem('الرصيد الختامي', closing),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryItem(String label, double value, {PdfColor? color}) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 11)),
        pw.SizedBox(height: 4),
        pw.Text(
          '${intl.NumberFormat.decimalPattern('ar').format(value)} ريال',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: color ?? PdfColors.blueGrey800),
        ),
      ],
    );
  }

  static pw.Widget _buildTransactionsTable(List<FundTransactionModel> transactions, double openingBalance) {
    final headers = ['الرصيد', 'صادر', 'وارد', 'الوصف', 'التاريخ'];
    double currentBalance = openingBalance;

    final data = transactions.map((tx) {
      final deposit = tx.type == TransactionType.DEPOSIT ? tx.amount : 0.0;
      final withdrawal = tx.type == TransactionType.WITHDRAWAL ? tx.amount : 0.0;
      currentBalance = currentBalance + deposit - withdrawal;

      return [
        intl.NumberFormat.decimalPattern('ar').format(currentBalance),
        intl.NumberFormat.decimalPattern('ar').format(withdrawal),
        intl.NumberFormat.decimalPattern('ar').format(deposit),
        tx.description,
        intl.DateFormat('yyyy-MM-dd').format(tx.transactionDate),
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      cellAlignment: pw.Alignment.centerRight,
      cellStyle: const pw.TextStyle(fontSize: 10),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 11),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey600),
      rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200))),
      headers: headers,
      data: data,
      columnWidths: {
        0: const pw.FlexColumnWidth(2.5),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(4),
        4: const pw.FlexColumnWidth(2),
      },
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

