// File: lib/features/customers/presentation/screens/customer_details_screen.dart

import 'package:ehab_company_admin/features/customers/data/models/customer_model.dart';
import 'package:ehab_company_admin/features/customers/data/models/customer_transaction_model.dart';
import 'package:ehab_company_admin/features/customers/presentation/controllers/customer_details_controller.dart';
import 'package:ehab_company_admin/features/customers/presentation/screens/add_edit_customer_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/services/customer_report_service.dart';
import '../controllers/customer_controller.dart';

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
            // --- بداية التعديل: استدعاء الدالة الصحيحة من الـ Controller ---
            onPressed: () {
              // الآن، نحن لا نمرر البيانات، بل نستدعي الدالة التي ستقوم بكل العمل
              final customerController = Get.find<CustomerController>();
              customerController.printCustomerStatement(customer);
            },
            // --- نهاية التعديل ---
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

      // --- نهاية التعديل ---
      body: SafeArea(
        child: NestedScrollView(
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
  // ودجت عرض بطاقة الحركة (بتصميم محسن)
  Widget _buildTransactionCard(CustomerTransactionModel transaction, intl.NumberFormat formatCurrency) {
    bool isReceipt = transaction.type == CustomerTransactionType.RECEIPT;
    Color color;
    IconData icon;
    String title = transaction.notes ?? '';
    String amountSign = isReceipt ? '-' : '+'; // القبض يقلل الدين، والبيع يزيده

    // تحديد العنوان والأيقونة واللون بناءً على نوع الحركة
    if (isReceipt) {
      color = Colors.green.shade700;
      icon = Icons.arrow_downward_rounded;
      if (title.isEmpty) title = 'سند قبض'; // عنوان افتراضي
    } else if (transaction.type == CustomerTransactionType.SALE) {
      color = Colors.red.shade800;
      icon = Icons.receipt_long_outlined;
      if (title.isEmpty) title = 'فاتورة بيع'; // عنوان افتراضي
    } else { // OPENING_BALANCE
      color = Colors.purple.shade700;
      icon = Icons.play_for_work_rounded;
      if (title.isEmpty) title = 'رصيد افتتاحي'; // عنوان افتراضي
    }

    // --- بداية التعديل: إعادة تصميم الـ ListTile بالكامل ---
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        leading: CircleAvatar(
          radius: 24, // تكبير الأيقونة قليلاً
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        // استخدام Column لترتيب العناصر عموديًا
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الصف العلوي: العنوان الرئيسي والمبلغ
            Row(
              crossAxisAlignment: CrossAxisAlignment.start, // لمحاذاة العناصر من الأعلى
              children: [
                // --- بداية التعديل ---
                // 1. استخدام Flexible بدلاً من Expanded للسماح بالالتفاف
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    // 2. لا حاجة لـ overflow الآن، النص سيلتف تلقائيًا
                  ),
                ),
                const SizedBox(width: 8),
                // المبلغ في أقصى اليسار
                Text(
                  '$amountSign ${formatCurrency.format(transaction.amount)}',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
                  textDirection: TextDirection.ltr, // لضمان ظهور الإشارة صحيحة
                ),
              ],
            ),
            const SizedBox(height: 6), // مسافة بين العنوان والتفاصيل

            // الصف السفلي: التاريخ ورقم المرجع
            Row(
              children: [
                // التاريخ
                Text(
                  intl.DateFormat('yyyy-MM-dd – hh:mm a', 'ar').format(transaction.transactionDate),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const Spacer(), // Spacer لدفع العنصر التالي إلى أقصى اليسار
                // رقم المرجع (الفاتورة أو السند)
                Text(
                  '#${transaction.id}', // يمكن تغييره إلى referenceId إذا تم إضافته
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                )
              ],
            )
          ],
        ),
        // لم نعد بحاجة إلى subtitle أو trailing لأن كل شيء تم وضعه في title
      ),
    );
    // --- نهاية التعديل ---
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
