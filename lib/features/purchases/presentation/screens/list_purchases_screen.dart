// File: lib/features/purchases/presentation/screens/list_purchases_screen.dart

import 'package:ehab_company_admin/features/purchases/data/models/purchase_invoice_summary_model.dart';
import 'package:ehab_company_admin/features/purchases/presentation/controllers/list_purchases_controller.dart';
import 'package:ehab_company_admin/features/purchases/presentation/screens/purchase_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;

import '../../../suppliers/data/models/supplier_model.dart';

class ListPurchasesScreen extends StatelessWidget {
  const ListPurchasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ListPurchasesController controller = Get.put(ListPurchasesController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('أرشيف فواتير الشراء'),
        actions: [
          // --- بداية التعديل: تغيير الأيقونة ---
          IconButton(icon: const Icon(Icons.filter_alt_off_outlined),
            tooltip: 'مسح الفلاتر',
            onPressed: controller.clearFilters,
          ),
          // --- نهاية التعديل ---
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(130.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  children: [
                    // --- بداية التعديل: ربط TextField بـ searchQuery ---
                    Expanded(child: TextField(
                      controller: controller.searchController,
                      keyboardType: TextInputType.number,
                      onChanged: (value) => controller.searchQuery.value = value,
                      decoration: InputDecoration(
                        hintText: 'بحث برقم الفاتورة...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        isDense: true,
                      ),
                    ),
                    ),
                    // --- نهاية التعديل ---
                    const SizedBox(width: 8),
                    Expanded(
                      child: Obx(() {
                        // --- بداية التعديل: استخدام filteredSuppliers ---
                        return DropdownButtonFormField<SupplierModel?>(
                          value: controller.selectedSupplier.value,
                          items: [
                            const DropdownMenuItem<SupplierModel?>(
                              value: null,
                              child: Text('كل الموردين'),
                            ),
                            ...controller.supplierController.filteredSuppliers.map((supplier) {
                              return DropdownMenuItem<SupplierModel?>(
                                value: supplier,
                                child: Text(supplier.name),
                              );
                            }).toList(),
                          ],
                          onChanged:(value) {
                            controller.selectedSupplier.value = value;
                          },
                          decoration: InputDecoration(
                            hintText: 'اختر موردًا',
                            prefixIcon: const Icon(Icons.person_outline),
                            border:OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            isDense: true,
                          ),
                        );
                        // --- نهاية التعديل ---
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Obx(() => SegmentedButton<InvoiceFilterStatus>(

                    segments: const [
                      ButtonSegment(value: InvoiceFilterStatus.all, label: Text('الكل')),
                      ButtonSegment(value: InvoiceFilterStatus.due, label: Text('آجلة')),
                      ButtonSegment(value: InvoiceFilterStatus.paid, label: Text('مدفوعة')),
                      ButtonSegment(value: InvoiceFilterStatus.returned, label: Text('مرتجعة')),
                    ],
                    selected: {controller.selectedStatus.value},
                    onSelectionChanged: (newSelection) {
                      controller.selectedStatus.value = newSelection.first;
                    },
                    style: SegmentedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18),

                    ),
                  ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.isTrue) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.invoices.isEmpty) {
          // --- بداية التعديل: رسالة أكثر تعبيرًا ---
          return const Center(
            child: Text('لا توجد فواتير تطابق بحثك.', style: TextStyle(color: Colors.grey)),
          );
          // --- نهاية التعديل ---
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: controller.invoices.length,
          itemBuilder: (context, index) {
            final invoice = controller.invoices[index];
            return PurchaseInvoiceCard(invoice: invoice);
          },
        );
      }),
    );
  }
}

// ... (ودجت PurchaseInvoiceCard يبقى كما هو)
class PurchaseInvoiceCard extends StatelessWidget {
  final PurchaseInvoiceSummaryModel invoice;

  const PurchaseInvoiceCard({super.key, required this.invoice});

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
    final formatCurrency = intl.NumberFormat.currency(locale: 'ar_SA', symbol: ' ريال');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: statusColor.withOpacity(0.6), width: 1.5),
      ),
      child: InkWell(
        onTap: () {
          Get.to(() => PurchaseDetailsScreen(invoiceId: invoice.id));
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                invoice.supplierName ?? 'مورد غير محدد',
                style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500),
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoChip(Icons.calendar_today_outlined, intl.DateFormat('yyyy-MM-dd').format(invoice.invoiceDate)),
                  _buildInfoChip(Icons.attach_money_outlined, formatCurrency.format(invoice.totalAmount), isPrimary: true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, {bool isPrimary = false}) {
    final color = isPrimary ? Get.theme.primaryColor : Colors.grey.shade600;
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
