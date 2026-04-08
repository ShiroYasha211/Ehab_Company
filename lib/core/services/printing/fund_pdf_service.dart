// File: lib/core/services/printing/fund_pdf_service.dart

import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart' as intl;
import 'pdf_base_service.dart';

class FundPdfService {
  static Future<void> printFundTransactions(List<Map<String, dynamic>> transactions, {
    String? fundName, 
    String? dateRange,
    double openingBalance = 0.0,
  }) async {
    final pdf = pw.Document();

    final resources = await PdfBaseService.loadResources();
    final pw.Font ttf = resources['ttf'];
    final pw.Font boldTtf = resources['boldTtf'];
    final pw.MemoryImage logo = resources['logo'];

    final double totalIn = transactions
        .where((t) => (t['type'] == 'DEPOSIT'))
        .fold(0.0, (prev, t) => prev + (t['amount'] as num).toDouble());
    
    final double totalOut = transactions
        .where((t) => (t['type'] == 'WITHDRAWAL'))
        .fold(0.0, (prev, t) => prev + (t['amount'] as num).toDouble());

    final double closingBalance = openingBalance + totalIn - totalOut;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: ttf, bold: boldTtf),
        header: (context) => PdfBaseService.buildHeader(logo: logo, boldTtf: boldTtf, ttf: ttf),
        footer: (context) => PdfBaseService.buildFooter(context, ttf),
        build: (context) => [
          _buildReportTitle(fundName, dateRange),
          pw.SizedBox(height: 15),
          _buildSummary(openingBalance, totalIn, totalOut, closingBalance),
          pw.SizedBox(height: 20),
          _buildTransactionsTable(transactions, openingBalance),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/fund_report.pdf');
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }

  static pw.Widget _buildReportTitle(String? fund, String? range) {
    return pw.Column(
      children: [
        pw.SizedBox(height: 15),
        PdfBaseService.safeText('تقرير كشف حركات الصندوق (تحليلي)', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
        if (fund != null) PdfBaseService.safeText('اسم الصندوق: $fund', style: const pw.TextStyle(fontSize: 11)),
        if (range != null) PdfBaseService.safeText('فترة الكشف: $range', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        pw.SizedBox(height: 5),
        PdfBaseService.safeText('تاريخ الطباعة: ${intl.DateFormat('yyyy-MM-dd | hh:mm a').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
      ],
    );
  }

  static pw.Widget _buildSummary(double opening, double totalIn, double totalOut, double closing) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('الرصيد السابق', opening, PdfColors.grey800),
          _buildVerticalDivider(),
          _buildSummaryItem('إجمالي الداخل (+)', totalIn, PdfColors.green800),
          _buildVerticalDivider(),
          _buildSummaryItem('إجمالي الخارج (-)', totalOut, PdfColors.red800),
          _buildVerticalDivider(),
          _buildSummaryItem('الرصيد الحالي', closing, PdfColors.indigo900),
        ],
      ),
    );
  }

  static pw.Widget _buildVerticalDivider() {
    return pw.Container(height: 30, width: 0.5, color: PdfColors.grey300);
  }

  static pw.Widget _buildSummaryItem(String label, double amount, PdfColor color) {
    return pw.Column(
      children: [
        PdfBaseService.safeText(label, style: const pw.TextStyle(fontSize: 10)),
        pw.SizedBox(height: 4),
        PdfBaseService.safeText(PdfBaseService.formatCurrency(amount), 
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: color)),
      ],
    );
  }

  static pw.Widget _buildTransactionsTable(List<Map<String, dynamic>> transactions, double openingBalance) {
    final headers = ['الرصيد', 'دائن (+)', 'مدين (-)', 'المسؤول', 'البيان', 'التاريخ والوقت', '#'];
    
    double runningBalance = openingBalance;
    final List<List<String>> data = [];

    for (var i = 0; i < transactions.length; i++) {
      final t = transactions[i];
      final amount = (t['amount'] as num).toDouble();
      final type = t['type']?.toString().toUpperCase() ?? 'DEPOSIT';
      
      String credit = '', debit = '';
      if (type == 'DEPOSIT') {
        credit = intl.NumberFormat.decimalPattern('ar').format(amount);
        runningBalance += amount;
      } else {
        debit = intl.NumberFormat.decimalPattern('ar').format(amount);
        runningBalance -= amount;
      }

      String dateStr = '-';
      try {
        final dynamic dateVal = t['transactionDate'];
        if (dateVal is DateTime) {
          dateStr = '${intl.DateFormat('yyyy-MM-dd').format(dateVal)} | ${intl.DateFormat('hh:mm a').format(dateVal)}';
        } else if (dateVal != null) {
          final dt = DateTime.parse(dateVal.toString());
          dateStr = '${intl.DateFormat('yyyy-MM-dd').format(dt)} | ${intl.DateFormat('hh:mm a').format(dt)}';
        }
      } catch (_) {}

      data.add([
        PdfBaseService.sanitize(intl.NumberFormat.decimalPattern('ar').format(runningBalance)),
        PdfBaseService.sanitize(credit),
        PdfBaseService.sanitize(debit),
        PdfBaseService.sanitize(t['userName']?.toString() ?? '-'),
        PdfBaseService.sanitize(t['description']?.toString() ?? t['notes']?.toString() ?? '-'),
        PdfBaseService.sanitize(dateStr),
        (i + 1).toString(),
      ]);
    }

    return pw.Table.fromTextArray(
      headers: headers,
      data: data,
      cellAlignment: pw.Alignment.centerRight,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo900),
      rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200))),
      cellStyle: const pw.TextStyle(fontSize: 8),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.indigo50),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1.8),
        2: const pw.FlexColumnWidth(1.8),
        3: const pw.FlexColumnWidth(2),
        4: const pw.FlexColumnWidth(3.5),
        5: const pw.FlexColumnWidth(2.5),
        6: const pw.FixedColumnWidth(18),
      },
    );
  }
}
