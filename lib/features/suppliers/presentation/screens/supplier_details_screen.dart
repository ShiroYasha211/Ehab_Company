// File: lib/features/suppliers/presentation/screens/supplier_details_screen.dart

import 'package:ehab_company_admin/core/services/supplier_report_service.dart';
import 'package:ehab_company_admin/features/suppliers/data/models/supplier_model.dart';
import 'package:ehab_company_admin/features/suppliers/data/models/supplier_transaction_model.dart';
import 'package:ehab_company_admin/features/suppliers/presentation/controllers/supplier_details_controller.dart';
import 'package:ehab_company_admin/features/suppliers/presentation/screens/add_edit_supplier_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;

class SupplierDetailsScreen extends StatelessWidget {
  final SupplierModel supplier;

  const SupplierDetailsScreen({super.key, required this.supplier});

  @override
  Widget build(BuildContext context) {
    final SupplierDetailsController controller = Get.put(SupplierDetailsController(supplier));
    final formatCurrency = intl.NumberFormat.currency(locale: 'ar_SA', symbol: ' ريال');

    return Obx(() => Scaffold(
      appBar: AppBar(
        title: Text(controller.supplier.value.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Get.to(() => AddEditSupplierScreen(supplier: controller.supplier.value));
            },
            tooltip: 'تعديل بيانات المورد',
          ),
          IconButton(
            icon: const Icon(Icons.print_outlined),
            onPressed: () {
              SupplierReportService.printSupplierStatement(
                supplier: controller.supplier.value,
                transactions: controller.transactions,
              );
            },
            tooltip: 'طباعة كشف حساب',
          ),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: _buildHeader(context, formatCurrency, controller.supplier.value),
            ),
          ];
        },
        body: Obx(() {
          if (controller.isLoading.isTrue) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.transactions.isEmpty) {
            return const Center(
              child: Text('لا توجد حركات مالية مسجلة لهذا المورد.', style: TextStyle(color: Colors.grey)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: controller.transactions.length,
            itemBuilder: (context, index) {
              final transaction = controller.transactions[index];
              return _buildTransactionCard(transaction, formatCurrency);
            },
          );
        }),
      ),
    ));
  }

  Widget _buildHeader(BuildContext context, intl.NumberFormat formatCurrency, SupplierModel currentSupplier) {
    final balanceColor = currentSupplier.balance > 0 ? Colors.orange.shade800 : Colors.green.shade700;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('الرصيد الحالي للمورد', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              formatCurrency.format(currentSupplier.balance),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: balanceColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.business_outlined, 'الشركة', currentSupplier.company ?? 'غير محدد'),
            _buildInfoRow(Icons.phone_outlined, 'الهاتف', currentSupplier.phone ?? 'غير محدد'),
            _buildInfoRow(Icons.location_on_outlined, 'العنوان', currentSupplier.address ?? 'غير محدد'),
            _buildInfoRow(Icons.article_outlined, 'السجل التجاري', currentSupplier.commercialRecord ?? 'غير محدد'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text('$label:', style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(SupplierTransactionModel transaction, intl.NumberFormat formatCurrency) {
    bool isPayment = transaction.type == SupplierTransactionType.PAYMENT;
    Color color;
    IconData icon;
    String title = transaction.notes ?? 'حركة غير مسماة';

    if (isPayment) {
      color = Colors.green.shade700;
      icon = Icons.arrow_upward_rounded; // دفعة للمورد
    } else if (transaction.type == SupplierTransactionType.PURCHASE) {
      color = Colors.red.shade800; // دين جديد عليك
      icon = Icons.shopping_cart_outlined;
    } else { // OPENING_BALANCE
      color = Colors.purple.shade700;
      icon = Icons.play_for_work_rounded;
    }
    final amountSign = isPayment ? '-' : '+';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
            Text(
              'سند رقم: ${transaction.id}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.bold),
            )
          ],
        ),
        subtitle: Text(
          intl.DateFormat('yyyy-MM-dd – hh:mm a', 'ar').format(transaction.transactionDate),
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
        trailing: Text(
          '$amountSign ${formatCurrency.format(transaction.amount)}',
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}
