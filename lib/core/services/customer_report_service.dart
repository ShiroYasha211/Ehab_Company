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
    required double openingBalance, // سنستقبل الرصيد الافتتاحي جاهزًا
  }) async {
    final pdf = pw.Document();

    // --- 1. بداية التعديل: تحميل الخطوط والشعار بالكامل ---
    final font = await rootBundle.load("assets/fonts/Tajawal-Regular.ttf");
    final boldFont = await rootBundle.load("assets/fonts/Tajawal-Bold.ttf");
    final ttf = pw.Font.ttf(font);
    final boldTtf = pw.Font.ttf(boldFont);

    final logoImage = pw.MemoryImage(
      (await rootBundle.load('assets/images/logo.png')).buffer.asUint8List(),
    );
    // --- نهاية التعديل ---

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: ttf, bold: boldTtf),
        header: (context) => _buildHeader(logoImage), // <-- رأس الصفحة الموحد
        build: (context) => [
          _buildReportTitle(customer), // <-- عنوان التقرير ومعلومات العميل
          pw.SizedBox(height: 20),
          _buildFinancialSummary(openingBalance, customer.balance), // <-- الملخص المالي الجديد
          pw.SizedBox(height: 20),
          _buildTransactionsTable(transactions, openingBalance), // <-- جدول الحركات المحسن
        ],
        footer: (context) => _buildFooter(context), // <-- تذييل الصفحة الموحد
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/customer_statement_${customer.id}.pdf');
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }

  // --- 2. دوال بناء أجزاء التقرير (بتصميم متوافق مع الهوية البصرية) ---

  static pw.Widget _buildHeader(pw.MemoryImage logo) {
    // (نفس دالة الهيدر من التقارير السابقة)
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 15),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey, width: 1.5)),
      ),
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

  static pw.Widget _buildReportTitle(CustomerModel customer) {
    return pw.Padding(
        padding: const pw.EdgeInsets.only(top: 20),
        child: pw.Column(
          children: [
            pw.Text('كشف حساب العميل', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
            pw.SizedBox(height: 10),
            pw.Text(customer.name, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 5),
            pw.Text('تاريخ الطباعة: ${intl.DateFormat('yyyy-MM-dd').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
          ],
        ));
  }

  static pw.Widget _buildFinancialSummary(double openingBalance, double closingBalance) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
          color: PdfColors.blue.shade(0.05),
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColors.blue200)),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('الرصيد السابق', openingBalance),
          _buildSummaryItem('الرصيد النهائي المستحق', closingBalance, isTotal: true),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryItem(String label, double value, {bool isTotal = false}) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 11)),
        pw.SizedBox(height: 4),
        pw.Text(
          '${intl.NumberFormat.decimalPattern('ar').format(value)} ريال',
          style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? PdfColors.blue800 : PdfColors.black),
        ),
      ],
    );
  }

  static pw.Widget _buildTransactionsTable(List<CustomerTransactionModel> transactions, double openingBalance) {
    final headers = ['الرصيد', 'دائن (-)', 'مدين (+)', 'البيان', 'التاريخ'];
    double runningBalance = openingBalance;

    final data = transactions.map((trans) {
      double debit = 0;
      double credit = 0;

      if (trans.type == CustomerTransactionType.RECEIPT) {
        credit = trans.amount; // الدفعة من العميل (سند قبض) تقلل الدين
        runningBalance -= credit;
      } else { // فاتورة بيع أو رصيد افتتاحي
        debit = trans.amount; // البيع للعميل يزيد الدين
        runningBalance += debit;
      }
      final description = trans.notes?.isNotEmpty == true
          ? trans.notes!

          : (trans.type == CustomerTransactionType.RECEIPT ? 'سند قبض' : (trans.type == CustomerTransactionType.SALE ? 'فاتورة بيع #${trans.referenceId}' : 'رصيد افتتاحي'));

      return [
        '${intl.NumberFormat.decimalPattern('ar').format(runningBalance)}',
        credit > 0 ? '${intl.NumberFormat.decimalPattern('ar').format(credit)}' : '',
        debit > 0 ? '${intl.NumberFormat.decimalPattern('ar').format(debit)}' : '',
        description,
        intl.DateFormat('yyyy-MM-dd').format(trans.transactionDate),
      ];
    }).toList();

    return pw.Table.fromTextArray(
        cellAlignment: pw.Alignment.centerRight,
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 11),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
        rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200))),
        headers: headers,
        data: data,
        columnWidths: {
          0: const pw.FlexColumnWidth(2.5), // الرصيد
          1: const pw.FlexColumnWidth(2),   // دائن
          2: const pw.FlexColumnWidth(2),   // مدين
          3: const pw.FlexColumnWidth(4),   // البيان
          4: const pw.FlexColumnWidth(2),   // التاريخ
        },
        cellStyle: const pw.TextStyle(fontSize: 10),
        cellAlignments: { // محاذاة الأعمدة الرقمية لليسار
          0: pw.Alignment.centerLeft,
          1: pw.Alignment.centerLeft,
          2: pw.Alignment.centerLeft,
          4: pw.Alignment.centerLeft,
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
