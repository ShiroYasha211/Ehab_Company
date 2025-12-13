// File: lib/core/services/purchase_invoice_pdf_service.dart

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart' as intl;

class PurchaseInvoicePdfService {
  static Future<void> printInvoice(Map<String, dynamic> invoiceDetails) async {
    final pdf = pw.Document();
    final fontData = await rootBundle.load("assets/fonts/Tajawal-Regular.ttf");
    final arabicFont = pw.Font.ttf(fontData);

    final invoiceData = invoiceDetails['invoice'] as Map<String, dynamic>;
    final itemsData = invoiceDetails['items'] as List<dynamic>;
    final int invoiceId = invoiceData['id'];

    pdf.addPage(
        pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            textDirection: pw.TextDirection.rtl,
            header: (context) => _buildPageHeader(arabicFont),
            footer: (context) => _buildPageFooter(context, arabicFont),
            build: (context) => [
            _buildInvoiceHeader(invoiceData, invoiceId, arabicFont),
        pw.SizedBox(height: 20),
        _buildItemsTable(itemsData, arabicFont),
        pw.SizedBox(height: 20),
              _buildFinancialSummary(invoiceData, arabicFont),
              pw.SizedBox(height: 20),
              if (invoiceData['notes'] != null && invoiceData['notes'].isNotEmpty)
                _buildNotes(invoiceData['notes'], arabicFont),
            ],
        ),
    );

    // حفظ وفتح الملف
         final dir = await getApplicationDocumentsDirectory();
         final file = File('${dir.path}/purchase_invoice_$invoiceId.pdf');
         await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
       }

       static pw.Widget _buildPageHeader(pw.Font font) {
         return pw.Container(
           alignment: pw.Alignment.center,
           margin: const pw.EdgeInsets.only(bottom: 20.0),
           child: pw.Text('فاتورة شراء', style: pw.TextStyle(font: font, fontSize: 18, fontWeight: pw.FontWeight.bold)),
         );
       }

  static pw.Widget _buildInvoiceHeader(Map<String, dynamic> data, int invoiceId, pw.Font font) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
    pw.Text('فاتورة رقم: #$invoiceId', style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold, fontSize: 14)),
    pw.Text('التاريخ: ${intl.DateFormat('yyyy-MM-dd').format(DateTime.parse(data['invoiceDate']))}',
        style: pw.TextStyle(font: font)),
        ],
    ),
    pw.Divider(),
    pw.Text('المورد: ${data['supplierName'] ?? 'غير محدد'}', style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold)),
    pw.Text('الهاتف: ${data['supplierPhone'] ?? 'غير محدد'}', style: pw.TextStyle(font: font)),
        if (data['invoiceNumber'] != null && data['invoiceNumber'].isNotEmpty)
          pw.Text('رقم فاتورة المورد: ${data['invoiceNumber']}', style: pw.TextStyle(font: font)),
      ],
    );
  }

  static pw.Widget _buildItemsTable(List<dynamic> items, pw.Font font) {
    final headers = ['الإجمالي', 'السعر', 'الكميه', 'الصنف'];
    final formatNumber = intl.NumberFormat("#,##0.00", "en_US");

    final data = items.map((item) {
      return [
        '${formatNumber.format(item['totalPrice'])} ر.ي',
        '${formatNumber.format(item['purchasePrice'])}ر.ي',
        item['quantity'].toString(),
        item['productName'],

      ];
    }).toList();

    return pw.Table.fromTextArray(
        headers: headers,
        data: data,
      border: pw.TableBorder.all(color: PdfColors.grey, width: 0.5),
      headerStyle: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold, fontSize: 10),
      headerCellDecoration: pw.BoxDecoration(color: PdfColors.grey200),
      cellStyle: pw.TextStyle(font: font, fontSize: 10),
        cellHeight: 30,
        cellAlignments: {
          0: pw.Alignment.center,
          1: pw.Alignment.center,
          2: pw.Alignment.center,
          3: pw.Alignment.centerRight,
        },
        headerPadding: const pw.EdgeInsets.all(8),
      cellPadding: const pw.EdgeInsets.all(6),
    );
  }


  static pw.Widget _buildFinancialSummary(Map<String, dynamic> data, pw.Font font) {
    final formatNumber = intl.NumberFormat("#,##0.00", "en_US");
    String formatValue(dynamic value) {
      return '${formatNumber.format(value)} ر.ي';
    }
    return pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
        pw.Spacer(), // لدفع الملخص إلى اليمين
    pw.Expanded(
    flex: 2,
    child: pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
    _buildSummaryRow('الإجمالي الفرعي:', formatValue(data['totalAmount'] + data['discountAmount']), font),
    _buildSummaryRow('الخصم:', formatValue(data['discountAmount']), font),
      pw.Divider(),
      _buildSummaryRow('الإجمالي النهائي:', formatValue(data['totalAmount']), font, isTotal: true),
      _buildSummaryRow('المبلغ المدفوع:', formatValue(data['paidAmount']), font, color: PdfColors.green700),
      _buildSummaryRow('المبلغ المتبقي:', formatValue(data['remainingAmount']), font, color: PdfColors.red700),

    ],
    ),
    ),
        ],
    );
  }

  static pw.Widget _buildNotes(String notes, pw.Font font) {
    return pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey, width: 0.5),
            borderRadius: pw.BorderRadius.circular(5),
        ),
        child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
            pw.Text('ملاحظات:', style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 5),
        pw.Text(notes, style: pw.TextStyle(font: font), textDirection: pw.TextDirection.rtl),
            ],),
    );
  }

  static pw.Widget _buildSummaryRow(String label, String value, pw.Font font, {bool isTotal = false, PdfColor? color}) {
    return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
            pw.Text(label, style: pw.TextStyle(font: font, fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal)),
        pw.Text(value,
            style: pw.TextStyle(                  font: font,
                fontWeight: pw.FontWeight.bold,
                color: color)),
            ],
        ),
    );
  }

  static pw.Widget _buildPageFooter(pw.Context context, pw.Font font) {
    return pw.Container(
        alignment: pw.Alignment.center,
        child: pw.Text('صفحة ${context.pageNumber} من ${context.pagesCount}',
            style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey)),
    );
  }
}




















