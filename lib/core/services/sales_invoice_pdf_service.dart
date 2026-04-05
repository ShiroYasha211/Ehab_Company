// File: lib/core/services/sales_invoice_pdf_service.dart

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart' as intl;

import 'settings_service.dart';

class SalesInvoicePdfService {
  static Future<void> printInvoice(Map<String, dynamic> invoiceDetails) async {
    final pdf = pw.Document();

    // --- 1. بداية التعديل: استخدام خطين (عادي وداكن) ---
    final font = await rootBundle.load("assets/fonts/Tajawal-Regular.ttf");
    final boldFont = await rootBundle.load("assets/fonts/Tajawal-Bold.ttf");
    final ttf = pw.Font.ttf(font);
    final boldTtf = pw.Font.ttf(boldFont);

    final logoImage = pw.MemoryImage(
      (await rootBundle.load('assets/images/logo.png')).buffer.asUint8List(),
    );
    // --- نهاية التعديل ---

    final invoiceData = invoiceDetails['invoice'] as Map<String, dynamic>;
    final itemsData = invoiceDetails['items'] as List<dynamic>;
    final int invoiceId = invoiceData['id'];

    // محاولة استخراج سعر الصرف من الملاحظات لمعرفة ما إذا كان الدفع محليًا
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
          localCurrencySymbol =
              Get.find<SettingsService>().localCurrency.value.symbol;
        }
      }
    }

    // دالة تنسيق العملة المحدثة
    String formatMoney(double amountInPrimary) {
      if (printInLocal && exchangeRate != null) {
        final localAmount = amountInPrimary * exchangeRate;
        return '${intl.NumberFormat.decimalPattern('ar').format(localAmount)} $localCurrencySymbol';
      } else {
        return '${intl.NumberFormat.decimalPattern('ar').format(amountInPrimary)} ${Get.find<SettingsService>().primaryCurrency.value.symbol}';
      }
    }

    // دالة تنسيق الأرقام فقط (بدون رمز العملة) - نحتاجها للجدول
    String formatNumber(double amountInPrimary) {
      if (printInLocal && exchangeRate != null) {
        final localAmount = amountInPrimary * exchangeRate;
        return intl.NumberFormat.decimalPattern('ar').format(localAmount);
      } else {
        return intl.NumberFormat.decimalPattern('ar').format(amountInPrimary);
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: ttf, bold: boldTtf),
        // تطبيق الخطوط
        header: (context) => _buildHeader(logoImage),
        // <-- رأس الصفحة الموحد
        build: (context) => [
          _buildInvoiceTitle(invoiceId, invoiceData['invoiceDate']),
          // <-- عنوان الفاتورة
          _buildCustomerInfo(invoiceData),
          // <-- معلومات العميل
          pw.SizedBox(height: 20),
          // تمرير دوال التنسيق الجديدة
          _buildItemsTable(itemsData, formatNumber),
          // <-- جدول الأصناف المحدث
          pw.SizedBox(height: 20),
          _buildFinancialSummary(invoiceData, formatMoney),
          // <-- الملخص المالي المحدث
          pw.SizedBox(height: 15),
          if (invoiceData['issuedBy'] != null)
            pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(
                'مُصدر الفاتورة: ${invoiceData['issuedBy']}',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
              ),
            ),
          
          // --- إضافة: قسم تفاصيل السداد (الإصدار 24) ---
          if (invoiceDetails['payments'] != null && (invoiceDetails['payments'] as List).isNotEmpty) ...[
            pw.SizedBox(height: 15),
            _buildPaymentsSection(invoiceDetails['payments'] as List, formatMoney),
          ],
          
          pw.Spacer(),
          // لدفع الملاحظات إلى أسفل الصفحة إذا كانت هناك مساحة
          if (invoiceData['notes'] != null && invoiceData['notes'].isNotEmpty)
            _buildNotes(invoiceData['notes']),
        ],
        footer: (context) => _buildFooter(context), // <-- تذييل الصفحة الموحد
      ),
    );

    // حفظ وفتح الملف
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/sales_invoice_$invoiceId.pdf');
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }

  // --- 2. بداية التعديل: استخدام نفس تصميم رأس الصفحة من تقرير المخزون ---
  static pw.Widget _buildHeader(pw.MemoryImage logo) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 15),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey, width: 1.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'شركة إيهاب للتجارة',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'هاتف: 777-777-777',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                'البريد الإلكتروني: info@ehab-company.com',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
          pw.SizedBox(height: 60, width: 60, child: pw.Image(logo)),
        ],
      ),
    );
  }

  // --- نهاية التعديل ---

  // ودجت جديد لعرض عنوان الفاتورة ورقمها
  static pw.Widget _buildInvoiceTitle(int invoiceId, String dateString) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'فاتورة مبيعات',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'رقم الفاتورة: #$invoiceId',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                'التاريخ: ${intl.DateFormat('yyyy-MM-dd').format(DateTime.parse(dateString))}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ودجت جديد لعرض معلومات العميل
  static pw.Widget _buildCustomerInfo(Map<String, dynamic> data) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'فاتورة إلى العميل:',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            data['customerName'] ?? 'عميل نقدي',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
          ),
          if (data['customerPhone'] != null)
            pw.Text(
              'الهاتف: ${data['customerPhone']}',
              style: const pw.TextStyle(fontSize: 11),
            ),
        ],
      ),
    );
  }

  // --- 3. بداية التعديل: استخدام نفس تصميم جدول الأصناف ---
  static pw.Widget _buildItemsTable(
    List<dynamic> items,
    String Function(double) formatNumber,
  ) {
    final headers = ['الإجمالي', 'السعر', 'المجانية', 'الأساسية', 'الوحدة', 'الصنف'];

    final data = items.map((item) {
      return [
        formatNumber(item['totalPrice']),
        formatNumber(item['salePrice']),
        (item['freeQuantity'] as num? ?? 0.0).toStringAsFixed(0),
        (item['quantity'] as num).toStringAsFixed(0),
        item['unit'] ?? '-',
        item['productName'],
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      cellAlignment: pw.Alignment.centerRight,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        fontSize: 10,
      ),
      cellStyle: const pw.TextStyle(fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey600),
      rowDecoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200)),
      ),
      headers: headers,
      data: data,
      columnWidths: {
        0: const pw.FlexColumnWidth(1.8), // الإجمالي
        1: const pw.FlexColumnWidth(1.5), // السعر
        2: const pw.FlexColumnWidth(1.2), // المجانية
        3: const pw.FlexColumnWidth(1.2), // الأساسية
        4: const pw.FlexColumnWidth(1.5), // الوحدة
        5: const pw.FlexColumnWidth(2.8), // الصنف
      },
    );
  }

  // --- نهاية التعديل ---

  // --- 4. بداية التعديل: إعادة تصميم الملخص المالي ---
  static pw.Widget _buildFinancialSummary(
    Map<String, dynamic> data,
    String Function(double) formatCurrency,
  ) {
    final double totalBeforeDiscount =
        data['totalAmount'] + data['discountAmount'];

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Spacer(), // لدفع الملخص إلى اليسار
        pw.Expanded(
          flex: 2,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildSummaryRow(
                'الإجمالي قبل الخصم:',
                formatCurrency(totalBeforeDiscount),
              ),
              _buildSummaryRow(
                'الخصم:',
                '- ${formatCurrency(data['discountAmount'])}',
                color: PdfColors.orange800,
              ),
              pw.Container(
                margin: const pw.EdgeInsets.symmetric(vertical: 4),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(top: pw.BorderSide(color: PdfColors.grey)),
                ),
                padding: const pw.EdgeInsets.only(top: 4),
                child: _buildSummaryRow(
                  'الإجمالي بعد الخصم:',
                  formatCurrency(data['totalAmount']),
                  isTotal: true,
                ),
              ),
              _buildSummaryRow(
                'المبلغ المدفوع:',
                formatCurrency(data['paidAmount']),
                color: PdfColors.green700,
              ),
              pw.Container(
                color: PdfColors.grey200,
                padding: const pw.EdgeInsets.all(6),
                child: _buildSummaryRow(
                  'المبلغ المتبقي:',
                  formatCurrency(data['remainingAmount']),
                  isTotal: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- نهاية التعديل ---

  // ودجت عرض تفاصيل المدفوعات المتعددة
  static pw.Widget _buildPaymentsSection(
    List<dynamic> payments,
    String Function(double) formatCurrency,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'تفاصيل سداد المبالغ:',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
        ),
        pw.SizedBox(height: 5),
        pw.TableHelper.fromTextArray(
          cellAlignment: pw.Alignment.centerRight,
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white),
          cellStyle: const pw.TextStyle(fontSize: 8),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
          headers: ['الملاحظات', 'التفاصيل (رقم المرجع / المرسل)', 'الوسيلة', 'المبلغ'],
          data: payments.map((p) {
            String methodText = 'نقد (كاش)';
            String details = '-';
            
            if (p['method'] == 'transfer') {
              methodText = 'حوالة مصرفية';
              details = 'رقم: ${p['transferNumber'] ?? ''} | مُرسل: ${p['senderName'] ?? ''}\n(إلى: ${p['fundName'] ?? 'صندوق غير محدد'})';
            } else if (p['method'] == 'bank') {
              methodText = 'بنك / مسبق';
              details = 'مرجع: ${p['bankReference'] ?? ''} | بنك: ${p['bankName'] ?? ''}\n(إلى: ${p['fundName'] ?? 'حساب غير محدد'})';
            } else {
              details = 'إيداع في: ${p['fundName'] ?? 'صندوق النقد'}';
            }

            // إضافة الملاحظات إذا وجدت
            if (p['notes'] != null && p['notes'].toString().trim().isNotEmpty) {
              details += '\n📝 ملاحظة: ${p['notes']}';
            }

            return [
              p['notes'] ?? '-',
              details,
              methodText,
              formatCurrency(p['amount'] as double? ?? 0.0),
            ];
          }).toList(),
          columnWidths: {
            0: const pw.FlexColumnWidth(2), 
            1: const pw.FlexColumnWidth(3),
            2: const pw.FlexColumnWidth(1.5),
            3: const pw.FlexColumnWidth(1.5),
          },
        ),
      ],
    );
  }

  static pw.Widget _buildNotes(String notes) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey, width: 0.5),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ملاحظات:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 5),
          pw.Text(notes),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryRow(
    String label,
    String value, {
    bool isTotal = false,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: 11,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: color,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // --- 5. بداية التعديل: استخدام نفس تصميم تذييل الصفحة ---
  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        'صفحة ${context.pageNumber} من ${context.pagesCount} - © شركة إيهاب',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
      ),
    );
  }

  // --- نهاية التعديل ---
}
