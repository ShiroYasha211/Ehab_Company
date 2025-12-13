// File: lib/features/suppliers/presentation/screens/suppliers_reports_screen.dart

import 'package:ehab_company_admin/features/suppliers/data/models/supplier_transaction_model.dart';
import 'package:ehab_company_admin/features/suppliers/presentation/controllers/supplier_reports_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;

class SuppliersReportsScreen extends StatelessWidget {
  const SuppliersReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SupplierReportsController controller = Get.put(SupplierReportsController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('تقارير الموردين'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          // قسم البحث عن سند
          _buildSearchCard(context, controller),
          const SizedBox(height: 20),

          // قسم عرض نتيجة البحث
          Obx(() {
            if (controller.isLoading.isTrue) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.foundTransaction.value != null) {
              return _buildTransactionDetailsCard(controller.foundTransaction.value!);
            }
            if (controller.noResultFound.isTrue) {
              return const Center(child: Text('لا يوجد سند بهذا الرقم.', style: TextStyle(color: Colors.grey)));
            }
            return const Center(child: Text('أدخل رقم سند للبحث عنه.', style: TextStyle(color: Colors.grey)));
          }),

          // يمكنك إضافة تقارير أخرى هنا لاحقًا
        ],
      ),
    );
  }

  Widget _buildSearchCard(BuildContext context, SupplierReportsController controller) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'البحث عن سند',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.searchController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'أدخل رقم السند',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: controller.searchForTransaction,
                  icon: const Icon(Icons.search),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionDetailsCard(Map<String, dynamic> data) {
    // تحويل البيانات إلى مودل لتسهيل الاستخدام
    final transaction = SupplierTransactionModel.fromMap(data);
    final supplierName = data['supplierName'] as String?;
    final formatCurrency = intl.NumberFormat.currency(locale: 'ar_SA', symbol: ' ريال');
    final isPayment = transaction.type == SupplierTransactionType.PAYMENT;

    return Card(
      elevation: 4,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('تفاصيل السند رقم: ${transaction.id}', style: Get.theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(height: 20),
            _buildInfoRow(Icons.person_outline, 'المورد:', supplierName ?? 'غير محدد'),
            _buildInfoRow(isPayment ? Icons.arrow_upward : Icons.play_for_work, 'نوع العملية:', isPayment ? 'دفعة نقدية' : 'رصيد افتتاحي'),
            _buildInfoRow(Icons.calendar_today_outlined, 'التاريخ:', intl.DateFormat('yyyy-MM-dd – hh:mm a', 'ar').format(transaction.transactionDate)),
            _buildInfoRow(Icons.attach_money, 'المبلغ:', formatCurrency.format(transaction.amount)),
            _buildInfoRow(Icons.notes_outlined, 'البيان:', transaction.notes?.isNotEmpty == true ? transaction.notes! : 'لا يوجد'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Get.theme.primaryColor),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
