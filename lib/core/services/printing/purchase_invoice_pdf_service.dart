// File: lib/core/services/printing/purchase_invoice_pdf_service.dart

import 'dart:io';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart' as intl;
import 'tafqeet_service.dart';
import '../settings_service.dart';
import 'pdf_base_service.dart';

class PurchaseInvoicePdfService {
  static Future<void> printInvoice(Map<String, dynamic> invoiceDetails) async {
    final pdf = pw.Document();

    final resources = await PdfBaseService.loadResources();
    final pw.Font ttf = resources['ttf'];
    final pw.Font boldTtf = resources['boldTtf'];
    final pw.MemoryImage logo = resources['logo'];

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
      double finalAmount = amount;
      String? symbol;
      
      if (printInLocal && exchangeRate != null) {
        finalAmount = amount * exchangeRate;
        symbol = localCurrencySymbol;
      }
      
      if (symbol != null) {
        final formatted = intl.NumberFormat.decimalPattern('ar').format(finalAmount);
        return PdfBaseService.sanitize("$formatted $symbol");
      }
      
      return PdfBaseService.formatCurrency(amount);
    }

    String formatNum(double amount) {
      double finalAmount = amount;
      if (printInLocal && exchangeRate != null) finalAmount = amount * exchangeRate;
      return PdfBaseService.sanitize(intl.NumberFormat.decimalPattern('ar').format(finalAmount));
    }

    final qrData = 'PURCHASE: #$invoiceId\nDATE: ${invoiceData['invoiceDate']}\nTOTAL: ${formatMoney(invoiceData['totalAmount'] as double)}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: ttf, bold: boldTtf),
        header: (context) => PdfBaseService.buildHeader(
          logo: logo, 
          boldTtf: boldTtf, 
          ttf: ttf,
          extra: pw.BarcodeWidget(
            barcode: pw.Barcode.qrCode(),
            data: qrData,
            width: 40,
            height: 40,
            drawText: false,
          ),
        ),
        footer: (context) => PdfBaseService.buildFooter(context, ttf),
        build: (context) => [
          pw.Stack(
            children: [
              pw.Opacity(
                opacity: 0.05,
                child: pw.Container(
                  alignment: pw.Alignment.center,
                  margin: const pw.EdgeInsets.only(top: 150),
                  child: pw.Transform.rotate(
                    angle: -0.5,
                    child: PdfBaseService.safeText(statusText, style: pw.TextStyle(fontSize: 100, font: boldTtf, color: isPaid ? PdfColors.green : PdfColors.red)),
                  ),
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildInvoiceTitle(invoiceId, invoiceData['invoiceDate'], boldTtf, ttf),
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

  static pw.Widget _buildInvoiceTitle(int id, String date, pw.Font boldTtf, pw.Font ttf) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 15, bottom: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          PdfBaseService.safeText('فاتورة توريد مشتريات', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, font: boldTtf, color: PdfColors.indigo900)),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              PdfBaseService.safeText('رقم القيد: #$id', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: boldTtf, fontSize: 11)),
              PdfBaseService.safeText('تاريخ: $date', style: pw.TextStyle(font: ttf, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSupplierInfo(Map<String, dynamic> data, pw.Font ttf, pw.Font boldTtf) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(color: PdfColors.white, borderRadius: pw.BorderRadius.circular(6), border: pw.Border.all(color: PdfColors.grey300, width: 0.5)),
      child: pw.Row(
        children: [
          PdfBaseService.safeText('المورد المعتمد: ', style: pw.TextStyle(fontSize: 10, color: PdfColors.indigo700, font: ttf)),
          PdfBaseService.safeText(PdfBaseService.sanitize(data['supplierName'] ?? 'مورد غير محدد'), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, font: boldTtf)),
        ],
      ),
    );
  }

  static pw.Widget _buildItemsTable(List<dynamic> items, String Function(double) formatNum, pw.Font ttf, pw.Font boldTtf) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.3),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.4),
        1: const pw.FlexColumnWidth(1.2),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1.2),
        5: const pw.FlexColumnWidth(3),
        6: const pw.FixedColumnWidth(20),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.indigo900),
          children: [
            PdfBaseService.tableCell('الإجمالي', boldTtf, color: PdfColors.white, weight: pw.FontWeight.bold, size: 8.5),
            PdfBaseService.tableCell('السعر', boldTtf, color: PdfColors.white, weight: pw.FontWeight.bold, size: 8.5),
            PdfBaseService.tableCell('المجانية', boldTtf, color: PdfColors.white, weight: pw.FontWeight.bold, size: 8.5),
            PdfBaseService.tableCell('الكمية', boldTtf, color: PdfColors.white, weight: pw.FontWeight.bold, size: 8.5),
            PdfBaseService.tableCell('الوحدة', boldTtf, color: PdfColors.white, weight: pw.FontWeight.bold, size: 8.5),
            PdfBaseService.tableCell('الصنف', boldTtf, color: PdfColors.white, weight: pw.FontWeight.bold, size: 8.5),
            PdfBaseService.tableCell('#', boldTtf, color: PdfColors.white, weight: pw.FontWeight.bold, size: 8.5),
          ],
        ),
        ...List.generate(items.length, (index) {
          final item = items[index];
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: index % 2 == 1 ? PdfColors.indigo.shade(0.01) : PdfColors.white),
            children: [
              PdfBaseService.tableCell(formatNum((item['totalPrice'] as num).toDouble()), ttf, size: 8),
              PdfBaseService.tableCell(formatNum((item['purchasePrice'] as num).toDouble()), ttf, size: 8),
              PdfBaseService.tableCell((item['freeQuantity'] as num? ?? 0).toString(), ttf, size: 8),
              PdfBaseService.tableCell((item['quantity'] as num).toString(), ttf, size: 8),
              PdfBaseService.tableCell(PdfBaseService.sanitize(item['unit'] ?? '-'), ttf, size: 8),
              PdfBaseService.tableCell(PdfBaseService.sanitize(item['productName'] ?? '-'), ttf, size: 8),
              PdfBaseService.tableCell((index + 1).toString(), ttf, size: 8),
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
              PdfBaseService.safeText('مُسجل العملية:', style: pw.TextStyle(fontSize: 8, font: ttf, color: PdfColors.grey600)),
              PdfBaseService.safeText(data['issuedBy'], style: pw.TextStyle(fontSize: 9, font: boldTtf)),
              pw.SizedBox(height: 15),
              pw.Container(width: 70, decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400)))),
              PdfBaseService.safeText('توقيع المستلم', style: pw.TextStyle(fontSize: 7, font: ttf)),
            ],
          ) : pw.SizedBox(),
        ),
        pw.Expanded(
          flex: 1,
          child: pw.Column(
            children: [
              _buildSummaryRow('إجمالي قيمة المشتريات:', formatMoney(subTotal), ttf, boldTtf),
              _buildSummaryRow('إجمالي الخصم المكتسب:', '- ${formatMoney(data['discountAmount'] as double)}', ttf, boldTtf, color: PdfColors.red800),
              pw.SizedBox(height: 4),
              pw.Container(
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white, 
                  border: pw.Border.all(color: PdfColors.indigo900, width: 1.2),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))
                ),
                child: _buildSummaryRow('صافي القيمة المطلوبة:', formatMoney(data['totalAmount'] as double), ttf, boldTtf, isTotal: true, color: PdfColors.indigo900),
              ),
              _buildSummaryRow('مبلغ مسدد كدفعة:', formatMoney(data['paidAmount'] as double), ttf, boldTtf, color: PdfColors.green800),
              _buildSummaryRow('المتبقي للمورد:', formatMoney(data['remainingAmount'] as double), ttf, boldTtf, color: PdfColors.red900),
              pw.SizedBox(height: 5),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(4),
                decoration: pw.BoxDecoration(color: PdfColors.white, border: pw.Border.all(color: PdfColors.grey300), borderRadius: pw.BorderRadius.circular(2)),
                child: PdfBaseService.safeText(TafqeetService.convert((data['totalAmount'] as num).toDouble()), style: pw.TextStyle(fontSize: 8.5, font: boldTtf, color: PdfColors.indigo900), align: pw.TextAlign.center),
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
        PdfBaseService.safeText('سجل سداد المورد:', style: pw.TextStyle(font: boldTtf, fontSize: 10, color: PdfColors.indigo900)),
        pw.SizedBox(height: 4),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey200),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey50),
              children: [
                PdfBaseService.tableCell('الملاحظات', boldTtf, size: 8),
                PdfBaseService.tableCell('وسيلة الصرف', boldTtf, size: 8),
                PdfBaseService.tableCell('المبلغ', boldTtf, size: 8),
              ],
            ),
            ...payments.map((p) => pw.TableRow(
              children: [
                PdfBaseService.tableCell(p['notes'] ?? '-', ttf, size: 8),
                PdfBaseService.tableCell(p['method'] == 'cash' ? 'صندوق (${p['fundName']})' : 'بنك/حوالة', ttf, size: 8),
                PdfBaseService.tableCell(formatMoney(p['amount'] as double), ttf, size: 8),
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
      child: PdfBaseService.safeText('ملاحظات: $notes', style: pw.TextStyle(fontSize: 8, font: ttf, color: PdfColors.grey800)),
    );
  }

  static pw.Widget _buildSummaryRow(String label, String value, pw.Font ttf, pw.Font boldTtf, {bool isTotal = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          PdfBaseService.safeText(label, style: pw.TextStyle(font: isTotal ? boldTtf : ttf, fontSize: 9, color: isTotal ? color : null)),
          PdfBaseService.safeText(value, style: pw.TextStyle(font: boldTtf, fontSize: 9, color: color)),
        ],
      ),
    );
  }
}
