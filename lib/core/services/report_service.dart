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

    // --- بداية التعديل: تحميل الوزنين العادي والعريض للخط ---
    final font = await rootBundle.load("assets/fonts/Tajawal-Regular.ttf");
    final boldFont = await rootBundle.load("assets/fonts/Tajawal-Bold.ttf");
    final ttf = pw.Font.ttf(font);
    final boldTtf = pw.Font.ttf(boldFont);
    // --- نهاية التعديل ---

    // تقسيم المنتجات إلى صفحات لتجنب تجاوز حجم الصفحة
    const int productsPerPage = 20;
    for (var i = 0; i < products.length; i += productsPerPage) {
      final pageProducts = products.sublist(
          i, i + productsPerPage > products.length ? products.length : i + productsPerPage);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          // --- بداية التعديل: تعيين السمة العامة والخط الأساسي والاتجاه ---
          textDirection: pw.TextDirection.rtl,
          theme: pw.ThemeData.withFont(
            base: ttf, // الخط الأساسي
            bold: boldTtf, // الخط العريض
          ),
          // --- نهاية التعديل ---
          build: (pw.Context context) {
            return [
              _buildHeader(context),
              pw.SizedBox(height: 20),
              _buildInventoryTable(pageProducts),
              pw.SizedBox(height: 20),
              _buildSummary(context, products.length),
            ];
          },
          footer: (pw.Context context) {
            return _buildFooter(context);
          },
        ),
      );
    }

    // عرض شاشة المعاينة والطباعة
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  /// ودجت لإنشاء رأس التقرير
  static pw.Widget _buildHeader(pw.Context context) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'تقرير جرد المخزون',
          // استخدام الخط العريض هنا
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'تاريخ التقرير: ${intl.DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey),
        ),
        pw.Divider(),
      ],
    );
  }

  /// ودجت لإنشاء جدول المنتجات
  static pw.Widget _buildInventoryTable(List<ProductModel> products) {
    final headers = [
      'التكلفة',
      'سعر البيع',
      'الكمية',
      'الباركود',
      'المنتج',
    ];

    final data = products.map((product) {
      return [
        '${product.purchasePrice} ريال',
        '${product.salePrice} ريال',
        product.quantity.toInt().toString(),
        product.code ?? '-',
        product.name,
      ];
    }).toList();

    return pw.Table.fromTextArray(
      headers: headers,
      data: data,
      cellAlignment: pw.Alignment.centerRight,
      // استخدام الخط العريض للهيدر
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      border: pw.TableBorder.all(),
    );
  }

  /// ودجت لإنشاء ملخص التقرير
  static pw.Widget _buildSummary(pw.Context context, int totalProducts) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        'إجمالي عدد الأصناف: $totalProducts',
        // استخدام الخط العريض للملخص
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  /// ودجت لإنشاء تذييل الصفحة
  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.center,
      child: pw.Text(
        'صفحة ${context.pageNumber} من ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
      ),
    );
  }
}

