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

    // --- 1. بداية التعديل: تحميل الخطوط والشعار بالكامل ---
    final font = await rootBundle.load("assets/fonts/Tajawal-Regular.ttf");
    final boldFont = await rootBundle.load("assets/fonts/Tajawal-Bold.ttf");
    final ttf = pw.Font.ttf(font);
    final boldTtf = pw.Font.ttf(boldFont);

    final logoImage = pw.MemoryImage(
      (await rootBundle.load('assets/images/logo.png')).buffer.asUint8List(),
    );
    // --- نهاية التعديل ---


    // --- تحديد البيانات بناءً على نوع السند ---
    final bool isSupplier = transaction is SupplierTransactionModel;
    final String docTitle; // "سند دفع" أو "سند قبض"
    final String partyLabel; // "استلمنا من السيد/ة" أو "صرفنا للسيد/ة"
    final String partyName;
    final String transactionId = transaction.id.toString();
    final double amount = transaction.amount;
    final String date = intl.DateFormat('yyyy-MM-dd').format(transaction.transactionDate);
    final String notes = transaction.notes ?? 'لا توجد ملاحظات';

    if (isSupplier) {
      final voucher = transaction as SupplierTransactionModel;
      docTitle = 'سند صرف';
      partyLabel = 'صُرف للسيد/ة';
      partyName = voucher.supplierName ?? 'مورد غير محدد';
    } else {
      final voucher = transaction as CustomerTransactionModel;
      docTitle = 'سند قبض';
      partyLabel = 'استلمنا من السيد/ة';
      partyName = voucher.customerName ?? 'عميل غير محدد';
    }
    // --- نهاية تحديد البيانات ---

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5, // حجم A5 مناسب للسندات
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: ttf, bold: boldTtf),
        build: (context) {
          return pw.Column(
            children: [
              _buildHeader(logoImage), // <-- رأس الصفحة الموحد
              pw.SizedBox(height: 20),
              _buildVoucherTitle(docTitle, transactionId, date), // <-- عنوان السند الجديد
              pw.SizedBox(height: 30),
              _buildVoucherBody(partyLabel, partyName, amount, notes), // <-- محتوى السند الجديد
              pw.Spacer(),
              _buildFooter(), // <-- تذييل التوقيعات الجديد
            ],
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

  // --- 2. دوال بناء أجزاء السند (بتصميم متوافق مع الهوية البصرية) ---

  static pw.Widget _buildHeader(pw.MemoryImage logo) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('شركة إيهاب للتجارة', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
            pw.SizedBox(height: 5),
            pw.Text('هاتف: 777-777-777', style: const pw.TextStyle(fontSize: 9)),
          ],
        ),
        pw.SizedBox(height: 50, width: 50, child: pw.Image(logo)),
      ],
    );
  }

  static pw.Widget _buildVoucherTitle(String title, String id, String date) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 5),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(width: 2, color: PdfColors.black)),
          ),
          child: pw.Text(title, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
        ),
        pw.SizedBox(height: 20),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('رقم السند: $id', style: const pw.TextStyle(fontSize: 11)),
            pw.Text('التاريخ: $date', style: const pw.TextStyle(fontSize: 11)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildVoucherBody(String partyLabel, String partyName, double amount, String notes) {
    String numberToWords(double number) {
      // يمكن استبداله بمكتبة تفقيط حقيقية إذا لزم الأمر
      return 'فقط ${intl.NumberFormat.decimalPattern('ar').format(number)} ريال لا غير.';
    }

    return pw.Column(
      children: [
        _buildInfoRow(partyLabel, partyName),
        pw.SizedBox(height: 15),
        _buildInfoRow('مبلغ وقدره:', '${intl.NumberFormat.decimalPattern('ar').format(amount)} ريال'),
        pw.SizedBox(height: 10),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(5),
          ),
          child: pw.Text(
            numberToWords(amount),
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
          ),
        ),
        pw.SizedBox(height: 15),
        _buildInfoRow('وذلك عن:', notes),
      ],
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 90,
          child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
        ),
        pw.Expanded(
          child: pw.Text(value, style: const pw.TextStyle(fontSize: 13)),
        ),
      ],
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
      children: [
        _buildSignature('المحاسب'),
        _buildSignature('المستلم'),
      ],
    );
  }

  static pw.Widget _buildSignature(String title) {
    return pw.Column(
      children: [
        pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
        pw.SizedBox(height: 5),
        pw.Text('.......................', style: const pw.TextStyle(color: PdfColors.grey600)),
        pw.SizedBox(height: 5),
        pw.Text('التوقيع:', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
      ],
    );
  }
}
