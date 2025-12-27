// File: lib/features/reports/presentation/screens/invoices_report_screen.dart
import 'package:ehab_company_admin/core/theme/app_theme.dart';
import 'package:ehab_company_admin/features/reports/data/models/invoice_report_model.dart';
import 'package:ehab_company_admin/features/reports/presentation/controllers/invoices_report_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;

class InvoicesReportScreen extends StatelessWidget {
  const InvoicesReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(InvoicesReportController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير الفواتير'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_off_outlined),
            tooltip: 'مسح الفلاتر',
            onPressed: controller.clearFilters,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.fetchReportData,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(125.0),
          child: _buildFilters(controller),
        ),
      ),
      // --- بداية التعديل: إضافة BottomNavigationBar ---
      bottomNavigationBar: Obx(
            () => BottomNavigationBar(
          currentIndex: controller.currentPageIndex.value,
          onTap: controller.changePage,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.storefront_outlined),
              label: 'المبيعات',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_outlined),
              label: 'المشتريات',
            ),
          ],
        ),
      ),
      // --- نهاية التعديل ---
      body: Obx(() {
        if (controller.isLoading.isTrue &&
            (controller.salesInvoices.isEmpty &&
                controller.purchaseInvoices.isEmpty)) {
          return const Center(child: CircularProgressIndicator());
        }

        // --- بداية التعديل: استخدام PageView ---
        return PageView(
          controller: controller.pageController,
          onPageChanged: controller.changePage,
          children: [
            // الصفحة الأولى: المبيعات
            _InvoiceListPage(
              invoices: controller.salesInvoices,
              summaryCard: _buildMiniCard(
                'مبيعات',
                controller.totalSales.value,
                '${controller.salesCount.value} فاتورة',
                Icons.storefront_outlined,
                AppTheme.primaryColor,
              ),
            ),
            // الصفحة الثانية: المشتريات
            _InvoiceListPage(
              invoices: controller.purchaseInvoices,
              summaryCard: _buildMiniCard(
                'مشتريات',
                controller.totalPurchases.value,
                '${controller.purchasesCount.value} فاتورة',
                Icons.shopping_cart_outlined,
                Colors.orange.shade800,
              ),
            ),
          ],
        );
        // --- نهاية التعديل ---
      }),
    );
  }

  // --- بداية الإضافة: ودجت مستقل لعرض كل صفحة ---
  Widget _InvoiceListPage(
      {required RxList<InvoiceReportModel> invoices,
        required Widget summaryCard}) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: summaryCard,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'الفواتير (${invoices.length})',
              style:
              const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        invoices.isEmpty
            ? const SliverFillRemaining(
          child: Center(
            child: Text(
              'لا توجد فواتير تطابق بحثك.',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ),
        )
            : SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) {
              final invoice = invoices[index];
              return _buildInvoiceCard(invoice);
            },
            childCount: invoices.length,
          ),
        ),
      ],
    );
  }
  // --- نهاية الإضافة ---

  // ودجت بناء بطاقات الملخص (لا تغيير)
  Widget _buildMiniCard(String title, double value, String subtitle,
      IconData icon, Color color) {
    final formatCurrency =
    intl.NumberFormat.currency(locale: 'ar_SA', symbol: 'ريال');
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color)),
                Icon(icon, color: color, size: 28),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              formatCurrency.format(value),
              style:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // ودجت بناء الفلاتر
  Widget _buildFilters(InvoicesReportController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
      child: Column(
        children: [
          // الصف الأول: فلاتر التاريخ (لا تغيير)
          Row(
            children: [
              Expanded(
                child: _buildDateField(controller, isFromDate: true),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDateField(controller, isFromDate: false),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // الصف الثاني: فلتر حالة الدفع (فلتر النوع لم يعد مطلوبًا هنا)
          Obx(() => SegmentedButton<PaymentStatusFilter>(
            style: SegmentedButton.styleFrom(
              textStyle: const TextStyle(fontSize: 12),
            ),
            segments: const [
              ButtonSegment(
                  value: PaymentStatusFilter.all, label: Text('الكل')),
              ButtonSegment(
                  value: PaymentStatusFilter.paid, label: Text('مدفوع')),
              ButtonSegment(
                  value: PaymentStatusFilter.due, label: Text('آجل')),
            ],
            selected: {controller.paymentStatusFilter.value},
            onSelectionChanged: (newSelection) {
              controller.paymentStatusFilter.value = newSelection.first;
            },
          )),
        ],
      ),
    );
  }

  // ودجت بناء حقل التاريخ (لا تغيير)
  Widget _buildDateField(InvoicesReportController controller,
      {required bool isFromDate}) {
    return Obx(() {
      final date =
      isFromDate ? controller.fromDate.value : controller.toDate.value;
      return TextFormField(
        readOnly: true,
        controller: TextEditingController(
          text: date == null
              ? ''
              : intl.DateFormat('yyyy-MM-dd', 'ar').format(date),
        ),
        onTap: () =>
            controller.selectDate(Get.context!, isFromDate: isFromDate),
        decoration: InputDecoration(
          hintText: isFromDate ? 'من تاريخ' : 'إلى تاريخ',
          prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      );
    });
  }

  // ودجت بناء بطاقة الفاتورة (لا تغيير)
  Widget _buildInvoiceCard(InvoiceReportModel invoice) {
    final isSale = invoice.invoiceType == 'SALE';
    final isDue = invoice.remainingAmount > 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isSale ? AppTheme.primaryColor : Colors.orange,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isSale ? 'فاتورة مبيعات' : 'فاتورة مشتريات',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSale
                          ? AppTheme.primaryColor
                          : Colors.orange.shade900),
                ),
                Text(
                  '#${invoice.id}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              ],
            ),
            const Divider(),
            Text(invoice.partyName,
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الإجمالي: ${intl.NumberFormat.decimalPattern('ar').format(invoice.totalAmount)} ريال',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDue
                        ? Colors.red.shade100
                        : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    isDue ? 'آجل' : 'مدفوع',
                    style: TextStyle(
                      color: isDue
                          ? Colors.red.shade900
                          : Colors.green.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'التاريخ: ${intl.DateFormat('yyyy-MM-dd').format(invoice.invoiceDate)}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
