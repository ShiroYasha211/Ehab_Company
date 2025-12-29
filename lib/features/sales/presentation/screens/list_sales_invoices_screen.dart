// File: lib/features/sales/presentation/screens/list_sales_invoices_screen.dart

import 'package:ehab_company_admin/features/customers/data/models/customer_model.dart';
import 'package:ehab_company_admin/features/sales/data/models/sales_invoice_summary_model.dart';
import 'package:ehab_company_admin/features/sales/presentation/controllers/list_sales_controller.dart';
import 'package:ehab_company_admin/features/sales/presentation/screens/sales_details_screen.dart'; // سيتم تفعيله لاحقًا
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/services/settings_service.dart';

class ListSalesInvoicesScreen extends StatelessWidget {
  const ListSalesInvoicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ListSalesController controller = Get.put(ListSalesController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('أرشيف فواتير المبيعات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_off_outlined),
            tooltip: 'مسح الفلاتر',
            onPressed: controller.clearFilters,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(130.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller.searchController,
                        keyboardType: TextInputType.number,
                        onChanged: (value) =>
                            controller.searchQuery.value = value,
                        decoration: InputDecoration(
                          hintText: 'بحث برقم الفاتورة...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Obx(() {
                        // استخدام filteredCustomers من CustomerController
                        return DropdownButtonFormField<CustomerModel?>(
                          value: controller.selectedCustomer.value,
                          items: [
                            const DropdownMenuItem<CustomerModel?>(
                              value: null,
                              child: Text('كل العملاء'),
                            ),
                            ...controller.customerController.filteredCustomers
                                .map((customer) {
                                  return DropdownMenuItem<CustomerModel?>(
                                    value: customer,
                                    child: Text(customer.name),
                                  );
                                })
                                .toList(),
                          ],
                          onChanged: (value) {
                            controller.selectedCustomer.value = value;
                          },
                          decoration: InputDecoration(
                            hintText: 'اختر عميلًا',
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            isDense: true,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Obx(
                    () => SegmentedButton<InvoiceFilterStatus>(
                      segments: const [
                        ButtonSegment(
                          value: InvoiceFilterStatus.all,
                          label: Text('الكل'),
                        ),
                        ButtonSegment(
                          value: InvoiceFilterStatus.due,
                          label: Text('آجلة'),
                        ),
                        ButtonSegment(
                          value: InvoiceFilterStatus.paid,
                          label: Text('مدفوعة'),
                        ),
                        ButtonSegment(
                          value: InvoiceFilterStatus.returned,
                          label: Text('مرتجعة'),
                        ),
                      ],
                      selected: {controller.selectedStatus.value},
                      onSelectionChanged: (newSelection) {
                        controller.selectedStatus.value = newSelection.first;
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.isTrue) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.invoices.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد فواتير تطابق بحثك.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: controller.invoices.length,
            itemBuilder: (context, index) {
              final invoice = controller.invoices[index];
              return SalesInvoiceCard(
                invoice: invoice,
              ); // استخدام بطاقة المبيعات
            },
          );
        }),
      ),
    );
  }
}

// ودجت مخصص لبطاقة فاتورة المبيعات
class SalesInvoiceCard extends StatelessWidget {
  final SalesInvoiceSummaryModel invoice;

  const SalesInvoiceCard({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    late Color statusColor;
    late String statusText;

    if (invoice.status == 'RETURNED') {
      statusColor = Colors.red.shade700;
      statusText = 'مرتجعة';
    } else {
      final bool isPaid = invoice.remainingAmount <= 0;
      statusColor = isPaid ? Colors.green.shade700 : Colors.orange.shade700;
      statusText = isPaid ? 'مدفوعة' : 'آجلة';
    }

    Widget _buildPriceWidget(double price) {
      final settings = Get.find<SettingsService>();
      final primarySymbol = settings.primaryCurrency.value.symbol;
      final primaryPrice = '${price.toStringAsFixed(2)} $primarySymbol';

      if (settings.showBothCurrenciesInInvoice.value &&
          !settings.isLocalSameAsPrimary.value) {
        final localPrice = price * settings.exchangeRate.value;
        final localSymbol = settings.localCurrency.value.symbol;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              primaryPrice,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Get.theme.primaryColor,
              ),
            ),
            Text(
              '${localPrice.toStringAsFixed(2)} $localSymbol',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        );
      }
      return Text(
        primaryPrice,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Get.theme.primaryColor,
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: statusColor.withOpacity(0.6), width: 1.5),
      ),
      child: InkWell(
        onTap: () {
          Get.to(
            () => SalesDetailsScreen(invoiceId: invoice.id),
          ); // سيتم تفعيله لاحقًا
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'فاتورة #${invoice.id}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                invoice.customerName ?? 'عميل غير محدد', // اسم العميل
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoChip(
                    Icons.calendar_today_outlined,
                    intl.DateFormat('yyyy-MM-dd').format(invoice.invoiceDate),
                  ),
                  _buildInfoChip(
                    Icons.attach_money_outlined,
                    _buildPriceWidget(invoice.totalAmount),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, dynamic content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        content is Widget
            ? content
            : Text(
                content.toString(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
      ],
    );
  }
}
