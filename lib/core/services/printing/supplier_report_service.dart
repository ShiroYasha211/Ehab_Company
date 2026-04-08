// File: lib/core/services/printing/supplier_report_service.dart

import 'dart:io';
import 'package:ehab_company_admin/features/suppliers/data/models/supplier_model.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart' as intl;
import 'pdf_base_service.dart';

class SupplierReportService {
  static Future<void> printSupplierStatement({
    required SupplierModel supplier,
    required List<Map<String, dynamic>> transactions,
    required double openingBalance,
  }) async {
    final pdf = pw.Document();

    final resources = await PdfBaseService.loadResources();
    final pw.Font ttf = resources['ttf'];
    final pw.Font boldTtf = resources['boldTtf'];
    final pw.MemoryImage logo = resources['logo'];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: ttf, bold: boldTtf),
        header: (context) => PdfBaseService.buildHeader(logo: logo, boldTtf: boldTtf, ttf: ttf),
        footer: (context) => PdfBaseService.buildFooter(context, ttf),
        build: (context) => [
          _buildReportTitle(supplier, boldTtf, ttf),
          pw.SizedBox(height: 20),
          _buildFinancialSummary(openingBalance, supplier.balance, boldTtf, ttf),
          pw.SizedBox(height: 20),
          _buildTransactionsTable(transactions, openingBalance, boldTtf, ttf),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/supplier_statement_${supplier.id}.pdf');
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }

  static pw.Widget _buildReportTitle(SupplierModel supplier, pw.Font boldTtf, pw.Font ttf) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 20),
      child: pw.Column(
        children: [
          PdfBaseService.safeText('كشف حساب المورد', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, font: boldTtf, color: PdfColors.indigo900)),
          pw.SizedBox(height: 10),
          PdfBaseService.safeText(PdfBaseService.sanitize(supplier.name), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, font: boldTtf)),
          pw.SizedBox(height: 5),
          PdfBaseService.safeText('تاريخ الطباعة: ${intl.DateFormat('yyyy-MM-dd').format(DateTime.now())}', style: pw.TextStyle(fontSize: 10, font: ttf, color: PdfColors.grey600)),
        ],
      ),
    );
  }

  static pw.Widget _buildFinancialSummary(double openingBalance, double closingBalance, pw.Font boldTtf, pw.Font ttf) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.indigo.shade(0.01), 
        borderRadius: pw.BorderRadius.circular(8), 
        border: pw.Border.all(color: PdfColors.indigo100)
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('الرصيد السابق', openingBalance, boldTtf, ttf),
          _buildSummaryItem('الرصيد النهائي المستحق', closingBalance, boldTtf, ttf, isTotal: true),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryItem(String label, double value, pw.Font boldTtf, pw.Font ttf, {bool isTotal = false}) {
    return pw.Column(
      children: [
        PdfBaseService.safeText(label, style: pw.TextStyle(fontSize: 10, font: ttf, color: PdfColors.grey700)),
        pw.SizedBox(height: 4),
        PdfBaseService.safeText(
          PdfBaseService.formatCurrency(value),
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: isTotal ? 16 : 14, font: boldTtf, color: isTotal ? PdfColors.indigo900 : PdfColors.black),
        ),
      ],
    );
  }

  static pw.Widget _buildTransactionsTable(List<Map<String, dynamic>> transactions, double openingBalance, pw.Font boldTtf, pw.Font ttf) {
    double runningBalance = openingBalance;

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.3),
      columnWidths: {
        0: const pw.FlexColumnWidth(2.5),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(4),
        4: const pw.FlexColumnWidth(2),
        5: const pw.FixedColumnWidth(25),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.indigo900),
          children: [
            PdfBaseService.tableCell('الرصيد', boldTtf, color: PdfColors.white, weight: pw.FontWeight.bold, size: 9),
            PdfBaseService.tableCell('مدين (-)', boldTtf, color: PdfColors.white, weight: pw.FontWeight.bold, size: 9),
            PdfBaseService.tableCell('دائن (+)', boldTtf, color: PdfColors.white, weight: pw.FontWeight.bold, size: 9),
            PdfBaseService.tableCell('البيان', boldTtf, color: PdfColors.white, weight: pw.FontWeight.bold, size: 9),
            PdfBaseService.tableCell('التاريخ', boldTtf, color: PdfColors.white, weight: pw.FontWeight.bold, size: 9),
            PdfBaseService.tableCell('#', boldTtf, color: PdfColors.white, weight: pw.FontWeight.bold, size: 9),
          ],
        ),
        ...List.generate(transactions.length, (index) {
          final trans = transactions[index];
          double debit = 0;
          double credit = 0;

          if (trans['type'] == 'PAYMENT') {
            debit = (trans['amount'] as num).toDouble();
            runningBalance -= debit;
          } else {
            credit = (trans['amount'] as num).toDouble();
            runningBalance += credit;
          }

          final String? notes = trans['notes'];
          final description = notes?.isNotEmpty == true
              ? notes!
              : (trans['type'] == 'PAYMENT'
                    ? 'سند صرف'
                    : (trans['type'] == 'PURCHASE'
                          ? 'فاتورة مشتريات #${trans['referenceId']}'
                          : 'رصيد افتتاحي'));

          return pw.TableRow(
            decoration: pw.BoxDecoration(color: index % 2 == 1 ? PdfColors.indigo.shade(0.01) : PdfColors.white),
            children: [
              PdfBaseService.tableCell(intl.NumberFormat.decimalPattern('ar').format(runningBalance), ttf, size: 9, weight: pw.FontWeight.bold),
              PdfBaseService.tableCell(debit > 0 ? intl.NumberFormat.decimalPattern('ar').format(debit) : '', ttf, size: 9, color: PdfColors.red800),
              PdfBaseService.tableCell(credit > 0 ? intl.NumberFormat.decimalPattern('ar').format(credit) : '', ttf, size: 9, color: PdfColors.green800),
              PdfBaseService.tableCell(PdfBaseService.sanitize(description), ttf, size: 9),
              PdfBaseService.tableCell(intl.DateFormat('yyyy-MM-dd').format(DateTime.parse(trans['transactionDate'].toString())), ttf, size: 9),
              PdfBaseService.tableCell((index + 1).toString(), ttf, size: 9),
            ],
          );
        }),
      ],
    );
  }
}
