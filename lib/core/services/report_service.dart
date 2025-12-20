// File: lib/core/services/report_service.dart

import 'package:ehab_company_admin/features/products/data/models/product_model.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportService {
  /// دالة لإنشاء وطباعة تقرير جرد المخزون
  static Future<void> printInventoryReport(List<ProductModel> products) async {
    final pdf = pw.Document();

    final font = await rootBundle.load("assets/fonts/Tajawal-Regular.ttf");
    final boldFont = await rootBundle.load("assets/fonts/Tajawal-Bold.ttf");
    final ttf = pw.Font.ttf(font);
    final boldTtf = pw.Font.ttf(boldFont);

    // --- بداية التعديل: تحميل صورة الشعار ---
    final logoImage = pw.MemoryImage(
      (await rootBundle.load('assets/images/logo.png')).buffer.asUint8List(),
    );
    // --- نهاية التعديل ---

    const int productsPerPage = 20;
    for (var i = 0; i < products.length; i += productsPerPage) {
      final pageProducts = products.sublist(
          i, i + productsPerPage > products.length ? products.length : i + productsPerPage);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          theme: pw.ThemeData.withFont(
            base: ttf,
            bold: boldTtf,
          ),
          header: (context) => _buildHeader(logoImage), // <-- تمرير الشعار
          build: (pw.Context context) {
            return [
              _buildReportTitle(), // <-- عنوان التقرير
              pw.SizedBox(height: 20),
              _buildInventoryTable(pageProducts),
              // الملخص سيظهر فقط في آخر صفحة
              if (i + productsPerPage >= products.length) ...[
                pw.SizedBox(height: 30),
                _buildSummary(products),
              ],
            ];
          },
          footer: (pw.Context context) {
            return _buildFooter(context);
          },
        ),
      );
    }

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  // --- بداية التعديل: دالة جديدة لبناء رأس الصفحة مع الشعار وبيانات الشركة ---
  static pw.Widget _buildHeader(pw.MemoryImage logo) {
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
          pw.SizedBox(
            height: 60,
            width: 60,
            child: pw.Image(logo),
          ),
        ],
      ),
    );
  }
  // --- نهاية التعديل ---

  // --- بداية التعديل: ودجت جديد لعرض عنوان التقرير وتاريخه ---
  static pw.Widget _buildReportTitle() {
    return pw.Column(
      children: [
        pw.SizedBox(height: 10),
        pw.Text(
          'تقرير جرد المخزون',
          style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'تاريخ التقرير: ${intl.DateFormat('yyyy-MM-dd hh:mm a', 'ar').format(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
        ),
      ],
    );
  }
  // --- نهاية التعديل ---


  // --- بداية التعديل: تحسين تصميم الجدول وإضافة عمود "القيمة" ---
  static pw.Widget _buildInventoryTable(List<ProductModel> products) {
    final formatCurrency = (double value) => intl.NumberFormat.decimalPattern('ar').format(value);

    final headers = [
      'القيمة',
      'س. الشراء',
      'الكمية',
      'المنتج',
    ];

    final data = products.map((product) {
      final totalValue = product.quantity * product.purchasePrice;
      return [
        '${formatCurrency(totalValue)}',
        '${formatCurrency(product.purchasePrice)}',
        product.quantity.toInt().toString(),
        product.name,
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      cellAlignment: pw.Alignment.centerRight,
      cellStyle: const pw.TextStyle(fontSize: 10),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 11),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey600),
      rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200))),
      headers: headers,
      data: data,
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(4),
      },
    );
  }
  // --- نهاية التعديل ---

  // --- بداية التعديل: تحسين الملخص ليشمل القيم المالية ---
  static pw.Widget _buildSummary(List<ProductModel> allProducts) {
    final double totalValue = allProducts.fold(0, (sum, item) => sum + (item.quantity * item.purchasePrice));
    final int totalItems = allProducts.fold(0, (sum, item) => sum + item.quantity.toInt());
    final formatCurrency = intl.NumberFormat.currency(locale: 'ar_SA', symbol: ' ريال');

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('إجمالي قيمة المخزون', formatCurrency.format(totalValue)),
          _buildSummaryItem('إجمالي عدد القطع', totalItems.toString()),
          _buildSummaryItem('إجمالي عدد الأصناف', allProducts.length.toString()),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(color: PdfColors.black, fontSize: 11)),
        pw.SizedBox(height: 4),
        pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.blueGrey800)),
      ],
    );
  }
  // --- نهاية التعديل ---

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
}
