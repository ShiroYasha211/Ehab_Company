// File: lib/features/reports/data/repositories/reports_repository.dart
import '../../../../core/database/database_service.dart';
import '../models/invoice_report_model.dart';

class ReportsRepository {
  final DatabaseService _dbService = DatabaseService();

  /// دالة قوية لجلب بيانات تقرير الفواتير مع فلاتر متقدمة
  Future<List<InvoiceReportModel>> getInvoicesReport({
    DateTime? fromDate,
    DateTime? toDate,
    InvoiceTypeFilter type = InvoiceTypeFilter.all,
    PaymentStatusFilter status = PaymentStatusFilter.all,
  }) async {
    final db = await _dbService.database;

    String whereClause = "WHERE 1=1"; // شرط ابتدائي
    List<dynamic> whereArgs = [];

    // بناء شروط التاريخ
    if (fromDate != null) {
      whereClause += " AND invoiceDate >= ?";
      whereArgs.add(fromDate.toIso8601String());
    }
    if (toDate != null) {
      final inclusiveTo = toDate.add(const Duration(days: 1));
      whereClause += " AND invoiceDate < ?";
      whereArgs.add(inclusiveTo.toIso8601String());
    }

    // بناء شرط حالة الدفع
    if (status == PaymentStatusFilter.paid) {
      whereClause += " AND remainingAmount <= 0";
    } else if (status == PaymentStatusFilter.due) {
      whereClause += " AND remainingAmount > 0";
    }

    // بناء الاستعلام الرئيسي باستخدام UNION ALL
    String salesQuery = '';
    if (type == InvoiceTypeFilter.all || type == InvoiceTypeFilter.sales) {
      salesQuery = '''
            SELECT
              'SALE' as invoiceType,
              si.id,
              si.invoiceDate,
              si.totalAmount,
              si.remainingAmount,
              c.name as partyName
            FROM sales_invoices si
            LEFT JOIN customers c ON si.customerId = c.id
            $whereClause
          ''';
    }

    String purchaseQuery = '';
    if (type == InvoiceTypeFilter.all || type == InvoiceTypeFilter.purchases) {
      purchaseQuery = '''
            SELECT
              'PURCHASE' as invoiceType,
              pi.id,
              pi.invoiceDate,
              pi.totalAmount,
              pi.remainingAmount,
              s.name as partyName
            FROM purchase_invoices pi
            LEFT JOIN suppliers s ON pi.supplierId = s.id
            $whereClause
          ''';
    }

    String finalQuery = '';
    List<dynamic> finalArgs = [];

    if (salesQuery.isNotEmpty && purchaseQuery.isNotEmpty) {
      finalQuery = '$salesQuery UNION ALL $purchaseQuery';
      // يجب تكرار الوسائط لأنها تُستخدم في كلا الاستعلامين
      finalArgs.addAll(whereArgs);
      finalArgs.addAll(whereArgs);
    } else if (salesQuery.isNotEmpty) {
      finalQuery = salesQuery;
      finalArgs.addAll(whereArgs);
    } else if (purchaseQuery.isNotEmpty) {
      finalQuery = purchaseQuery;
      finalArgs.addAll(whereArgs);
    } else {
      return []; // لا يوجد استعلام للتنفيذ
    }

    finalQuery += ' ORDER BY invoiceDate DESC';

    final List<Map<String, dynamic>> maps = await db.rawQuery(finalQuery, finalArgs);

    return maps.map((map) => InvoiceReportModel.fromMap(map)).toList();
  }
}
