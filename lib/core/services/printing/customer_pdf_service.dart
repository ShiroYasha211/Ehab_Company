// File: lib/core/services/printing/customer_pdf_service.dart

import 'dart:io';
import 'package:ehab_company_admin/features/customers/data/models/customer_model.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart' as intl;
import 'pdf_base_service.dart';

class CustomerPdfService {
  static Future<void> printCustomersReport(List<CustomerModel> customers) async {
    final pdf = pw.Document();

    final resources = await PdfBaseService.loadResources();
    final pw.Font ttf = resources['ttf'];
    final pw.Font boldTtf = resources['boldTtf'];
    final pw.MemoryImage logo = resources['logo'];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: ttf, bold: boldTtf),
        header: (context) => PdfBaseService.buildHeader(logo: logo, boldTtf: boldTtf, ttf: ttf),
        footer: (context) => PdfBaseService.buildFooter(context, ttf),
        build: (context) {
          final totalReceivables = customers.fold(0.0, (sum, c) => sum + c.balance);
          final creditorsCount = customers.length;
          final maxBalance = customers.isEmpty ? 0.0 : customers.map((c) => c.balance).reduce((a, b) => a > b ? a : b);

          return [
            _buildReportTitle(),
            pw.SizedBox(height: 20),
            _buildStatsDashboard(totalReceivables, creditorsCount, maxBalance),
            pw.SizedBox(height: 20),
            _buildCustomersTable(customers),
          ];
        },
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/customers_report.pdf');
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }

  static pw.Widget _buildReportTitle() {
    return pw.Column(
      children: [
        pw.SizedBox(height: 15),
        PdfBaseService.safeText('تقرير أرصدة العملاء', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
        pw.SizedBox(height: 5),
        PdfBaseService.safeText('تاريخ التقرير: ${intl.DateFormat('yyyy-MM-dd | hh:mm a').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
      ],
    );
  }

  static pw.Widget _buildStatsDashboard(double total, int count, double max) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        PdfBaseService.buildStatCard('إجمالي المديونية', PdfBaseService.formatCurrency(total), color: PdfColors.indigo900),
        PdfBaseService.buildStatCard('عدد العملاء', '$count عميل', color: PdfColors.blueGrey800),
        PdfBaseService.buildStatCard('أعلى مديونية', PdfBaseService.formatCurrency(max), color: PdfColors.orange900),
      ],
    );
  }

  static pw.Widget _buildCustomersTable(List<CustomerModel> customers) {
    final headers = ['#', 'الرصيد', 'آخر حركة', 'الشركة / الهاتف', 'اسم العميل'];
    
    final data = List.generate(customers.length, (index) {
      final c = customers[index];
      return [
        (index + 1).toString(),
        PdfBaseService.formatCurrency(c.balance),
        c.lastTransactionDate != null ? intl.DateFormat('yyyy-MM-dd').format(c.lastTransactionDate!) : 'لا يوجد',
        PdfBaseService.sanitize('${c.company ?? ""}${(c.company != null && c.phone != null) ? " - " : ""}${c.phone ?? ""}'),
        PdfBaseService.sanitize(c.name),
      ];
    });

    return pw.Table.fromTextArray(
      headers: headers,
      data: data,
      cellAlignment: pw.Alignment.centerRight,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo900),
      rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200))),
      cellStyle: const pw.TextStyle(fontSize: 9),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.indigo50),
      columnWidths: {
        0: const pw.FixedColumnWidth(25),
        1: const pw.FlexColumnWidth(2.5),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(3),
        4: const pw.FlexColumnWidth(4),
      },
    );
  }
}
