// File: lib/core/services/printing/report_service.dart

import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ehab_company_admin/features/products/data/models/product_model.dart';
import 'package:ehab_company_admin/features/units/data/models/unit_model.dart';
import 'package:ehab_company_admin/features/units/data/repositories/unit_repository.dart';
import 'package:intl/intl.dart' as intl;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'pdf_base_service.dart';

class ReportService {
  /// دالة لإنشاء وطباعة تقرير جرد المخزون المحاسبي والمالي المتقدم
  static Future<void> printInventoryReport(List<ProductModel> products) async {
    final pdf = pw.Document();

    final resources = await PdfBaseService.loadResources();
    final pw.Font ttf = resources['ttf'];
    final pw.Font boldTtf = resources['boldTtf'];
    final pw.MemoryImage logo = resources['logo'];

    // جلب بيانات الوحدات لربطها بالتقرير
    final List<UnitModel> units = await UnitRepository().getAllUnits();
    final Map<int, UnitModel> unitMap = {for (var u in units) u.id!: u};

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: ttf, bold: boldTtf),
        header: (context) => PdfBaseService.buildHeader(logo: logo, boldTtf: boldTtf, ttf: ttf),
        footer: (context) => PdfBaseService.buildFooter(context, ttf),
        build: (pw.Context context) {
          return [
            _buildReportTitle(boldTtf, ttf),
            _buildFiscalDashboard(products, boldTtf, ttf),
            pw.SizedBox(height: 20),
            _buildInventoryTable(products, unitMap, boldTtf, ttf),
          ];
        },
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/inventory_audit_report.pdf');
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }

  static pw.Widget _buildReportTitle(pw.Font boldTtf, pw.Font ttf) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 15, bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          PdfBaseService.safeText('تقرير الجرد الفني والمالي للمخازن', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900, font: boldTtf)),
          pw.SizedBox(height: 4),
          PdfBaseService.safeText('تاريخ الجرد: ${intl.DateFormat('yyyy-MM-dd | hh:mm a').format(DateTime.now())}', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700, font: ttf)),
          pw.Divider(color: PdfColors.indigo100, thickness: 0.5),
        ],
      ),
    );
  }

  static pw.Widget _buildFiscalDashboard(List<ProductModel> products, pw.Font boldTtf, pw.Font ttf) {
    final double totalPurchaseValue = products.fold(0, (sum, p) => sum + (p.quantity * p.purchasePrice));
    final double totalSalesValue = products.fold(0, (sum, p) => sum + (p.quantity * p.salePrice));
    final int itemsCount = products.length;

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey200, width: 0.5),
        borderRadius: pw.BorderRadius.circular(6),
        color: PdfColors.white,
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildMetricStat('إجمالي القيمة (شراء)', PdfBaseService.formatCurrency(totalPurchaseValue), PdfColors.grey800, boldTtf),
          _buildVerticalSeparator(),
          _buildMetricStat('إجمالي القيمة (بيع)', PdfBaseService.formatCurrency(totalSalesValue), PdfColors.blue800, boldTtf),
          _buildVerticalSeparator(),
          _buildMetricStat('إجمالي الأصناف', itemsCount.toString(), PdfColors.indigo900, boldTtf),
        ],
      ),
    );
  }

  static pw.Widget _buildInventoryTable(List<ProductModel> products, Map<int, UnitModel> unitMap, pw.Font boldTtf, pw.Font ttf) {
    final headers = ['سعر البيع', 'سعر الشراء', 'الكمية', 'الوحدة', 'الحالة', 'اسم الصنف', 'الباركود', '#'];

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.3),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.2), // Sale
        1: const pw.FlexColumnWidth(1.2), // Purchase
        2: const pw.FlexColumnWidth(1.5), // Qty (increased width for breakdown)
        3: const pw.FlexColumnWidth(1),   // Unit
        4: const pw.FlexColumnWidth(1),   // Status
        5: const pw.FlexColumnWidth(3),   // Name
        6: const pw.FlexColumnWidth(1.2), // Barcode
        7: const pw.FixedColumnWidth(20), // #
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.indigo900),
          children: headers.map((h) => PdfBaseService.tableCell(h, boldTtf, color: PdfColors.white, size: 8, weight: pw.FontWeight.bold)).toList(),
        ),
        ...List.generate(products.length, (index) {
          final p = products[index];
          
          final status = p.isSalesStopped ? 'موقوف' : 'متوفر';
          final statusColor = p.isSalesStopped ? PdfColors.red800 : PdfColors.green800;

          final String smartQty = PdfBaseService.formatSmartQuantity(p.unitId, p.quantity, unitMap);
          final String unitName = unitMap[p.unitId]?.name ?? 'قطعة';

          return pw.TableRow(
            decoration: pw.BoxDecoration(color: index % 2 == 1 ? PdfColors.indigo.shade(0.01) : PdfColors.white),
            children: [
              PdfBaseService.tableCell(PdfBaseService.sanitize(intl.NumberFormat.decimalPattern('ar').format(p.salePrice)), ttf, size: 7.5),
              PdfBaseService.tableCell(PdfBaseService.sanitize(intl.NumberFormat.decimalPattern('ar').format(p.purchasePrice)), ttf, size: 7.5),
              PdfBaseService.tableCell(smartQty, ttf, size: 7.5),
              PdfBaseService.tableCell(unitName, ttf, size: 7.5),
              PdfBaseService.tableCell(status, boldTtf, size: 7.5, color: statusColor),
              PdfBaseService.tableCell(PdfBaseService.sanitize(p.name), ttf, size: 8),
              PdfBaseService.tableCell(PdfBaseService.sanitize(p.code ?? '-'), ttf, size: 7.5),
              PdfBaseService.tableCell((index + 1).toString(), ttf, size: 7),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildMetricStat(String label, String value, PdfColor color, pw.Font boldTtf) {
    return pw.Column(
      children: [
        PdfBaseService.safeText(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        pw.SizedBox(height: 2),
        PdfBaseService.safeText(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: color, font: boldTtf)),
      ],
    );
  }

  static pw.Widget _buildVerticalSeparator() {
    return pw.Container(height: 20, width: 0.5, color: PdfColors.grey200);
  }
}
