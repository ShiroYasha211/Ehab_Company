// File: lib/core/services/voucher_pdf_service.dart

import 'dart:io';
import 'package:ehab_company_admin/features/suppliers/data/models/supplier_transaction_model.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart' as intl;
import 'tafqeet_service.dart';
import 'settings_service.dart';

class VoucherPdfService {
  static Future<void> printVoucher(dynamic transaction) async {
    final pdf = pw.Document();

    final font = await rootBundle.load("assets/fonts/Tajawal-Regular.ttf");
    final boldFont = await rootBundle.load("assets/fonts/Tajawal-Bold.ttf");
    final ttf = pw.Font.ttf(font);
    final boldTtf = pw.Font.ttf(boldFont);

    final logoImage = pw.MemoryImage(
      (await rootBundle.load('assets/images/logo.png')).buffer.asUint8List(),
    );

    final bool isSupplier = transaction is SupplierTransactionModel;
    final String docTitle = isSupplier ? 'سند صرف' : 'سند قبض';
    final String partyLabel = isSupplier ? 'صُرف للسيد/ة:' : 'استلمنا من السيد/ة:';
    final String partyName = isSupplier 
        ? (transaction.supplierName ?? 'مورد غير محدد')
        : (transaction.customerName ?? 'عميل غير محدد');
    
    final String transactionId = transaction.id.toString();
    final double amount = transaction.amount;
    final String date = intl.DateFormat('yyyy-MM-dd').format(transaction.transactionDate);
    final String notes = transaction.notes ?? 'لا توجد ملاحظات';

    String formatMoney(double val) {
      String symbol = Get.find<SettingsService>().primaryCurrency.value.symbol;
      if (symbol.contains('ر.ي') || symbol.contains('﷼')) {
        symbol = 'ريال';
      }
      final formatted = intl.NumberFormat.decimalPattern('ar').format(val);
      return _sanitize("$formatted $symbol");
    }

    final qrData = 'VOUCHER: #$transactionId\nTYPE: ${isSupplier ? "PAYMENT" : "RECEIPT"}\nDATE: $date\nAMOUNT: ${formatMoney(amount)}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        orientation: pw.PageOrientation.portrait,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: ttf, bold: boldTtf),
        build: (context) {
          return pw.Stack(
            children: [
              // العلامة المائية الخلفية (شعار خفيف)
              pw.Center(
                child: pw.Opacity(
                  opacity: 0.03,
                  child: pw.SizedBox(width: 200, height: 200, child: pw.Image(logoImage)),
                ),
              ),
              pw.Column(
                children: [
                  _buildHeader(logoImage, ttf, boldTtf, qrData),
                  pw.SizedBox(height: 15),
                  _buildTitleSection(docTitle, transactionId, date, boldTtf, ttf),
                  pw.SizedBox(height: 25),
                  _buildVoucherBody(partyLabel, partyName, amount, notes, formatMoney, ttf, boldTtf),
                  pw.Spacer(),
                  _buildFooter(ttf, boldTtf),
                  pw.SizedBox(height: 10),
                  pw.Divider(color: PdfColors.grey300, thickness: 0.5),
                  _safeText('نظام إيهاب للمحاسبة والمخازن', style: pw.TextStyle(fontSize: 7, font: ttf, color: PdfColors.grey500)),
                ],
              ),
            ],
          );
        },
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/voucher_$transactionId.pdf');
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }

  static pw.Widget _buildHeader(pw.MemoryImage logo, pw.Font ttf, pw.Font boldTtf, String qrData) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _safeText('شركة إيهاب للتجارة', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, font: boldTtf, color: PdfColors.indigo900)),
            _safeText('هاتف: 777-777-777', style: pw.TextStyle(fontSize: 8, font: ttf, color: PdfColors.grey700)),
          ],
        ),
        pw.Row(
          children: [
            pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: qrData,
              width: 35,
              height: 35,
              drawText: false,
            ),
            pw.SizedBox(width: 8),
            pw.SizedBox(height: 40, width: 40, child: pw.Image(logo)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTitleSection(String title, String id, String date, pw.Font boldTtf, pw.Font ttf) {
    return pw.Column(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.indigo900, width: 1.5)),
          ),
          child: _safeText(title, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, font: boldTtf, color: PdfColors.indigo900)),
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _safeText('رقم السند: #$id', style: pw.TextStyle(fontSize: 10, font: boldTtf)),
            _safeText('التاريخ: $date', style: pw.TextStyle(fontSize: 10, font: ttf)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildVoucherBody(String label, String name, double amount, String notes, String Function(double) formatMoney, pw.Font ttf, pw.Font boldTtf) {
    return pw.Column(
      children: [
        _infoRow(label, name, ttf, boldTtf, isHighlight: true),
        pw.SizedBox(height: 12),
        _infoRow('المبلغ وقدره:', formatMoney(amount), ttf, boldTtf),
        pw.SizedBox(height: 8),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: PdfColors.indigo50,
            borderRadius: pw.BorderRadius.circular(4),
            border: pw.Border.all(color: PdfColors.indigo100),
          ),
          child: _safeText(TafqeetService.convert(amount), align: pw.TextAlign.center, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, font: boldTtf, color: PdfColors.indigo900)),
        ),
        pw.SizedBox(height: 12),
        _infoRow('وذلك عن:', notes, ttf, boldTtf),
      ],
    );
  }

  static pw.Widget _infoRow(String label, String value, pw.Font ttf, pw.Font boldTtf, {bool isHighlight = false}) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(width: 100, child: _safeText(label, style: pw.TextStyle(fontSize: 11, font: boldTtf, color: PdfColors.grey800))),
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 2),
            decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, style: pw.BorderStyle.dashed))),
            child: _safeText(value, style: pw.TextStyle(fontSize: 11, font: isHighlight ? boldTtf : ttf)),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Font ttf, pw.Font boldTtf) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
      children: [
        _signatureBox('أمين الصندوق', ttf, boldTtf),
        _signatureBox('المستلم / المحاسب', ttf, boldTtf),
      ],
    );
  }

  static pw.Widget _signatureBox(String title, pw.Font ttf, pw.Font boldTtf) {
    return pw.Column(
      children: [
        _safeText(title, style: pw.TextStyle(fontSize: 10, font: boldTtf)),
        pw.SizedBox(height: 30),
        _safeText('___________________', style: pw.TextStyle(color: PdfColors.grey400)),
      ],
    );
  }

  static pw.Widget _safeText(String? text, {required pw.TextStyle style, pw.TextAlign align = pw.TextAlign.right}) {
    String sanitized = _sanitize(text ?? '');
    if (sanitized.trim().isEmpty) sanitized = " ";
    return pw.Text(sanitized, style: style, textAlign: align);
  }

  static String _sanitize(String text) {
    if (text.isEmpty) return " ";
    String cleaned = text
        .replaceAll('\u202f', ' ')
        .replaceAll('\u00a0', ' ')
        .replaceAll('\u066c', ',')
        .replaceAll('\u066b', '.')
        .replaceAll('\ufdfc', 'ر.ي')
        .replaceAll('﷼', 'ر.ي');

    final buffer = StringBuffer();
    for (final rune in cleaned.runes) {
      if (rune == 0x0A || rune == 0x0D) { buffer.writeCharCode(rune); continue; }
      if (rune >= 0x0020 && rune <= 0x007E) { buffer.writeCharCode(rune); continue; }
      if (rune >= 0x0600 && rune <= 0x06FF) { buffer.writeCharCode(rune); continue; }
      if (rune >= 0x0750 && rune <= 0x077F) { buffer.writeCharCode(rune); continue; }
      if (rune >= 0xFB50 && rune <= 0xFDFF) { buffer.writeCharCode(rune); continue; }
      if (rune >= 0xFE70 && rune <= 0xFEFF) { buffer.writeCharCode(rune); continue; }
      if (rune >= 0x0660 && rune <= 0x0669) { buffer.writeCharCode(rune); continue; }
    }
    return buffer.toString();
  }
}
