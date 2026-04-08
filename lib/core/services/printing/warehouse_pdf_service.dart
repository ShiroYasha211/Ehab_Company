import 'dart:io';

import 'package:ehab_company_admin/features/fund/data/models/fund_model.dart';
import 'package:ehab_company_admin/features/units/data/models/unit_model.dart';
import 'package:ehab_company_admin/features/units/data/repositories/unit_repository.dart';
import 'package:ehab_company_admin/features/warehouses/data/models/custody_model.dart';
import 'package:ehab_company_admin/features/warehouses/data/models/inventory_transfer_model.dart';
import 'package:intl/intl.dart' as intl;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'pdf_base_service.dart';
import 'tafqeet_service.dart';

class WarehousePdfService {
  static Future<void> printTransferDocument({
    required InventoryTransferModel transfer,
    required List<InventoryTransferItemModel> items,
  }) async {
    final pdf = pw.Document();
    final resources = await PdfBaseService.loadResources();
    final pw.Font ttf = resources['ttf'];
    final pw.Font boldTtf = resources['boldTtf'];
    final pw.MemoryImage logo = resources['logo'];
    final units = await UnitRepository().getAllUnits();
    final unitsMap = {for (final unit in units) unit.id!: unit};

    final totalQty = items.fold<double>(
      0.0,
      (sum, item) => sum + item.quantity,
    );
    final qrData =
        'TRANSFER:${transfer.id}\nDATE:${transfer.transferDate.toIso8601String()}\nFROM:${transfer.sourceWarehouseName ?? ''}\nTO:${transfer.destinationWarehouseName ?? ''}\nTOTAL:${transfer.totalValue.toStringAsFixed(2)}';

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
            width: 42,
            height: 42,
            drawText: false,
          ),
        ),
        footer: (context) => PdfBaseService.buildFooter(context, ttf),
        build: (context) => [
          _buildDocumentTitle(
            title: 'سند تحويل مخزني',
            number: transfer.id ?? 0,
            date: transfer.transferDate,
            boldTtf: boldTtf,
            ttf: ttf,
            accent: PdfColors.orange800,
          ),
          pw.SizedBox(height: 14),
          _buildTransferInfo(transfer, ttf, boldTtf),
          pw.SizedBox(height: 14),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              PdfBaseService.buildStatCard(
                'عدد الأصناف',
                items.length.toString(),
                color: PdfColors.indigo800,
              ),
              PdfBaseService.buildStatCard(
                'إجمالي الكمية',
                _formatNumber(totalQty),
                color: PdfColors.orange800,
              ),
              PdfBaseService.buildStatCard(
                'قيمة البيع',
                PdfBaseService.formatCurrency(transfer.totalValue),
                color: PdfColors.green800,
              ),
              PdfBaseService.buildStatCard(
                'قيمة التكلفة',
                PdfBaseService.formatCurrency(transfer.totalCostValue),
                color: PdfColors.red800,
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          _buildTransferItemsTable(items, unitsMap, ttf, boldTtf),
          if ((transfer.notes ?? '').trim().isNotEmpty) ...[
            pw.SizedBox(height: 12),
            _buildNotesCard(transfer.notes!, ttf, boldTtf),
          ],
          pw.SizedBox(height: 18),
          _buildSignatures(ttf),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/warehouse_transfer_${transfer.id}.pdf');
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }

  static Future<void> printCustodySettlementDocument({
    required CustodySettlementModel settlement,
    required List<CustodySettlementItemModel> items,
    FundModel? fund,
  }) async {
    final pdf = pw.Document();
    final resources = await PdfBaseService.loadResources();
    final pw.Font ttf = resources['ttf'];
    final pw.Font boldTtf = resources['boldTtf'];
    final pw.MemoryImage logo = resources['logo'];

    final qrData =
        'SETTLEMENT:${settlement.id}\nWAREHOUSE:${settlement.warehouseName ?? ''}\nDATE:${settlement.settlementDate.toIso8601String()}\nSOLD:${settlement.totalSoldValue.toStringAsFixed(2)}\nRECEIVED:${settlement.receivedAmount.toStringAsFixed(2)}';

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
            width: 42,
            height: 42,
            drawText: false,
          ),
        ),
        footer: (context) => PdfBaseService.buildFooter(context, ttf),
        build: (context) => [
          _buildDocumentTitle(
            title: 'تقرير تسوية عهدة',
            number: settlement.id ?? 0,
            date: settlement.settlementDate,
            boldTtf: boldTtf,
            ttf: ttf,
            accent: PdfColors.indigo900,
          ),
          pw.SizedBox(height: 14),
          _buildSettlementInfo(settlement, fund, ttf, boldTtf),
          pw.SizedBox(height: 14),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              PdfBaseService.buildStatCard(
                'المباع',
                PdfBaseService.formatCurrency(settlement.totalSoldValue),
                color: PdfColors.indigo800,
              ),
              PdfBaseService.buildStatCard(
                'المستلم',
                PdfBaseService.formatCurrency(settlement.receivedAmount),
                color: PdfColors.green800,
              ),
              PdfBaseService.buildStatCard(
                'فرق التسوية',
                PdfBaseService.formatCurrency(settlement.settlementDifference),
                color: settlement.settlementDifference > 0
                    ? PdfColors.red800
                    : PdfColors.green800,
              ),
              PdfBaseService.buildStatCard(
                'الرصيد الجديد',
                PdfBaseService.formatCurrency(settlement.newBalance),
                color: settlement.newBalance > 0
                    ? PdfColors.red800
                    : PdfColors.green800,
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          _buildSettlementItemsTable(items, ttf, boldTtf),
          pw.SizedBox(height: 14),
          _buildSettlementSummary(settlement, ttf, boldTtf),
          if ((settlement.notes ?? '').trim().isNotEmpty) ...[
            pw.SizedBox(height: 12),
            _buildNotesCard(settlement.notes!, ttf, boldTtf),
          ],
          pw.SizedBox(height: 18),
          _buildSignatures(ttf),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/custody_settlement_${settlement.id}.pdf');
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }

  static pw.Widget _buildDocumentTitle({
    required String title,
    required int number,
    required DateTime date,
    required pw.Font boldTtf,
    required pw.Font ttf,
    required PdfColor accent,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: pw.BoxDecoration(
            color: accent,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: PdfBaseService.safeText(
            title,
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              font: boldTtf,
            ),
          ),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            PdfBaseService.safeText(
              'رقم المستند: #$number',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                font: boldTtf,
              ),
            ),
            PdfBaseService.safeText(
              'التاريخ: ${intl.DateFormat('yyyy/MM/dd - hh:mm a', 'ar').format(date)}',
              style: pw.TextStyle(fontSize: 9, font: ttf),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTransferInfo(
    InventoryTransferModel transfer,
    pw.Font ttf,
    pw.Font boldTtf,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.orange50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: PdfColors.orange200),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: _buildInfoColumn(
              'من المخزن',
              transfer.sourceWarehouseName ?? '-',
              ttf,
              boldTtf,
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: _buildInfoColumn(
              'إلى المخزن',
              transfer.destinationWarehouseName ?? '-',
              ttf,
              boldTtf,
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: _buildInfoColumn(
              'الحالة',
              transfer.status == 'COMPLETED' ? 'مكتمل' : transfer.status,
              ttf,
              boldTtf,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSettlementInfo(
    CustodySettlementModel settlement,
    FundModel? fund,
    pw.Font ttf,
    pw.Font boldTtf,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.indigo50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: PdfColors.indigo100),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildInfoColumn(
                  'المندوب',
                  settlement.warehouseName ?? 'مندوب',
                  ttf,
                  boldTtf,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _buildInfoColumn(
                  'طريقة التحصيل',
                  _paymentMethodLabel(settlement.paymentMethod),
                  ttf,
                  boldTtf,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _buildInfoColumn(
                  'الصندوق / الحساب',
                  fund?.name ?? 'غير محدد',
                  ttf,
                  boldTtf,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildInfoColumn(
                  'الرصيد السابق',
                  PdfBaseService.formatCurrency(settlement.previousBalance),
                  ttf,
                  boldTtf,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _buildInfoColumn(
                  'المبلغ كتابة',
                  TafqeetService.convert(settlement.receivedAmount),
                  ttf,
                  boldTtf,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTransferItemsTable(
    List<InventoryTransferItemModel> items,
    Map<int, UnitModel> unitsMap,
    pw.Font ttf,
    pw.Font boldTtf,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.3),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.4),
        1: const pw.FlexColumnWidth(1.4),
        2: const pw.FlexColumnWidth(1.2),
        3: const pw.FlexColumnWidth(1.2),
        4: const pw.FlexColumnWidth(1.6),
        5: const pw.FlexColumnWidth(3.2),
        6: const pw.FixedColumnWidth(24),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.orange800),
          children: [
            _headerCell('إجمالي شراء', boldTtf),
            _headerCell('إجمالي بيع', boldTtf),
            _headerCell('شراء', boldTtf),
            _headerCell('بيع', boldTtf),
            _headerCell('الكمية', boldTtf),
            _headerCell('الصنف', boldTtf),
            _headerCell('#', boldTtf),
          ],
        ),
        ...List.generate(items.length, (index) {
          final item = items[index];
          final quantityText = item.unitId != null
              ? PdfBaseService.formatSmartQuantity(
                  item.unitId,
                  item.quantity,
                  unitsMap,
                )
              : _formatNumber(item.quantity);
          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: index.isEven ? PdfColors.white : PdfColors.orange50,
            ),
            children: [
              PdfBaseService.tableCell(
                _formatNumber(item.totalCostValue),
                ttf,
                size: 8,
              ),
              PdfBaseService.tableCell(
                _formatNumber(item.totalSaleValue),
                ttf,
                size: 8,
              ),
              PdfBaseService.tableCell(
                _formatNumber(item.purchasePrice),
                ttf,
                size: 8,
              ),
              PdfBaseService.tableCell(
                _formatNumber(item.salePrice),
                ttf,
                size: 8,
              ),
              PdfBaseService.tableCell(quantityText, ttf, size: 7.5),
              PdfBaseService.tableCell(item.productName, ttf, size: 8),
              PdfBaseService.tableCell('${index + 1}', ttf, size: 8),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildSettlementItemsTable(
    List<CustodySettlementItemModel> items,
    pw.Font ttf,
    pw.Font boldTtf,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.3),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.4),
        1: const pw.FlexColumnWidth(1.2),
        2: const pw.FlexColumnWidth(1.2),
        3: const pw.FlexColumnWidth(1.2),
        4: const pw.FlexColumnWidth(1.2),
        5: const pw.FlexColumnWidth(1.2),
        6: const pw.FlexColumnWidth(3),
        7: const pw.FixedColumnWidth(24),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.indigo900),
          children: [
            _headerCell('قيمة المباع', boldTtf),
            _headerCell('السعر', boldTtf),
            _headerCell('المتبقي', boldTtf),
            _headerCell('المرتجع', boldTtf),
            _headerCell('المباع', boldTtf),
            _headerCell('المتاح', boldTtf),
            _headerCell('الصنف', boldTtf),
            _headerCell('#', boldTtf),
          ],
        ),
        ...List.generate(items.length, (index) {
          final item = items[index];
          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: index.isEven ? PdfColors.white : PdfColors.indigo50,
            ),
            children: [
              PdfBaseService.tableCell(
                _formatNumber(item.soldValue),
                ttf,
                size: 8,
              ),
              PdfBaseService.tableCell(
                _formatNumber(item.salePricePerBaseUnit),
                ttf,
                size: 8,
              ),
              PdfBaseService.tableCell(
                _formatNumber(item.remainingQty),
                ttf,
                size: 8,
              ),
              PdfBaseService.tableCell(
                _formatNumber(item.returnedQty),
                ttf,
                size: 8,
              ),
              PdfBaseService.tableCell(
                _formatNumber(item.soldQty),
                ttf,
                size: 8,
              ),
              PdfBaseService.tableCell(
                _formatNumber(item.availableQty),
                ttf,
                size: 8,
              ),
              PdfBaseService.tableCell(item.productName, ttf, size: 8),
              PdfBaseService.tableCell('${index + 1}', ttf, size: 8),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildSettlementSummary(
    CustodySettlementModel settlement,
    pw.Font ttf,
    pw.Font boldTtf,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        children: [
          _summaryRow(
            'إجمالي المباع',
            PdfBaseService.formatCurrency(settlement.totalSoldValue),
            ttf,
            boldTtf,
          ),
          _summaryRow(
            'المبلغ المستلم',
            PdfBaseService.formatCurrency(settlement.receivedAmount),
            ttf,
            boldTtf,
          ),
          _summaryRow(
            'فرق التسوية',
            PdfBaseService.formatCurrency(settlement.settlementDifference),
            ttf,
            boldTtf,
          ),
          _summaryRow(
            'الرصيد السابق',
            PdfBaseService.formatCurrency(settlement.previousBalance),
            ttf,
            boldTtf,
          ),
          _summaryRow(
            'الرصيد الجديد',
            PdfBaseService.formatCurrency(settlement.newBalance),
            ttf,
            boldTtf,
            isLast: true,
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildNotesCard(String notes, pw.Font ttf, pw.Font boldTtf) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          PdfBaseService.safeText(
            'ملاحظات',
            style: pw.TextStyle(
              font: boldTtf,
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
            ),
          ),
          pw.SizedBox(height: 5),
          PdfBaseService.safeText(
            notes,
            style: pw.TextStyle(font: ttf, fontSize: 9),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSignatures(pw.Font ttf) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _signatureBlock('المستلم', ttf),
        _signatureBlock('أمين المخزن', ttf),
        _signatureBlock('الاعتماد', ttf),
      ],
    );
  }

  static pw.Widget _buildInfoColumn(
    String label,
    String value,
    pw.Font ttf,
    pw.Font boldTtf,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        PdfBaseService.safeText(
          label,
          style: pw.TextStyle(fontSize: 8, font: ttf, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 3),
        PdfBaseService.safeText(
          value,
          style: pw.TextStyle(
            fontSize: 10,
            font: boldTtf,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  static pw.Widget _summaryRow(
    String label,
    String value,
    pw.Font ttf,
    pw.Font boldTtf, {
    bool isLast = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      decoration: isLast
          ? null
          : const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.4),
              ),
            ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          PdfBaseService.safeText(
            label,
            style: pw.TextStyle(font: ttf, fontSize: 9),
          ),
          PdfBaseService.safeText(
            value,
            style: pw.TextStyle(
              font: boldTtf,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _signatureBlock(String label, pw.Font ttf) {
    return pw.Column(
      children: [
        pw.SizedBox(height: 34),
        pw.Container(
          width: 120,
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: PdfColors.grey400, width: 0.6),
            ),
          ),
        ),
        pw.SizedBox(height: 4),
        PdfBaseService.safeText(
          label,
          style: pw.TextStyle(font: ttf, fontSize: 8.5),
          align: pw.TextAlign.center,
        ),
      ],
    );
  }

  static pw.Widget _headerCell(String text, pw.Font boldTtf) {
    return PdfBaseService.tableCell(
      text,
      boldTtf,
      color: PdfColors.white,
      weight: pw.FontWeight.bold,
      size: 8.5,
    );
  }

  static String _paymentMethodLabel(String? method) {
    switch (method) {
      case 'cash':
        return 'نقد';
      case 'bank':
        return 'بنك';
      case 'transfer':
        return 'حوالة';
      default:
        return method?.trim().isNotEmpty == true ? method! : 'غير محدد';
    }
  }

  static String _formatNumber(double value) {
    return PdfBaseService.sanitize(
      intl.NumberFormat.decimalPattern('ar').format(value),
    );
  }
}
