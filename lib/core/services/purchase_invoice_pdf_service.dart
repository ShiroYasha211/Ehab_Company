// File: lib/core/services/purchase_invoice_pdf_service.dart

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart' as intl;
import 'tafqeet_service.dart';
import 'settings_service.dart';

class PurchaseInvoicePdfService {
  static Future<void> printInvoice(Map<String, dynamic> invoiceDetails) async {
    final pdf = pw.Document();

    final font = await rootBundle.load("assets/fonts/Tajawal-Regular.ttf");
    final boldFont = await rootBundle.load("assets/fonts/Tajawal-Bold.ttf");
    final ttf = pw.Font.ttf(font);
    final boldTtf = pw.Font.ttf(boldFont);

    final logoImage = pw.MemoryImage(
      (await rootBundle.load('assets/images/logo.png')).buffer.asUint8List(),
    );

    final invoiceData = invoiceDetails['invoice'] as Map<String, dynamic>;
    final itemsData = invoiceDetails['items'] as List<dynamic>;
    final List<dynamic> payments = invoiceDetails['payments'] ?? [];
    final int invoiceId = invoiceData['id'];
    final double remainingAmount = (invoiceData['remainingAmount'] as num? ?? 0.0).toDouble();
    final bool isPaid = remainingAmount <= 0;
    final String statusText = isPaid ? 'مسددة' : 'آجلة';

    double? exchangeRate;
    String? localCurrencySymbol;
    bool printInLocal = false;
    if (invoiceData['notes'] != null) {
      final notes = invoiceData['notes'].toString();
      final rateMatch = RegExp(r'سعر الصرف:\s*([\d\.]+)').firstMatch(notes);
      if (rateMatch != null) {
        exchangeRate = double.tryParse(rateMatch.group(1) ?? '');
        if (exchangeRate != null) {
          printInLocal = true;
          localCurrencySymbol = Get.find<SettingsService>().localCurrency.value.symbol;
        }
      }
    }

    String formatMoney(double amount) {
      String symbol = Get.find<SettingsService>().primaryCurrency.value.symbol;
      double finalAmount = amount;
      if (printInLocal && exchangeRate != null) {
        finalAmount = amount * exchangeRate;
        symbol = localCurrencySymbol ?? symbol;
      }
      
      if (symbol.contains('ر.ي') || symbol.contains('﷼')) {
        symbol = 'ريال';
      }
      final formatted = intl.NumberFormat.decimalPattern('ar').format(finalAmount);
      return _sanitize("$formatted $symbol");
    }

    String formatNum(double amount) {
      double finalAmount = amount;
      if (printInLocal && exchangeRate != null) {
        finalAmount = amount * exchangeRate;
      }
      return _sanitize(intl.NumberFormat.decimalPattern('ar').format(finalAmount));
    }

    final qrData = 'PURCHASE: #$invoiceId\nDATE: ${invoiceData['invoiceDate']}\nTOTAL: ${formatMoney(invoiceData['totalAmount'] as double)}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: ttf, bold: boldTtf),
        header: (context) => _buildHeader(logoImage, ttf, boldTtf, qrData),
        footer: (context) => _buildFooter(context, ttf),
        build: (context) => [
          pw.Stack(
            children: [
              // العلامة المائية للحالة
              pw.Opacity(
                opacity: 0.05,
                child: pw.Container(
                  alignment: pw.Alignment.center,
                  margin: const pw.EdgeInsets.only(top: 150),
                  child: pw.Transform.rotate(
                    angle: -0.5,
                    child: _safeText(statusText, style: pw.TextStyle(fontSize: 100, font: boldTtf, color: isPaid ? PdfColors.green : PdfColors.red)),
                  ),
                ),
              ),
              // المحتوى الأساسي
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildInvoiceTitle(invoiceId, invoiceData['invoiceDate'], ttf, boldTtf),
                  _buildSupplierInfo(invoiceData, ttf, boldTtf),
                  pw.SizedBox(height: 15),
                  _buildItemsTable(itemsData, formatNum, ttf, boldTtf),
                  pw.SizedBox(height: 15),
                  _buildFinancialSummary(invoiceData, formatMoney, ttf, boldTtf),
                  if (payments.isNotEmpty) ...[
                    pw.SizedBox(height: 15),
                    _buildPaymentsTable(payments, formatMoney, ttf, boldTtf),
                  ],
                  if (invoiceData['notes'] != null && invoiceData['notes'].toString().isNotEmpty) ...[
                    pw.SizedBox(height: 10),
                    _buildNotes(invoiceData['notes'], ttf, boldTtf),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/purchase_invoice_$invoiceId.pdf');
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }

  static pw.Widget _buildHeader(pw.MemoryImage logo, pw.Font ttf, pw.Font boldTtf, String qrData) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.indigo900, width: 2.0)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _safeText('شركة إيهاب للتجارة العامة', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16, font: boldTtf, color: PdfColors.indigo900)),
              pw.SizedBox(height: 2),
              _safeText('قسم المشتريات والمخازن', style: pw.TextStyle(fontSize: 9, font: ttf, color: PdfColors.grey700)),
              _safeText('صنعاء - اليمن', style: pw.TextStyle(fontSize: 9, font: ttf, color: PdfColors.grey700)),
            ],
          ),
          pw.Row(
            children: [
              pw.SizedBox(height: 50, width: 50, child: pw.Image(logo)),
              pw.SizedBox(width: 8),
              pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: qrData,
                width: 40,
                height: 40,
                drawText: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInvoiceTitle(int id, String date, pw.Font ttf, pw.Font boldTtf) {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _safeText('فاتورة مشتريات', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, font: boldTtf, color: PdfColors.indigo900)),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _safeText('رقم القيد: #$id', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: boldTtf, fontSize: 11)),
              _safeText('تاريخ: $date', style: pw.TextStyle(font: ttf, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSupplierInfo(Map<String, dynamic> data, pw.Font ttf, pw.Font boldTtf) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(color: PdfColors.indigo50, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6))),
      child: pw.Row(
        children: [
          _safeText('المورد: ', style: pw.TextStyle(fontSize: 10, color: PdfColors.indigo700, font: ttf)),
          _safeText('${data['supplierName'] ?? 'مورد غير محدد'}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, font: boldTtf)),
        ],
      ),
    );
  }

  static pw.Widget _buildItemsTable(List<dynamic> items, String Function(double) formatNum, pw.Font ttf, pw.Font boldTtf) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.4),
        1: const pw.FlexColumnWidth(1.2),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1.2),
        5: const pw.FlexColumnWidth(3),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.indigo800),
          children: [
            _tableCell('الإجمالي', boldTtf, color: PdfColors.white, weight: pw.FontWeight.bold),
            _tableCell('السعر', boldTtf, color: PdfColors.white, weight: pw.FontWeight.bold),
            _tableCell('المجانية', boldTtf, color: PdfColors.white, weight: pw.FontWeight.bold),
            _tableCell('الكمية', boldTtf, color: PdfColors.white, weight: pw.FontWeight.bold),
            _tableCell('الوحدة', boldTtf, color: PdfColors.white, weight: pw.FontWeight.bold),
            _tableCell('الصنف', boldTtf, color: PdfColors.white, weight: pw.FontWeight.bold),
          ],
        ),
        ...List.generate(items.length, (index) {
          final item = items[index];
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: index % 2 == 1 ? PdfColors.grey100 : PdfColors.white),
            children: [
              _tableCell(formatNum(item['totalPrice'] as double), ttf),
              _tableCell(formatNum(item['purchasePrice'] as double), ttf),
              _tableCell((item['freeQuantity'] as num? ?? 0).toString(), ttf),
              _tableCell((item['quantity'] as num).toString(), ttf),
              _tableCell(item['unit'] ?? '-', ttf),
              _tableCell(item['productName'] ?? '-', ttf),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildFinancialSummary(Map<String, dynamic> data, String Function(double) formatMoney, pw.Font ttf, pw.Font boldTtf) {
    final subTotal = (data['totalAmount'] as double) + (data['discountAmount'] as double);
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 1,
          child: (data['issuedBy'] != null) ? pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _safeText('مُسجل العملية:', style: pw.TextStyle(fontSize: 8, font: ttf, color: PdfColors.grey600)),
              _safeText(data['issuedBy'], style: pw.TextStyle(fontSize: 9, font: boldTtf)),
              pw.SizedBox(height: 15),
              pw.Container(width: 70, decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400)))),
              _safeText('توقيع المستلم', style: pw.TextStyle(fontSize: 7, font: ttf)),
            ],
          ) : pw.SizedBox(),
        ),
        pw.Expanded(
          flex: 1,
          child: pw.Column(
            children: [
              _buildSummaryRow('إجمالي المشتريات:', formatMoney(subTotal), ttf, boldTtf),
              _buildSummaryRow('الخصم المكتسب:', '- ${formatMoney(data['discountAmount'] as double)}', ttf, boldTtf, color: PdfColors.orange900),
              pw.Divider(color: PdfColors.indigo100, thickness: 0.5),
              pw.Container(
                padding: const pw.EdgeInsets.all(6),
                decoration: const pw.BoxDecoration(color: PdfColors.indigo900, borderRadius: pw.BorderRadius.all(pw.Radius.circular(4))),
                child: _buildSummaryRow('صافي الفاتورة:', formatMoney(data['totalAmount'] as double), ttf, boldTtf, isTotal: true, color: PdfColors.white),
              ),
              _buildSummaryRow('مبلغ مسدد كدفعة:', formatMoney(data['paidAmount'] as double), ttf, boldTtf, color: PdfColors.green800),
              _buildSummaryRow('المتبقي للمورد:', formatMoney(data['remainingAmount'] as double), ttf, boldTtf, color: PdfColors.red800),
              pw.SizedBox(height: 5),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(4),
                decoration: pw.BoxDecoration(color: PdfColors.indigo50, border: pw.Border.all(color: PdfColors.indigo100)),
                child: _safeText(TafqeetService.convert(data['totalAmount'] as double), style: pw.TextStyle(fontSize: 8, font: ttf), align: pw.TextAlign.center),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildPaymentsTable(List<dynamic> payments, String Function(double) formatMoney, pw.Font ttf, pw.Font boldTtf) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _safeText('سجل سداد المورد:', style: pw.TextStyle(font: boldTtf, fontSize: 10, color: PdfColors.indigo900)),
        pw.SizedBox(height: 4),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey200),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey50),
              children: [
                _tableCell('الملاحظات', boldTtf, size: 8),
                _tableCell('وسيلة الصرف', boldTtf, size: 8),
                _tableCell('المبلغ', boldTtf, size: 8),
              ],
            ),
            ...payments.map((p) => pw.TableRow(
              children: [
                _tableCell(p['notes'] ?? '-', ttf, size: 8),
                _tableCell(p['method'] == 'cash' ? 'صندوق (${p['fundName']})' : 'بنك/حوالة', ttf, size: 8),
                _tableCell(formatMoney(p['amount'] as double), ttf, size: 8),
              ],
            )),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildNotes(String notes, pw.Font ttf, pw.Font boldTtf) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
      child: _safeText('ملاحظات: $notes', style: pw.TextStyle(fontSize: 8, font: ttf, color: PdfColors.grey800)),
    );
  }

  static pw.Widget _tableCell(String text, pw.Font font, {PdfColor? color, double size = 9, pw.FontWeight? weight, double padding = 4}) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(padding),
      child: _safeText(text, style: pw.TextStyle(font: font, fontSize: size, color: color, fontWeight: weight)),
    );
  }

  static pw.Widget _buildSummaryRow(String label, String value, pw.Font ttf, pw.Font boldTtf, {bool isTotal = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _safeText(label, style: pw.TextStyle(font: isTotal ? boldTtf : ttf, fontSize: 9, color: isTotal ? color : null)),
          _safeText(value, style: pw.TextStyle(font: boldTtf, fontSize: 9, color: color)),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context, pw.Font ttf) {
    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: PdfColors.grey200))),
      padding: const pw.EdgeInsets.only(top: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _safeText('صفحة ${context.pageNumber}', style: pw.TextStyle(fontSize: 7, font: ttf, color: PdfColors.grey500)),
          _safeText('طُبع بواسطة نظام إيهاب', style: pw.TextStyle(fontSize: 7, font: ttf, color: PdfColors.grey500)),
        ],
      ),
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
