// File: lib/core/services/printing/customer_report_service.dart

import 'dart:io';
import 'package:ehab_company_admin/features/customers/data/models/customer_model.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart' as intl;
import 'pdf_base_service.dart';

class CustomerReportService {
  static Future<void> printCustomerStatement({
    required CustomerModel customer,
    required List<Map<String, dynamic>> transactions,
    required double openingBalance,
  }) async {
    final pdf = pw.Document();

    final resources = await PdfBaseService.loadResources();
    final pw.Font ttf = resources['ttf'];
    final pw.Font boldTtf = resources['boldTtf'];
    final pw.MemoryImage logo = resources['logo'];

    double totalCredit = 0;
    double totalDebit = 0;

    for (var t in transactions) {
      final type = t['type'];
      final amount = (t['amount'] as num?)?.toDouble() ?? 0.0;
      if (type == 'RECEIPT' || type == 'RETURN') {
        totalCredit += amount;
      } else if (type == 'SALE' || type == 'OPENING_BALANCE') {
        totalDebit += amount;
      }
    }
    
    final double closingBalance = openingBalance + totalDebit - totalCredit;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: ttf, bold: boldTtf),
        header: (context) => PdfBaseService.buildHeader(logo: logo, boldTtf: boldTtf, ttf: ttf),
        footer: (context) => PdfBaseService.buildFooter(context, ttf),
        build: (context) => [
          _buildReportTitle(customer),
          _buildCustomerProfile(customer, ttf, boldTtf),
          pw.SizedBox(height: 20),
          _buildFinancialDashboard(openingBalance, totalDebit, totalCredit, closingBalance),
          pw.SizedBox(height: 20),
          _buildTransactionsTable(transactions, openingBalance),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/customer_statement_${customer.id}.pdf');
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }

  static pw.Widget _buildReportTitle(CustomerModel customer) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Column(
        children: [
          PdfBaseService.safeText('كشف حساب عميل', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
          pw.SizedBox(height: 5),
          PdfBaseService.safeText('تاريخ التقرير: ${intl.DateFormat('yyyy-MM-dd | hh:mm a').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
        ],
      ),
    );
  }

  static pw.Widget _buildCustomerProfile(CustomerModel customer, pw.Font ttf, pw.Font boldTtf) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      margin: const pw.EdgeInsets.only(top: 15),
      decoration: pw.BoxDecoration(color: PdfColors.white, borderRadius: pw.BorderRadius.circular(8), border: pw.Border.all(color: PdfColors.grey300, width: 0.5)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              PdfBaseService.safeText('العميل: ', style: pw.TextStyle(fontSize: 10, color: PdfColors.indigo900, font: boldTtf)),
              PdfBaseService.safeText(customer.name, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, font: boldTtf)),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            children: [
              pw.Expanded(child: PdfBaseService.safeText('الهاتف: ${customer.phone ?? "غير متوفر"}', style: const pw.TextStyle(fontSize: 9))),
              pw.Expanded(child: PdfBaseService.safeText('الشركة: ${customer.company ?? "جهة خاصة"}', style: const pw.TextStyle(fontSize: 9))),
            ],
          ),
          if (customer.address != null) ...[
            pw.SizedBox(height: 5),
            PdfBaseService.safeText('العنوان: ${customer.address}', style: const pw.TextStyle(fontSize: 9)),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildFinancialDashboard(double opening, double debit, double credit, double closing) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        PdfBaseService.buildStatCard('الرصيد السابق', PdfBaseService.formatCurrency(opening)),
        PdfBaseService.buildStatCard('إجمالي السحب', PdfBaseService.formatCurrency(debit), color: PdfColors.red800),
        PdfBaseService.buildStatCard('إجمالي المدفوع', PdfBaseService.formatCurrency(credit), color: PdfColors.green800),
        PdfBaseService.buildStatCard('الرصيد الحالي', PdfBaseService.formatCurrency(closing), color: PdfColors.indigo900),
      ],
    );
  }

  static pw.Widget _buildTransactionsTable(List<Map<String, dynamic>> transactions, double openingBalance) {
    final headers = ['الرصيد', 'دائن (+)', 'مدين (-)', 'البيان', 'التاريخ'];
    double runningBalance = openingBalance;

    final data = transactions.map((trans) {
      final type = trans['type'];
      final amount = (trans['amount'] as num?)?.toDouble() ?? 0.0;
      final double debit = (type == 'SALE' || type == 'OPENING_BALANCE') ? amount : 0;
      final double credit = (type == 'RECEIPT' || type == 'RETURN') ? amount : 0;
      
      runningBalance = runningBalance + debit - credit;

      final String? notes = trans['notes'];
      final refId = trans['referenceId'] ?? '-';
      final description = notes?.isNotEmpty == true
          ? notes!
          : (type == 'RECEIPT'
                ? 'سند قبض'
                : (type == 'SALE'
                      ? 'فاتورة مبيعات #$refId'
                      : (type == 'RETURN' ? 'مرتجع مبيعات #$refId' : 'رصيد افتتاحي')));

      String dateStr = '-';
      try {
        final dynamic dateVal = trans['transactionDate'];
        if (dateVal is DateTime) {
          dateStr = intl.DateFormat('yyyy-MM-dd').format(dateVal);
        } else if (dateVal != null) {
          dateStr = intl.DateFormat('yyyy-MM-dd').format(DateTime.parse(dateVal.toString()));
        }
      } catch (_) {}

      return [
        PdfBaseService.sanitize(intl.NumberFormat.decimalPattern('ar').format(runningBalance)),
        credit > 0 ? PdfBaseService.sanitize(intl.NumberFormat.decimalPattern('ar').format(credit)) : '',
        debit > 0 ? PdfBaseService.sanitize(intl.NumberFormat.decimalPattern('ar').format(debit)) : '',
        PdfBaseService.sanitize(description),
        dateStr,
      ];
    }).toList();

    return pw.Table.fromTextArray(
      headers: headers,
      data: data,
      cellAlignment: pw.Alignment.centerRight,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo900),
      rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200))),
      cellStyle: const pw.TextStyle(fontSize: 8.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1.8),
        2: const pw.FlexColumnWidth(1.8),
        3: const pw.FlexColumnWidth(4.5),
        4: const pw.FlexColumnWidth(1.8),
      },
    );
  }
}
