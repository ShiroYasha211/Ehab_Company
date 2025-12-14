// File: lib/features/customers/presentation/screens/list_customers_screen.dart

import 'package:ehab_company_admin/features/customers/data/models/customer_model.dart';
import 'package:ehab_company_admin/features/customers/presentation/controllers/customer_controller.dart';
import 'package:ehab_company_admin/features/customers/presentation/screens/add_edit_customer_screen.dart';
// --- 1. بداية التعديل: إضافة import ---
import 'package:ehab_company_admin/features/customers/presentation/screens/customer_details_screen.dart';
// --- نهاية التعديل ---
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ListCustomersScreen extends StatelessWidget {
  const ListCustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // يجب أن يكون Controller قد تم إنشاؤه في شاشة لوحة التحكم
    final CustomerController controller = Get.find<CustomerController>();
    final searchController = TextEditingController(text: controller.searchQuery.value);
    return Scaffold(
      appBar: AppBar(
        title: const Text('قائمة العملاء'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120.0),
          child: Column(
            children: [
              // شريط البحث
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: searchController,
                  onChanged: (value) => controller.searchQuery.value = value,
                  decoration: InputDecoration(
                    hintText: 'ابحث بالاسم أو رقم الهاتف...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Theme.of(context).scaffoldBackgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        searchController.clear();
                        controller.searchQuery.value = '';
                      },
                    )
                        : const SizedBox.shrink()),
                  ),
                ),
              ),
              // أزرار الفلترة
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Obx(() => SegmentedButton<CustomerFilter>(
                  segments: const [
                    ButtonSegment(value: CustomerFilter.all, label: Text('الكل')),
                    ButtonSegment(value: CustomerFilter.hasBalance, label: Text('عليهم رصيد')),
                    ButtonSegment(value: CustomerFilter.noBalance, label: Text('رصيد صفري')),
                  ],
                  selected: {controller.currentFilter.value},
                  onSelectionChanged: (newSelection) {
                    controller.currentFilter.value = newSelection.first;
                  },
                )),
              ),
            ],
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.isTrue) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.filteredCustomers.isEmpty) {
          return const Center(child: Text('لا يوجد عملاء يطابقون بحثك.', style: TextStyle(color: Colors.grey)));
        }
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 80),
          itemCount: controller.filteredCustomers.length,
          itemBuilder: (context, index) {
            final customer = controller.filteredCustomers[index];
            return CustomerCard(customer: customer);
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => const AddEditCustomerScreen()),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ودجت منفصل لبطاقة العميل
class CustomerCard extends StatelessWidget {
  final CustomerModel customer;
  const CustomerCard({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    final hasBalance = customer.balance > 0;
    final balanceColor = hasBalance ? Colors.blue.shade800 : Colors.green.shade700;
    final formatCurrency = NumberFormat.currency(locale: 'ar_SA', symbol: 'ريال');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: hasBalance ? balanceColor : Colors.transparent,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        // --- 2. بداية التعديل: تفعيل on Tap ---
        onTap: () {
          Get.to(() => CustomerDetailsScreen(customer: customer));
        },
        // --- نهاية التعديل ---
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                customer.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'الرصيد المستحق:',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  Text(
                    formatCurrency.format(customer.balance),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: balanceColor,
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (customer.phone != null && customer.phone!.isNotEmpty) ...[
                    IconButton(
                      icon: Icon(Icons.phone_in_talk_rounded, color: Colors.green.shade700),
                      onPressed: () async {
                        final Uri url = Uri(scheme: 'tel', path: customer.phone);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      },
                      tooltip: 'اتصال',
                    ),
                    IconButton(
                      icon: const Icon(Icons.message_outlined),
                      onPressed: () async {
                        final Uri url = Uri.parse('https://wa.me/${customer.phone}');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      },
                      tooltip: 'واتساب',
                    ),
                  ],
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.delete_forever_rounded, color: Theme.of(context).colorScheme.error),
                    onPressed: () {
                      Get.defaultDialog(
                        title: 'تأكيد الحذف',
                        middleText: 'هل أنت متأكد من حذف العميل "${customer.name}"؟',
                        onConfirm: () {
                          Get.find<CustomerController>().removeCustomer(customer.id!);
                          Get.back();
                        },
                        textConfirm: 'حذف',
                        textCancel: 'إلغاء',
                      );
                    },
                    tooltip: 'حذف',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
