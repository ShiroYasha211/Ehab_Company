// File: lib/features/sales/presentation/screens/sales_details_screen.dart

import 'package:ehab_company_admin/core/services/settings_service.dart';
import 'package:ehab_company_admin/features/sales/presentation/controllers/sales_details_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import '../../../../core/services/sales_invoice_pdf_service.dart'; // سيتم تفعيله لاحقًا

class SalesDetailsScreen extends StatelessWidget {
  final int invoiceId;
  const SalesDetailsScreen({super.key, required this.invoiceId});

  @override
  Widget build(BuildContext context) {
    return _buildScreen(context);
  }

  Widget _buildPriceWidget(double price, {Color? color}) {
    final settings = Get.find<SettingsService>();
    final primarySymbol = settings.primaryCurrency.value.symbol;
    final primaryPrice = '${price.toStringAsFixed(2)} $primarySymbol';

    if (settings.showBothCurrenciesInInvoice.value &&
        !settings.isLocalSameAsPrimary.value) {
      final localPrice = price * settings.exchangeRate.value;
      final localSymbol = settings.localCurrency.value.symbol;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            primaryPrice,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: color ?? Colors.black87,
            ),
          ),
          Text(
            '${localPrice.toStringAsFixed(2)} $localSymbol',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      );
    }
    return Text(
      primaryPrice,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: color ?? Colors.black87,
      ),
    );
  }

  Widget _buildScreen(BuildContext context) {
    final SalesDetailsController controller = Get.put(
      SalesDetailsController(invoiceId),
      tag: 'sales_${invoiceId.toString()}',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('تفاصيل فاتورة مبيعات #${invoiceId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            onPressed: () {
              if (controller.invoiceDetails.value != null) {
                SalesInvoicePdfService.printInvoice(
                  controller.invoiceDetails.value!,
                );
              } else {
                Get.snackbar('لا يمكن الطباعة', 'البيانات غير جاهزة بعد.');
              }
            },
          ),
          // --- نهاية التعديل ---

          // --- بداية الإضافة: زر إرجاع فاتورة المبيعات ---
          Obx(() {
            if (controller.isLoading.isTrue ||
                controller.invoiceDetails.value == null) {
              return const SizedBox.shrink();
            }
            final status =
                controller.invoiceDetails.value!['invoice']['status'];
            if (status == 'RETURNED') {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Chip(
                  label: Text('مرتجعة', style: TextStyle(color: Colors.white)),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return IconButton(
              icon: const Icon(Icons.undo_rounded),
              tooltip: 'إرجاع الفاتورة',
              onPressed: () => _showReturnInvoiceDialog(context, controller),
            );
          }),
        ],
      ),
      // --- بداية التعديل: إضافة bottomNavigationBar لتسجيل الدفعة ---
      bottomNavigationBar: Obx(() {
        if (controller.isLoading.isTrue ||
            controller.invoiceDetails.value == null) {
          return const SizedBox.shrink();
        }
        final invoiceData = controller.invoiceDetails.value!['invoice'];
        final double remainingAmount = invoiceData['remainingAmount'];
        final String status = invoiceData['status'];

        // إخفاء الزر إذا كانت الفاتورة مدفوعة أو مرتجعة
        if (remainingAmount <= 0 || status == 'RETURNED') {
          return const SizedBox.shrink();
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.payment_rounded),
              label: const Text('تسجيل دفعة (سند قبض)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: const TextStyle(fontSize: 18),
              ),
              onPressed: () =>
                  _showAddPaymentDialog(context, controller, remainingAmount),
            ),
          ),
        );
      }),
      // --- نهاية التعديل ---
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.isTrue) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.invoiceDetails.value == null) {
            return const Center(child: Text('لا توجد بيانات لهذه الفاتورة.'));
          }

          final invoiceData =
              controller.invoiceDetails.value!['invoice']
                  as Map<String, dynamic>;
          final itemsData =
              controller.invoiceDetails.value!['items'] as List<dynamic>;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeader(invoiceData),
              const Divider(height: 30),
              Text(
                'الأصناف المباعة (${itemsData.length})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              // --- بداية التعديل: استخدام Table بدلاً من DataTable ---
              _buildItemsTable(itemsData),
              // --- نهاية التعديل ---
              const Divider(height: 30),
              // عرض الملاحظات (التي قد تحتوي على تفاصيل الدفع بالعملة المحلية)
              if (invoiceData['notes'] != null &&
                  invoiceData['notes'].toString().isNotEmpty)
                _buildNotesSection(invoiceData['notes']),
              const SizedBox(height: 10),
              _buildFinancialSummary(invoiceData),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildNotesSection(String notes) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        border: Border.all(color: Colors.amber.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ملاحظات / تفاصيل الدفع:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 4),
          Text(notes, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  // ودجت الهيدر (مشابه لتصميم المشتريات)
  Widget _buildHeader(Map<String, dynamic> invoiceData) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
              'اسم العميل:',
              invoiceData['customerName'] ?? 'غير محدد',
              highlight: false,
            ),
            _buildInfoRow(
              'هاتف العميل:',
              invoiceData['customerPhone'] ?? 'غير محدد',
              highlight: false,
            ),
            _buildInfoRow(
              'تاريخ الفاتورة:',
              intl.DateFormat(
                'yyyy-MM-dd',
              ).format(DateTime.parse(invoiceData['invoiceDate'])),
              highlight: false,
            ),
            // لاحقًا سنضيف سبب المرتجع هنا
          ],
        ),
      ),
    );
  }

  // --- بداية التعديل: استخدام Table بتصميم احترافي ---
  Widget _buildItemsTable(List<dynamic> items) {
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300, width: 1),
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(1.5),
        2: FlexColumnWidth(1.5),
        3: FlexColumnWidth(2),
      },
      children: [
        // Table Header
        TableRow(
          decoration: BoxDecoration(
            color: Get.theme.primaryColor.withOpacity(0.8),
          ),
          children: const [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'الصنف',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'الكمية',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'السعر',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'الإجمالي',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        // Table Rows
        ...items.map(
          (item) => TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(item['productName']),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text((item['quantity'] as num).toStringAsFixed(0)),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildPriceWidget(item['salePrice']),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildPriceWidget(item['totalPrice']),
              ),
            ],
          ),
        ),
      ],
    );
  }
  // --- نهاية التعديل ---

  // --- بداية التعديل: استخدام نفس تصميم الملخص المالي ---
  Widget _buildFinancialSummary(Map<String, dynamic> invoiceData) {
    // ... (نفس الكود السابق للحالة)
    final String status = invoiceData['status'];
    final String statusText = status == 'RETURNED'
        ? 'مرتجعة'
        : (invoiceData['remainingAmount'] <= 0 ? 'مدفوعة بالكامل' : 'آجلة');
    final Color statusColor = status == 'RETURNED'
        ? Colors.red
        : (invoiceData['remainingAmount'] <= 0 ? Colors.green : Colors.orange);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // استخدام _buildInfoRowWithWidget للأسعار
            _buildInfoRowWithWidget(
              'الخصم:',
              _buildPriceWidget(invoiceData['discountAmount']),
            ),
            _buildInfoRowWithWidget(
              'الإجمالي:',
              _buildPriceWidget(invoiceData['totalAmount']),
            ),
            const Divider(),
            _buildInfoRowWithWidget(
              'المقبوض:',
              _buildPriceWidget(invoiceData['paidAmount'], color: Colors.green),
            ),
            _buildInfoRowWithWidget(
              'المتبقي:',
              _buildPriceWidget(
                invoiceData['remainingAmount'],
                color: Colors.red,
              ),
            ),
            const Divider(),
            _buildInfoRow(
              'حالة الفاتورة:',
              statusText,
              color: statusColor,
              highlight: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRowWithWidget(String label, Widget content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
          ),
          content,
        ],
      ),
    );
  }
  // --- نهاية التعديل ---

  Widget _buildInfoRow(
    String label,
    String value, {
    bool highlight = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: highlight ? 18 : 16,
              fontWeight: FontWeight.bold,
              color: color ?? Get.theme.textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }

  // --- بداية التعديل: ديالوج إضافة الدفعة ---
  void _showAddPaymentDialog(
    BuildContext context,
    SalesDetailsController controller,
    double remainingAmount,
  ) {
    final paymentController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text('تسجيل دفعة (سند قبض)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'المبلغ المتبقي: ${remainingAmount.toStringAsFixed(2)} ${Get.find<SettingsService>().primaryCurrency.value.symbol}',
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: paymentController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'أدخل مبلغ الدفعة',
                prefixIcon: Icon(Icons.money),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          Obx(() {
            if (controller.isAddingPayment.isTrue) {
              return const CircularProgressIndicator();
            }
            return ElevatedButton(
              onPressed: () {
                final double amount =
                    double.tryParse(paymentController.text) ?? 0.0;
                controller.addPayment(amount);
              },
              child: const Text('تأكيد الدفعة'),
            );
          }),
        ],
      ),
    );
  }

  // --- بداية الإضافة: ديالوج تأكيد إرجاع فاتورة المبيعات ---
  void _showReturnInvoiceDialog(
    BuildContext context,
    SalesDetailsController controller,
  ) {
    final reasonController = TextEditingController();
    final returnPayment = true.obs;

    Get.dialog(
      AlertDialog(
        title: const Text('تأكيد إرجاع الفاتورة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'هل أنت متأكد من أنك تريد إرجاع هذه الفاتورة بالكامل؟ سيتم عكس كل العمليات المحاسبية.',
              style: TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'سبب الإرجاع (اختياري)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Obx(
              () => SwitchListTile(
                title: const Text('إرجاع المبلغ نقداً'),
                subtitle: const Text('سيتم خصم المبلغ المقبوض من الصندوق'),
                value: returnPayment.value,
                onChanged: (value) => returnPayment.value = value,
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          Obx(() {
            if (controller.isReturningInvoice.isTrue) {
              return const CircularProgressIndicator();
            }
            return ElevatedButton(
              onPressed: () {
                controller.returnInvoice(
                  reason: reasonController.text,
                  returnPayment: returnPayment.value,
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('تأكيد الإرجاع'),
            );
          }),
        ],
      ),
    );
  }
  // --- نهاية الإضافة ---

  // --- نهاية التعديل ---
}
