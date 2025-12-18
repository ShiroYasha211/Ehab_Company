// File: lib/features/reports/presentation/screens/customer_debts_report_screen.dart

import 'package:ehab_company_admin/features/customers/data/models/customer_model.dart';
import 'package:ehab_company_admin/features/customers/presentation/screens/customer_details_screen.dart';
import 'package:ehab_company_admin/features/reports/presentation/controllers/customer_debts_report_controller.dart';
import 'package:ehab_company_admin/features/reports/presentation/screens/reports_binding.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import 'package:url_launcher/url_launcher.dart';

class CustomerDebtsReportScreen extends StatelessWidget {
  const CustomerDebtsReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CustomerDebtsReportController controller =
    Get.put(CustomerDebtsReportController());
    final formatCurrency =
    intl.NumberFormat.currency(locale: 'ar_SA', symbol: ' ريال');

    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير ديون العملاء'),
      ),
      body: RefreshIndicator(
        onRefresh: controller.generateReport,
        child: Obx(() {
          if (controller.isLoading.isTrue) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.indebtedCustomers.isEmpty) {
            return const Center(
              child: Text('لا يوجد عملاء عليهم ديون حاليًا.',
                  style: TextStyle(color: Colors.grey, fontSize: 16)),
            );
          }

          return Column(
            children: [
              // 1. بطاقة الملخص
              _buildSummaryCard(controller, formatCurrency),

              // 2. خيارات الفرز
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Obx(() => SegmentedButton<CustomerDebtSortOrder>(
                  segments: const [
                    ButtonSegment(
                        value: CustomerDebtSortOrder.byHighestDebt,
                        label: Text('الأعلى دينًا')),
                    ButtonSegment(
                        value: CustomerDebtSortOrder.byOldestDebt,
                        label: Text('الأقدم دينًا')),
                    ButtonSegment(
                        value: CustomerDebtSortOrder.byName,
                        label: Text('ترتيب أبجدي')),
                  ],
                  selected: {controller.sortOrder.value},
                  onSelectionChanged: (newSelection) {
                    controller.sortOrder.value = newSelection.first;
                  },
                )),
              ),
              const Divider(),

              // 3. قائمة العملاء
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: controller.indebtedCustomers.length,
                  itemBuilder: (context, index) {
                    final customer = controller.indebtedCustomers[index];
                    return _buildCustomerDebtCard(customer, formatCurrency);
                  },
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  /// ودجت بناء بطاقة الملخص
  Widget _buildSummaryCard(CustomerDebtsReportController controller,
      intl.NumberFormat formatCurrency) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem('إجمالي الديون',
                formatCurrency.format(controller.totalDebtAmount.value)),
            const SizedBox(
                height: 50, child: VerticalDivider(thickness: 1)),
            _buildSummaryItem('عدد العملاء',
                controller.indebtedCustomers.length.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Get.theme.primaryColor)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  /// ودجت بناء بطاقة العميل المدين التفاعلية
  Widget _buildCustomerDebtCard(
      CustomerModel customer, intl.NumberFormat formatCurrency) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              title: Text(customer.name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(customer.phone ?? 'لا يوجد رقم هاتف',
                  style: TextStyle(color: Colors.grey.shade600)),
              trailing: Text(
                formatCurrency.format(customer.balance),
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.red.shade700),
              ),
            ),
            const Divider(height: 1),
            // أزرار الإجراءات السريعة
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.receipt_long_outlined, size: 20),
                  label: const Text('كشف حساب'),
                  onPressed: () {
                    Get.to(() => CustomerDetailsScreen(customer: customer),
                    binding: ReportsBinding());
                  },
                ),
                TextButton.icon(
                  icon: const Icon(Icons.phone_outlined, size: 20),
                  label: const Text('اتصال'),
                  onPressed: () async {
                    if (customer.phone != null &&
                        customer.phone!.isNotEmpty) {
                      final Uri url = Uri(scheme: 'tel', path: customer.phone);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      }
                    }
                  },
                ),
                TextButton.icon(
                  icon: const Icon(Icons.message_outlined, size: 20),
                  label: const Text('واتساب'),
                  onPressed: () async {
                    if (customer.phone != null &&
                        customer.phone!.isNotEmpty) {
                      final Uri url =
                      Uri.parse('https://wa.me/${customer.phone}');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url,
                            mode: LaunchMode.externalApplication);
                      }
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
