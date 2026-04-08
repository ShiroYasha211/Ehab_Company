// File: lib/core/services/printing/voucher_pdf_service.dart

import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart' as intl;
import 'tafqeet_service.dart';
import 'pdf_base_service.dart';

class VoucherPdfService {
  static Future<void> printVoucher(Map<String, dynamic> voucherData, {required bool isReceipt}) async {
    final pdf = pw.Document();

    final resources = await PdfBaseService.loadResources();
    final pw.Font ttf = resources['ttf'];
    final pw.Font boldTtf = resources['boldTtf'];
    final pw.MemoryImage logo = resources['logo'];

    final String voucherTitle = isReceipt ? 'سند قبض' : 'سند صرف';
    final PdfColor themeColor = isReceipt ? PdfColors.green800 : PdfColors.red800;
    final double amount = (voucherData['amount'] as num).toDouble();

    final String qrData = 'VOUCHER: $voucherTitle\nID: ${voucherData['id']}\nAMOUNT: ${amount.toStringAsFixed(2)}\nDATE: ${intl.DateFormat('yyyy-MM-dd').format(DateTime.now())}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: ttf, bold: boldTtf),
        build: (context) => pw.Container(
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(border: pw.Border.all(color: themeColor, width: 2)),
          child: pw.Column(
            children: [
              PdfBaseService.buildHeader(
                logo: logo, 
                boldTtf: boldTtf, 
                ttf: ttf,
                extra: pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: qrData,
                  width: 45,
                  height: 45,
                  drawText: false,
                ),
              ),
              pw.SizedBox(height: 20),
              _buildVoucherTitle(voucherTitle, voucherData['id'].toString(), themeColor, boldTtf),
              pw.SizedBox(height: 30),
              _buildVoucherBody(voucherData, ttf, boldTtf, isReceipt),
              pw.Spacer(),
              _buildSignatures(ttf, boldTtf),
              pw.SizedBox(height: 20),
              PdfBaseService.buildFooter(context, ttf),
            ],
          ),
        ),
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/voucher_${voucherData['id']}.pdf');
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }

  static pw.Widget _buildVoucherTitle(String title, String id, PdfColor color, pw.Font boldTtf) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          decoration: pw.BoxDecoration(color: color, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5))),
          child: PdfBaseService.safeText(title, style: pw.TextStyle(color: PdfColors.white, fontSize: 20, fontWeight: pw.FontWeight.bold, font: boldTtf)),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            PdfBaseService.safeText('رقم السند: #$id', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, font: boldTtf)),
            PdfBaseService.safeText('التاريخ: ${intl.DateFormat('yyyy-MM-dd').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 11)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildVoucherBody(Map<String, dynamic> data, pw.Font ttf, pw.Font boldTtf, bool isReceipt) {
    final amount = data['amount'] as double;
    return pw.Column(
      children: [
        _buildInfoRow(isReceipt ? 'استلمنا من السيد/ة:' : 'صرفنا للسيد/ة:', PdfBaseService.sanitize(data['entityName'] ?? 'غير محدد'), ttf, boldTtf),
        pw.SizedBox(height: 15),
        _buildInfoRow('مبلـغ وقدره:', PdfBaseService.formatCurrency(amount), ttf, boldTtf, isAmount: true),
        pw.SizedBox(height: 10),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(8),
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          child: PdfBaseService.safeText(TafqeetService.convert(amount), style: pw.TextStyle(fontSize: 10, font: ttf), align: pw.TextAlign.center),
        ),
        pw.SizedBox(height: 15),
        _buildInfoRow('وذلـك عـن:', PdfBaseService.sanitize(data['notes'] ?? 'بيان العملية'), ttf, boldTtf),
        pw.SizedBox(height: 15),
        _buildInfoRow('طريقة الدفع:', PdfBaseService.sanitize(data['method'] == 'cash' ? 'نقداً من ${data['fundName']}' : 'حوالة / بنك'), ttf, boldTtf),
      ],
    );
  }

  static pw.Widget _buildInfoRow(String label, String value, pw.Font ttf, pw.Font boldTtf, {bool isAmount = false}) {
    return pw.Row(
      children: [
        pw.Text(label, style: pw.TextStyle(font: ttf, fontSize: 12), textDirection: pw.TextDirection.rtl),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 2),
            decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400, style: pw.BorderStyle.dashed))),
            child: PdfBaseService.safeText(value, style: pw.TextStyle(font: boldTtf, fontSize: isAmount ? 16 : 13, color: isAmount ? PdfColors.indigo900 : PdfColors.black)),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildSignatures(pw.Font ttf, pw.Font boldTtf) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _buildSignZone('توقيع المستلم', ttf),
        _buildSignZone('توقيع المحاسب', ttf),
        _buildSignZone('ختم الشركة', ttf),
      ],
    );
  }

  static pw.Widget _buildSignZone(String label, pw.Font ttf) {
    return pw.Column(
      children: [
        pw.SizedBox(height: 40),
        pw.Container(width: 100, decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400)))),
        pw.SizedBox(height: 5),
        PdfBaseService.safeText(label, style: pw.TextStyle(fontSize: 9, font: ttf)),
      ],
    );
  }
}
