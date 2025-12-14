// File: lib/core/services/customer_report_service.dart

import 'dart:io';
import 'package:ehab_company_admin/features/customers/data/models/customer_model.dart';
import 'package:ehab_company_admin/features/customers/data/models/customer_transaction_model.dart';
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart' as intl;

class CustomerReportService {
  static Future<void> printCustomerStatement({
    required CustomerModel customer,
    required List<CustomerTransactionModel> transactions,
  }) async {
    final pdf = pw.Document();

    final fontData = await rootBundle.load("assets/fonts/Tajawal-Regular.ttf");
    final arabicFont = pw.Font.ttf(fontData);
    final textStyle = pw.TextStyle(font: arabicFont, fontSize: 10);
    final headerStyle = pw.TextStyle(font: arabicFont, fontWeight: pw.FontWeight.bold, fontSize: 11);

    final formatCurrency = intl.NumberFormat("#,##0.00", "ar_SA");

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        build: (context) => [
          _buildHeader(customer, textStyle, headerStyle),
          pw.SizedBox(height: 20),
          _buildTable(transactions, customer, textStyle, headerStyle, formatCurrency),
          pw.Divider(),
        ],
        header: (context) => _buildPageHeader(context, headerStyle),
        footer: (context) => _buildPageFooter(context, textStyle),
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/customer_statement_${customer.id}.pdf');
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }

  static pw.Widget _buildHeader(CustomerModel customer, pw.TextStyle textStyle, pw.TextStyle boldStyle) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('كشف حساب العميل', style: boldStyle.copyWith(fontSize: 18, color: PdfColors.blueGrey800)),
        pw.Divider(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('اسم العميل: ${customer.name}', style: boldStyle),
            pw.Text('تاريخ الطباعة: ${intl.DateFormat('yyyy-MM-dd').format(DateTime.now())}', style: textStyle),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTable(
      List<CustomerTransactionModel> transactions,
      CustomerModel customer,
      pw.TextStyle textStyle,
      pw.TextStyle headerStyle,
      intl.NumberFormat formatCurrency,
      ) {
    final headers = ['التاريخ', 'رقم السند', 'البيان', 'مدين (+)', 'دائن (-)', 'الرصيد'];

    final orderedTransactions = transactions.reversed.toList();
    double openingBalance = customer.balance;

    for (final trans in orderedTransactions) {
      if (trans.type == CustomerTransactionType.RECEIPT) {
        openingBalance += trans.amount;
      } else {
        openingBalance -= trans.amount;
      }
    }

    final List<List<pw.Widget>> tableData = [];
    double runningBalance = openingBalance;

    tableData.add([
      pw.Text('', style: textStyle),
      pw.Text('', style: textStyle),
      pw.Text('رصيد بداية الفترة', style: headerStyle),
      pw.Text('', style: textStyle),
      pw.Text('', style: textStyle),
      pw.Text(formatCurrency.format(runningBalance), style: textStyle),
    ]);

    for (final trans in orderedTransactions) {
      double debit = 0;
      double credit = 0;

      // --- بداية التعديل المنطقي ---
      // المنطق معكوس عن الموردين
      if (trans.type == CustomerTransactionType.RECEIPT) {
        credit = trans.amount; // الدفعة من العميل هي "دائن" (تقلل الدين)
        runningBalance -= credit;
      } else { // فاتورة بيع أو رصيد افتتاحي
        debit = trans.amount; // البيع هو "مدين" (يزيد الدين)
        runningBalance += debit;
      }
      // --- نهاية التعديل المنطقي ---

      final description = trans.notes?.isNotEmpty == true ? trans.notes! : (trans.type == CustomerTransactionType.RECEIPT ? 'سند قبض' : (trans.type == CustomerTransactionType.SALE ? 'فاتورة بيع' : 'رصيد افتتاحي'));

      tableData.add([
        pw.Text(intl.DateFormat('yyyy-MM-dd').format(trans.transactionDate), style: textStyle),
        pw.Text(trans.id.toString(), style: textStyle),
        pw.Text(description, style: textStyle),
        pw.Text(debit > 0 ? formatCurrency.format(debit) : '', style: textStyle.copyWith(color: PdfColors.red800)),
        pw.Text(credit > 0 ? formatCurrency.format(credit) : '', style: textStyle.copyWith(color: PdfColors.green800)),
        pw.Text(formatCurrency.format(runningBalance), style: textStyle),
      ]);
    }

    tableData.add([
      pw.Text(''),
      pw.Text(''),
      pw.Text('الرصيد النهائي المستحق', style: headerStyle.copyWith(fontSize: 12)),
      pw.Text(''),
      pw.Text(''),
      pw.Text(formatCurrency.format(customer.balance), style: headerStyle.copyWith(fontSize: 12)),
    ]);

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(4),
        3: const pw.FlexColumnWidth(2),
        4: const pw.FlexColumnWidth(2),
        5: const pw.FlexColumnWidth(2.5),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
          children: headers.map((header) => pw.Padding(
            padding: const pw.EdgeInsets.all(5),
            child: pw.Text(header, style: headerStyle.copyWith(color: PdfColors.white)),
          )).toList(),
        ),
        ...tableData.map((row) => pw.TableRow(
          children: row.map((cell) => pw.Padding(
            padding: const pw.EdgeInsets.all(5),
            child: pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: cell,
            ),
          )).toList(),
        )),
      ],
    );
  }

  static pw.Widget _buildPageHeader(pw.Context context, pw.TextStyle boldStyle) {
    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(bottom: 20.0),
      child: pw.Text('شركة إيهاب', style: boldStyle.copyWith(fontSize: 16)),
    );
  }

  static pw.Widget _buildPageFooter(pw.Context context, pw.TextStyle textStyle) {
    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(top: 20.0),
      child: pw.Text('صفحة ${context.pageNumber} من ${context.pagesCount}', style: textStyle),
    );
  }
}
