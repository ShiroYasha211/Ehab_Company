// File: lib/features/financial_docs/presentation/screens/transaction_details_screen.dart

import 'package:ehab_company_admin/features/customers/data/models/customer_transaction_model.dart';
import 'package:ehab_company_admin/features/suppliers/data/models/supplier_transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/services/voucher_pdf_service.dart';

class TransactionDetailsScreen extends StatelessWidget {
  final dynamic transaction; // يمكن أن يكون إما SupplierTransactionModel أو CustomerTransactionModel

  const TransactionDetailsScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    // تحديد نوع السند والبيانات
    final bool isSupplier = transaction is SupplierTransactionModel;
    final String transactionTypeString;
    final String partyLabel; // "المورد" أو "العميل"
    final String partyName;
    final String transactionId = transaction.id.toString();
    final String amount = intl.NumberFormat.currency(locale: 'ar_SA', symbol: ' ريال').format(transaction.amount);
    final String date = intl.DateFormat('yyyy-MM-dd – hh:mm a', 'ar').format(transaction.transactionDate);
    final String notes = transaction.notes ?? 'لا توجد ملاحظات';
    final bool affectsFund = transaction.affectsFund;

    if (isSupplier) {
      partyLabel = 'المورد';
      partyName = (transaction as SupplierTransactionModel).supplierName ?? 'غير محدد';
      final type = (transaction as SupplierTransactionModel).type;
      transactionTypeString = type == SupplierTransactionType.PAYMENT ? 'سند دفع' : 'رصيد افتتاحي';
    } else {
      partyLabel = 'العميل';
      partyName = (transaction as CustomerTransactionModel).customerName ?? 'غير محدد';
      final type = (transaction as CustomerTransactionModel).type;
      transactionTypeString = type == CustomerTransactionType.RECEIPT ? 'سند قبض' : 'رصيد افتتاحي';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('تفاصيل سند رقم #$transactionId'),
        // --- بداية التعديل ---
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            onPressed: () {
              VoucherPdfService.printVoucher(transaction);
            },
            tooltip: 'طباعة السند',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryCard(transactionTypeString, amount, isSupplier),
          const SizedBox(height: 20),
          _buildDetailsCard(partyLabel, partyName, date, notes, affectsFund),
        ],
      ),
    );
  }

  /// ودجت بناء بطاقة الملخص الرئيسية
  Widget _buildSummaryCard(String title, String amount, bool isSupplier) {
    final color = isSupplier ? Colors.blue.shade700 : Colors.green.shade700;
    final icon = isSupplier ? Icons.upload_file_rounded : Icons.download_done_rounded;

    return Card(
      elevation: 4,
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 40),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                amount,
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ودجت بناء بطاقة التفاصيل
  Widget _buildDetailsCard(String partyLabel, String partyName, String date, String notes, bool affectsFund) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoRow(partyLabel, partyName),
            _buildInfoRow('تاريخ السند', date),
            _buildInfoRow('الملاحظات', notes),
            const Divider(),
            _buildInfoRow(
              'التأثير على الصندوق',
              affectsFund ? 'نعم، تم التأثير على الصندوق' : 'لا، لم يؤثر على الصندوق',
              highlightColor: affectsFund ? Colors.orange.shade700 : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  /// ودجت مساعد لعرض كل صف من المعلومات
  Widget _buildInfoRow(String label, String value, {Color? highlightColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label:', style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: highlightColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
