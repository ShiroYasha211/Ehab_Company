// File: lib/features/purchases/presentation/screens/purchase_details_screen.dart

import 'package:ehab_company_admin/features/purchases/presentation/controllers/purchase_details_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/services/purchase_invoice_pdf_service.dart';

class PurchaseDetailsScreen extends StatelessWidget {
  final int invoiceId;

  const PurchaseDetailsScreen({super.key, required this.invoiceId});

  @override
  Widget build(BuildContext context) {
    // استخدام tag لضمان إنشاء controller فريد لكل فاتورة
    final PurchaseDetailsController controller = Get.put(
      PurchaseDetailsController(invoiceId),
      tag: invoiceId.toString(),
    );
    final formatCurrency = intl.NumberFormat.currency(
        locale: 'ar_SA', symbol: ' ريال');

    return Scaffold(
      appBar: AppBar(
        title: Text('تفاصيل الفاتورة رقم #$invoiceId'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            onPressed: () {
              if (controller.invoiceDetails.value != null) {
                PurchaseInvoicePdfService.printInvoice(
                    controller.invoiceDetails.value!);
              }
            },
          ),
          Obx(() {
            if (controller.isLoading.isTrue ||
                controller.invoiceDetails.value == null) {
              return const SizedBox.shrink();
            }
            final status = controller.invoiceDetails
                .value!['invoice']['status'];
            if (status == 'RETURNED') {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Chip(
                  label: Text('مرتجعة', style: TextStyle(color: Colors.white)),
                  backgroundColor: Colors.red,
                ),
              );
            }
            // إذا لم تكن مرتجعة، أظهر زر الإرجاع

            return IconButton(
              icon: const Icon(Icons.undo_rounded),
              tooltip: 'إرجاع الفاتورة',
              onPressed: () => _showReturnInvoiceDialog(context, controller),
            );
          }),
        ],
      ),
      bottomNavigationBar: Obx(() {
        if (controller.isLoading.isTrue ||
            controller.invoiceDetails.value == null) {
          return const SizedBox.shrink();
        }
        final invoiceData = controller.invoiceDetails.value!['invoice'];
        final double remainingAmount = invoiceData['remainingAmount'];
        final String status = invoiceData['status'];

        if (remainingAmount <= 0 || status == 'RETURNED') {
          return const SizedBox.shrink();
        }

        if (remainingAmount <= 0) {
          return const SizedBox.shrink(); // إخفاء الزر إذا كانت الفاتورة مدفوعة
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.payment_rounded),
              label: const Text('تسجيل دفعة جديدة'),
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

      body: Obx(() {
        if (controller.isLoading.isTrue) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.invoiceDetails.value == null) {
          return const Center(child: Text('لا توجد بيانات لهذه الفاتورة.'));
        }

        final invoiceData = controller.invoiceDetails.value!['invoice'] as Map<
            String,
            dynamic>;
        final itemsData = controller.invoiceDetails.value!['items'] as List<
            dynamic>;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. رأس الفاتورة
            _buildHeader(invoiceData),
            const Divider(height: 30),
            // 2. قائمة الأصناف
            Text('الأصناف (${itemsData.length})', style: Theme
                .of(context)
                .textTheme
                .titleLarge),
            const SizedBox(height: 10),
            _buildItemsTable(itemsData, formatCurrency),
            const Divider(height: 30),
            // 3. الملخص المالي
            _buildFinancialSummary(invoiceData, formatCurrency),
          ],
        );
      }),
    );
  }

  Widget _buildHeader(Map<String, dynamic> invoiceData) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
                'اسم المورد:', invoiceData['supplierName'] ?? 'غير محدد'),
            _buildInfoRow(
                'هاتف المورد:', invoiceData['supplierPhone'] ?? 'غير محدد'),
            _buildInfoRow('تاريخ الفاتورة:',
                intl.DateFormat('yyyy-MM-dd').format(
                    DateTime.parse(invoiceData['invoiceDate']))),
            if (invoiceData['invoiceNumber'] != null &&
                invoiceData['invoiceNumber'].isNotEmpty)
              _buildInfoRow('رقم فاتورة المورد:', invoiceData['invoiceNumber']),
            if (invoiceData['status'] == 'RETURNED')
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: _buildInfoRow(
                  "سبب الإرجاع:", // إضافة نقطتين للتنسيق
                  // التحقق مما إذا كان السبب فارغًا أو null
                  (invoiceData['reason'] == null || (invoiceData['reason'] as String).isEmpty)
                      ? 'لم يتم تحديد سبب'
                      : invoiceData['reason'],
                  color: Colors.red.shade700,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsTable(List<dynamic> items,
      intl.NumberFormat formatCurrency) {
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
        const TableRow(
          decoration: BoxDecoration(color: Colors.blueGrey),
          children: [
            Padding(padding: EdgeInsets.all(8.0),
                child: Text('الصنف', style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold))),
            Padding(padding: EdgeInsets.all(8.0),
                child: Text('الكمية', style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold))),
            Padding(padding: EdgeInsets.all(8.0),
                child: Text('السعر', style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold))),
            Padding(padding: EdgeInsets.all(8.0),
                child: Text('الإجمالي', style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold))),
          ],
        ),
        // Table Rows
        ...items.map((item) =>
            TableRow(
              children: [
                Padding(padding: const EdgeInsets.all(8.0),
                    child: Text(item['productName'])),
                Padding(padding: const EdgeInsets.all(8.0),
                    child: Text(item['quantity'].toString())),
                Padding(padding: const EdgeInsets.all(8.0),
                    child: Text(formatCurrency.format(item['purchasePrice']))),
                Padding(padding: const EdgeInsets.all(8.0),
                    child: Text(formatCurrency.format(item['totalPrice']))),
              ],
            )),
      ],
    );
  }

  Widget _buildFinancialSummary(Map<String, dynamic> invoiceData,
      intl.NumberFormat formatCurrency) {
    final String status = invoiceData['status'];
    final String statusText = status == 'RETURNED'
        ? 'مرتجعة'
        : (invoiceData['remainingAmount'] <= 0 ? 'مدفوعة بالكامل' : 'آجلة');
    final Color statusColor = status== 'RETURNED'
        ? Colors.red
        : (invoiceData['remainingAmount'] <= 0 ? Colors.green : Colors.orange);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoRow(
                'الخصم:', formatCurrency.format(invoiceData['discountAmount']),
                highlight: true),
            _buildInfoRow(
                'الإجمالي:', formatCurrency.format(invoiceData['totalAmount']),
                highlight: true),
            const Divider(),
            _buildInfoRow(
                'المدفوع:', formatCurrency.format(invoiceData['paidAmount']),
                color: Colors.green),
            _buildInfoRow('المتبقي:',
                formatCurrency.format(invoiceData['remainingAmount']),
                color: Colors.red),
            const Divider(),
            _buildInfoRow('حالة الفاتورة:', statusText, color: statusColor, highlight: true),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value,
      {bool highlight = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
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

  void _showAddPaymentDialog(BuildContext context,
      PurchaseDetailsController controller,
      double remainingAmount,) {
    final paymentController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text('تسجيل دفعة جديدة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('المبلغ المتبقي: ${remainingAmount.toStringAsFixed(2)} ريال',
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: paymentController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true),
              decoration: const InputDecoration(
                labelText: 'أدخل مبلغ الدفعة', prefixIcon: Icon(Icons.money),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),),
          Obx(() {
            if (controller.isAddingPayment.isTrue) {
              return const CircularProgressIndicator();
            }
            return ElevatedButton(
              onPressed: () {
                final double amount = double.tryParse(paymentController.text) ??
                    0.0;
                controller.addPayment(amount);
              },
              child: const Text('تأكيد الدفعة'),
            );
          }),
        ],
      ),
    );
  }

  // --- بداية الإضافة: بناء ديالوج تأكيد الإرجاع ---
  void _showReturnInvoiceDialog(BuildContext context,
      PurchaseDetailsController controller) {
    final reasonController = TextEditingController();
    final receivePayment = true.obs; // متغير لتتبع خيار استلام المبلغ

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
            Obx(() =>
                SwitchListTile(title: const Text('استلام المبلغ نقداً'),
                  subtitle: const Text('سيتم توريد قيمة المرتجع إلى الصندوق'),
                  value: receivePayment.value,
                  onChanged: (value) => receivePayment.value = value,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          Obx(() {
            if (controller.isReturningInvoice.isTrue) {
              return const CircularProgressIndicator();
            }
            return ElevatedButton(
              onPressed: () {
                controller.returnInvoice(
                  reason: reasonController.text,
                  receivePayment: receivePayment.value,
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
}