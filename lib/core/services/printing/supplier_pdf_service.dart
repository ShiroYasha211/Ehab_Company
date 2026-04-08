// File: lib/core/services/printing/supplier_pdf_service.dart

import 'dart:io';
import 'package:ehab_company_admin/features/suppliers/data/models/supplier_model.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart' as intl;
import 'pdf_base_service.dart';

class SupplierPdfService {
  static Future<void> printSuppliersReport(List<SupplierModel> suppliers) async {
    final pdf = pw.Document();

    final resources = await PdfBaseService.loadResources();
    final pw.Font ttf = resources['ttf'];
    final pw.Font boldTtf = resources['boldTtf'];
    final pw.MemoryImage logo = resources['logo'];

    final double totalCredit = suppliers.fold(0, (prev, s) => prev + s.balance);
    final int creditorsCount = suppliers.where((s) => s.balance > 0).length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: ttf, bold: boldTtf),
        header: (context) => PdfBaseService.buildHeader(logo: logo, boldTtf: boldTtf, ttf: ttf),
        footer: (context) => PdfBaseService.buildFooter(context, ttf),
        build: (context) => [
          _buildReportTitle(boldTtf, ttf),
          pw.SizedBox(height: 20),
          _buildFinancialSummary(totalCredit, creditorsCount, boldTtf, ttf),
          pw.SizedBox(height: 20),
          _buildSuppliersTable(suppliers, boldTtf, ttf),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/suppliers_report.pdf');
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }

  static pw.Widget _buildReportTitle(pw.Font boldTtf, pw.Font ttf) {
    return pw.Column(
      children: [
        pw.SizedBox(height: 15),
        PdfBaseService.safeText('تقرير أرصدة الموردين', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, font: boldTtf, color: PdfColors.indigo900)),
        pw.SizedBox(height: 5),
        PdfBaseService.safeText('تاريخ التقرير: ${intl.DateFormat('yyyy-MM-dd').format(DateTime.now())}', style: pw.TextStyle(fontSize: 10, font: ttf, color: PdfColors.grey600)),
      ],
    );
  }

  static pw.Widget _buildFinancialSummary(double totalCredit, int creditorsCount, pw.Font boldTtf, pw.Font ttf) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.indigo.shade(0.01), 
        borderRadius: pw.BorderRadius.circular(8), 
        border: pw.Border.all(color: PdfColors.indigo100)
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('إجمالي المستحقات للموردين', totalCredit, boldTtf, ttf),
          _buildSummaryItem('عدد الموردين المستحقين', creditorsCount.toDouble(), boldTtf, ttf, isCurrency: false),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryItem(String label, double value, pw.Font boldTtf, pw.Font ttf, {bool isCurrency = true}) {
    final formattedValue = isCurrency
        ? PdfBaseService.formatCurrency(value)
        : value.toInt().toString();

    return pw.Column(
      children: [
        PdfBaseService.safeText(label, style: pw.TextStyle(fontSize: 10, font: ttf, color: PdfColors.grey700)),
        pw.SizedBox(height: 4),
        PdfBaseService.safeText(formattedValue, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16, font: boldTtf, color: PdfColors.indigo900)),
      ],
    );
  }

  static pw.Widget _buildSuppliersTable(List<SupplierModel> suppliers, pw.Font boldTtf, pw.Font ttf) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.3),
      columnWidths: {
        0: const pw.FlexColumnWidth(2.5),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2.5),
        3: const pw.FlexColumnWidth(4),
        4: const pw.FixedColumnWidth(25),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.indigo900),
          children: [
            PdfBaseService.tableCell('الرصيد', boldTtf, color: PdfColors.white, size: 9, weight: pw.FontWeight.bold),
            PdfBaseService.tableCell('آخر حركة', boldTtf, color: PdfColors.white, size: 9, weight: pw.FontWeight.bold),
            PdfBaseService.tableCell('رقم الهاتف', boldTtf, color: PdfColors.white, size: 9, weight: pw.FontWeight.bold),
            PdfBaseService.tableCell('اسم المورد', boldTtf, color: PdfColors.white, size: 9, weight: pw.FontWeight.bold),
            PdfBaseService.tableCell('#', boldTtf, color: PdfColors.white, size: 9, weight: pw.FontWeight.bold),
          ],
        ),
        ...List.generate(suppliers.length, (index) {
          final s = suppliers[index];
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: index % 2 == 1 ? PdfColors.indigo.shade(0.01) : PdfColors.white),
            children: [
              PdfBaseService.tableCell(PdfBaseService.formatCurrency(s.balance), ttf, size: 9, color: s.balance > 0 ? PdfColors.red900 : null),
              PdfBaseService.tableCell(intl.DateFormat('yyyy-MM-dd').format(s.createdAt), ttf, size: 9),
              PdfBaseService.tableCell(PdfBaseService.sanitize(s.phone ?? '-'), ttf, size: 9),
              PdfBaseService.tableCell(PdfBaseService.sanitize(s.name), boldTtf, size: 10),
              PdfBaseService.tableCell((index + 1).toString(), ttf, size: 9),
            ],
          );
        }),
      ],
    );
  }
}
