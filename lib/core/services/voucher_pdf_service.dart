// File: lib/core/services/voucher_pdf_service.dart

import 'dart:io';
import 'package:ehab_company_admin/features/customers/data/models/customer_transaction_model.dart';
import 'package:ehab_company_admin/features/suppliers/data/models/supplier_transaction_model.dart';
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart' as intl;

class VoucherPdfService {
  static Future<void> printVoucher(dynamic transaction) async {
    final pdf = pw.Document();
    final fontData = await rootBundle.load("assets/fonts/Tajawal-Regular.ttf");
    final arabicFont = pw.Font.ttf(fontData);

    // --- تحديد البيانات بناءً على نوع السند ---
    final bool isSupplier = transaction is SupplierTransactionModel;
    final String docTitle; // "سند دفع" أو "سند قبض"
    final String partyLabel; // "المورد" أو "العميل"
    final String partyName;
    final String transactionId = transaction.id.toString();
    final double amount = transaction.amount;
    final String date = intl.DateFormat('yyyy-MM-dd').format(transaction.transactionDate);
    final String notes = transaction.notes ?? 'لا توجد ملاحظات';

    if (isSupplier) {
      final voucher = transaction;
      docTitle = voucher.type == SupplierTransactionType.PAYMENT ? 'سند دفع' : 'رصيد افتتاحي';
      partyLabel = 'إلى المورد';
      partyName = voucher.supplierName ?? 'غير محدد';
    } else {
      final voucher = transaction as CustomerTransactionModel;
      docTitle = voucher.type == CustomerTransactionType.RECEIPT ? 'سند قبض' : 'رصيد افتتاحي';
      partyLabel = 'من العميل';
      partyName = voucher.customerName ?? 'غير محدد';
    }
    // --- نهاية تحديد البيانات ---

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5, // حجم A5 مناسب للسندات
        textDirection: pw.TextDirection.rtl,
        build: (context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildHeader(docTitle, transactionId, date, arabicFont),
                pw.SizedBox(height: 30),
                _buildBody(partyLabel, partyName, amount, notes, arabicFont),
                pw.Spacer(),
                _buildFooter(arabicFont),
              ],
            ),
          );
        },
      ),
    );

    // حفظ وفتح الملف
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/voucher_$transactionId.pdf');
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }

  static pw.Widget _buildHeader(String title, String id, String date, pw.Font font) {
    return pw.Column(
      children: [
        pw.Text('شركة إيهاب', style: pw.TextStyle(font: font, fontSize: 20, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 20),
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black),
            borderRadius: pw.BorderRadius.circular(5),
          ),
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(title, style: pw.TextStyle(font: font, fontSize: 22, fontWeight: pw.FontWeight.bold)),
        ),
        pw.SizedBox(height: 20),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('رقم السند: $id', style: pw.TextStyle(font: font)),
            pw.Text('التاريخ: $date', style: pw.TextStyle(font: font)),
          ],
        ),
        pw.Divider(thickness: 1.5, height: 20),
      ],
    );
  }

  static pw.Widget _buildBody(String partyLabel, String partyName, double amount, String notes, pw.Font font) {
    // دالة لتحويل الرقم إلى نص (تفقيط)
    String numberToWords(double number) {
      // هذا مجرد مثال بسيط، يمكن استبداله بمكتبة تفقيط حقيقية إذا لزم الأمر
      return 'فقط ${intl.NumberFormat.decimalPattern('ar').format(number)} ريال لا غير.';
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildInfoRow('$partyLabel:', partyName, font, isLarge: true),
        pw.SizedBox(height: 20),
        _buildInfoRow('مبلغ وقدره:', '${intl.NumberFormat.currency(locale: 'ar', symbol: 'ر.ي').format(amount)}', font, isLarge: true),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey),
            borderRadius: pw.BorderRadius.circular(5),
          ),
          child: pw.Text(
            numberToWords(amount),
            style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.SizedBox(height: 20),
        _buildInfoRow('وذلك عن:', notes, font),
      ],
    );
  }

  static pw.Widget _buildInfoRow(String label, String value, pw.Font font, {bool isLarge = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(label, style: pw.TextStyle(font: font, fontSize: isLarge ? 14 : 12, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Expanded(
            child: pw.Text(value, style: pw.TextStyle(font: font, fontSize: isLarge ? 14 : 12)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Font font) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
      children: [
        pw.Column(children: [
          pw.Text('المحاسب', style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 5),
          pw.Text('................', style: pw.TextStyle(font: font)),
        ]),
        pw.Column(children: [
          pw.Text('المستلم', style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 5),
          pw.Text('................', style: pw.TextStyle(font: font)),
        ]),
      ],
    );
  }
}
