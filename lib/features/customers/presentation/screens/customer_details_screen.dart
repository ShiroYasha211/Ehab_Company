// File: lib/features/customers/presentation/screens/customer_details_screen.dart

import 'package:ehab_company_admin/features/customers/data/models/customer_model.dart';
import 'package:ehab_company_admin/features/customers/data/models/customer_transaction_model.dart';
import 'package:ehab_company_admin/features/customers/presentation/controllers/customer_details_controller.dart';
import 'package:ehab_company_admin/features/customers/presentation/screens/add_edit_customer_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/services/customer_report_service.dart';

class CustomerDetailsScreen extends StatelessWidget {
  final CustomerModel customer;
  const CustomerDetailsScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    final CustomerDetailsController controller = Get.put(CustomerDetailsController(customer));
    final formatCurrency = intl.NumberFormat.currency(locale: 'ar_SA', symbol: ' ريال');

    // ... (داخل build method)
    return Obx(() => Scaffold(
      appBar: AppBar(
        title: Text(controller.customer.value.name),
        actions: [
          // --- بداية التعديل ---
          IconButton(
            icon: const Icon(Icons.print_outlined),
            onPressed: () {
              // التأكد من أن قائمة الحركات ليست فارغة قبل الطباعة
              if (controller.transactions.isNotEmpty) {
                CustomerReportService.printCustomerStatement(
                  customer: controller.customer.value,
                  transactions: controller.transactions,
                );
              } else {
                Get.snackbar('لا يمكن الطباعة', 'لا توجد حركات مالية لطباعتها.');
              }
            },
            tooltip: 'طباعة كشف حساب',
          ),
          // --- نهاية التعديل ---
// ...

          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Get.to(() => AddEditCustomerScreen(customer: controller.customer.value));
            },
            tooltip: 'تعديل بيانات العميل',
          ),
        ],
      ),
      // --- بداية التعديل: استخدام bottomNavigationBar ---
      bottomNavigationBar: Obx(() {
        // أظهر زر الدفع فقط إذا كان على العميل رصيد
        if (controller.customer.value.balance <= 0) {
          return const SizedBox.shrink();
        }
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_card_rounded),
              label: const Text('تسجيل دفعة (سند قبض)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: const TextStyle(fontSize: 18),
              ),
              onPressed: () => _showAddPaymentDialog(context, controller),
            ),
          ),
        );
      }),
      // --- نهاية التعديل ---
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: _buildHeader(context, formatCurrency, controller.customer.value),
            ),
          ];
        },
        body: Obx(() {
          if (controller.isLoading.isTrue) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.transactions.isEmpty) {
            return const Center(
              child: Text('لا توجد حركات مالية مسجلة لهذا العميل.', style: TextStyle(color: Colors.grey)),
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

  // ودجت الهيدر الجديد (مطابق لتصميم الموردين)
  Widget _buildHeader(BuildContext context, intl.NumberFormat formatCurrency, CustomerModel currentCustomer) {
    // عكس الألوان: الرصيد الموجب (دين) يظهر باللون البرتقالي/الأحمر
    final balanceColor = currentCustomer.balance > 0 ? Colors.orange.shade800 : Colors.green.shade700;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('الرصيد المستحق على العميل', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              formatCurrency.format(currentCustomer.balance),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: balanceColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.phone_outlined, 'الهاتف', currentCustomer.phone ?? 'غير محدد'),
            _buildInfoRow(Icons.business_outlined, 'الشركة', currentCustomer.company ?? 'غير محدد'),
            _buildInfoRow(Icons.location_on_outlined, 'العنوان', currentCustomer.address ?? 'غير محدد'),
            _buildInfoRow(Icons.email_outlined, 'البريد الإلكتروني', currentCustomer.email ?? 'غير محدد'),
          ],
        ),
      ),
    );
  }

  // ودجت عرض معلومات العميل (مطابق لتصميم الموردين)
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

  // ودجت عرض بطاقة الحركة (مطابق لتصميم الموردين)
  Widget _buildTransactionCard(CustomerTransactionModel transaction, intl.NumberFormat formatCurrency) {
    bool isReceipt = transaction.type == CustomerTransactionType.RECEIPT;
    Color color;
    IconData icon;
    String title = transaction.notes ?? 'حركة غير مسماة';
    String amountSign = isReceipt ? '-' : '+'; // القبض يقلل الدين، والبيع يزيده

    if (isReceipt) {
      color = Colors.green.shade700;
      icon = Icons.arrow_downward_rounded; // سهم لأسفل (قبض)
    } else if (transaction.type == CustomerTransactionType.SALE) {
      color = Colors.red.shade800; // فاتورة (دين جديد)
      icon = Icons.receipt_long_outlined;
    } else { // OPENING_BALANCE
      color = Colors.purple.shade700;
      icon = Icons.play_for_work_rounded;
    }

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
              'سند قبض رقم: ${transaction.id}',
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

  // ديالوج إضافة دفعة (يبقى كما هو)
  void _showAddPaymentDialog(BuildContext context, CustomerDetailsController controller) {
    final amountController = TextEditingController();
    final notesController = TextEditingController();

    Get.dialog(AlertDialog(
      title: const Text('تسجيل دفعة من العميل'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
              'الرصيد الحالي: ${intl.NumberFormat.currency(locale: 'ar_SA', symbol: 'ريال').format(controller.customer.value.balance)}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextFormField(
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'أدخل مبلغ الدفعة',
              prefixIcon: Icon(Icons.money),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'الرجاء إدخال المبلغ';
              final amount = double.tryParse(value);
              if (amount == null) return 'مبلغ غير صالح';
              if (amount > controller.customer.value.balance) return 'المبلغ أكبر من الرصيد المستحق';
              return null;
            },
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: notesController,
            decoration: const InputDecoration(
              labelText: 'ملاحظات (اختياري)',
              prefixIcon: Icon(Icons.notes),
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () {
            final double amount = double.tryParse(amountController.text) ?? 0.0;
            // التحقق من الصحة قبل الإرسال
            if (amount > 0 && amount <= controller.customer.value.balance) {
              controller.addReceiptTransaction(amount, notesController.text);
            } else {
              Get.snackbar('خطأ', 'الرجاء إدخال مبلغ صحيح لا يتجاوز الرصيد المستحق.');
            }
          },
          child: const Text('تأكيد الدفعة'),
        ),
      ],
    ));
  }
}
