// File: lib/features/sales/presentation/screens/sales_details_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import '../../../../core/services/settings_service.dart';
import '../../../../core/services/sales_invoice_pdf_service.dart';
import '../controllers/sales_details_controller.dart';

class SalesDetailsScreen extends StatelessWidget {
  final int invoiceId;
  const SalesDetailsScreen({super.key, required this.invoiceId});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: _buildScreen(context),
    );
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
      tag: invoiceId.toString(),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('تفاصيل فاتورة مبيعات #$invoiceId'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            onPressed: () {
              if (controller.invoiceDetails.value != null) {
                SalesInvoicePdfService.printInvoice(
                  controller.invoiceDetails.value!,
                );
              }
            },
          ),
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
      bottomNavigationBar: Obx(() {
        if (controller.isLoading.isTrue ||
            controller.invoiceDetails.value == null) {
          return const SizedBox.shrink();
        }
        final invoiceData = controller.invoiceDetails.value!['invoice'];
        final double remainingAmount = (invoiceData['remainingAmount'] as num? ?? 0.0).toDouble();
        final String status = invoiceData['status'] ?? 'PENDING';

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
      body: Obx(() {
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
              _buildItemsList(itemsData),
              const Divider(height: 30),

              // تفاصيل الملاحظات إذا وجدت
              if (invoiceData['notes'] != null &&
                  invoiceData['notes'].toString().isNotEmpty)
                _buildNotesSection(invoiceData['notes']),

              const SizedBox(height: 10),

              // سجل المدفوعات
              if (controller.invoiceDetails.value!['payments'] != null && 
                 (controller.invoiceDetails.value!['payments'] as List).isNotEmpty)
                _buildPaymentsBreakdown(context, controller.invoiceDetails.value!['payments']),

              const SizedBox(height: 10),
              _buildFinancialSummary(invoiceData),

              // توثيق العملية (Issued By)
              if (invoiceData['issuedBy'] != null)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.shade100),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.verified_user_outlined, size: 20, color: Colors.amber.shade700),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'توثيق المبيعات',
                              style: TextStyle(fontSize: 10, color: Colors.amber.shade800, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                            ),
                            Text(
                              'صادرة بواسطة: ${invoiceData['issuedBy']}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        }),
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
            'ملاحظات الفاتورة:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.amber,
            ),
          ),
          const SizedBox(height: 4),
          Text(notes, style: const TextStyle(fontSize: 14)),
        ],
      ),
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
            if (invoiceData['status'] == 'RETURNED')
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: _buildInfoRow(
                  "سبب الإرجاع:",
                  (invoiceData['reason'] == null || (invoiceData['reason'] as String).isEmpty)
                      ? 'لم يتم تحديد سبب'
                      : invoiceData['reason'],
                  color: Colors.red.shade700,
                  highlight: true,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList(List<dynamic> items) {
    return Column(
      children: items.map((item) => _buildItemDetailCard(item)).toList(),
    );
  }

  Widget _buildItemDetailCard(Map<String, dynamic> item) {
    final double freeQty = (item['freeQuantity'] as num? ?? 0.0).toDouble();
    final double quantity = (item['quantity'] as num? ?? 0.0).toDouble();
    final double salesPrice = (item['salesPrice'] as num? ?? 0.0).toDouble();
    final double totalPrice = (item['totalPrice'] as num? ?? 0.0).toDouble();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item['productName'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                ),
              ),
              if (item['unit'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item['unit'],
                    style: TextStyle(color: Colors.blue.shade700, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCompactInfo('الكمية', quantity.toStringAsFixed(0)),
                _buildCompactInfo('المجانية', freeQty.toStringAsFixed(0),
                    color: freeQty > 0 ? Colors.orange.shade800 : null),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('السعر',
                        style: TextStyle(fontSize: 10, color: Colors.grey)),
                    _buildPriceWidget(salesPrice),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('الإجمالي',
                        style: TextStyle(fontSize: 10, color: Colors.grey)),
                    _buildPriceWidget(totalPrice,
                        color: Get.theme.primaryColor),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactInfo(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13, 
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialSummary(Map<String, dynamic> invoiceData) {
    final String status = invoiceData['status'];
    final String statusText = status == 'RETURNED'
        ? 'مرتجعة'
        : (invoiceData['remainingAmount'] <= 0 ? 'مدفوعة بالكامل' : 'آجلة');
    final Color statusColor = status == 'RETURNED'
        ? Colors.red
        : (invoiceData['remainingAmount'] <= 0 ? Colors.green : Colors.orange);

    final double discountAmount =
        (invoiceData['discountAmount'] as num? ?? 0.0).toDouble();
    final double totalAmount =
        (invoiceData['totalAmount'] as num? ?? 0.0).toDouble();
    final double paidAmount =
        (invoiceData['paidAmount'] as num? ?? 0.0).toDouble();
    final double remainingAmount =
        (invoiceData['remainingAmount'] as num? ?? 0.0).toDouble();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoRowWithWidget(
              'الخصم:',
              _buildPriceWidget(discountAmount),
            ),
            _buildInfoRowWithWidget(
              'الإجمالي:',
              _buildPriceWidget(totalAmount),
            ),
            const Divider(),
            _buildInfoRowWithWidget(
              'المدفوع:',
              _buildPriceWidget(paidAmount, color: Colors.green),
            ),
            _buildInfoRowWithWidget(
              'المتبقي:',
              _buildPriceWidget(
                remainingAmount,
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

  Widget _buildPaymentsBreakdown(BuildContext context, List<dynamic> payments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'سجل المدفوعات من العميل',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...payments.map((p) {
          final String method = p['method'];
          String methodLabel = 'نقد';
          IconData methodIcon = Icons.money;
          Color methodColor = Colors.green;

          if (method == 'transfer') {
            methodLabel = 'حوالة';
            methodIcon = Icons.swap_horiz_rounded;
            methodColor = Colors.blue;
          } else if (method == 'bank') {
            methodLabel = 'بنك';
            methodIcon = Icons.account_balance_rounded;
            methodColor = Colors.indigo;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(methodIcon, color: methodColor, size: 18),
                        const SizedBox(width: 8),
                        Text(methodLabel, style: TextStyle(fontWeight: FontWeight.bold, color: methodColor)),
                        if (p['fundName'] != null)
                           Text('  🔗 ${p['fundIcon'] ?? ''} ${p['fundName']}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    _buildPriceWidget((p['amount'] as num? ?? 0.0).toDouble()),
                  ],
                ),
                if (method == 'transfer' || method == 'bank') ...[
                  const Divider(height: 16),
                  if (p['transferNumber'] != null || p['bankReference'] != null)
                     _buildDetailRow(Icons.tag, 'المرجع:', p['transferNumber'] ?? p['bankReference']),
                  if (p['senderName'] != null)
                     _buildDetailRow(Icons.person_outline, 'المرسل:', p['senderName']),
                  if (p['bankName'] != null || p['transferCompany'] != null)
                     _buildDetailRow(Icons.business_outlined, 'الجهة:', p['bankName'] ?? p['transferCompany']),
                  
                  // عرض صورة السند إذا وجدت
                  if (p['attachmentPath'] != null && p['attachmentPath'].toString().isNotEmpty)
                    _buildReceiptImage(p['attachmentPath']),
                ],
                if (p['notes'] != null && p['notes'].toString().isNotEmpty) ...[
                   const SizedBox(height: 8),
                   Container(
                     padding: const EdgeInsets.all(8),
                     width: double.infinity,
                     decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                     child: Text('📝 ملاحظة: ${p['notes']}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                   ),
                ],
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(width: 4),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildReceiptImage(String path) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('صورة السند:', style: TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => Get.to(() => Scaffold(appBar: AppBar(title: const Text('معاينة السند')), body: Center(child: InteractiveViewer(child: Image.file(File(path)))))),
            child: Container(
              height: 120, width: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8), 
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(path), fit: BoxFit.cover)),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddPaymentDialog(
    BuildContext context,
    SalesDetailsController controller,
    double remainingAmount,
  ) {
    final paymentController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text('تسجيل دفعة من العميل'),
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

  void _showReturnInvoiceDialog(
    BuildContext context,
    SalesDetailsController controller,
  ) {
    final reasonController = TextEditingController();
    final payBack = true.obs;

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
                subtitle: const Text('سيتم صرف قيمة المرتجع من الصندوق'),
                value: payBack.value,
                onChanged: (value) => payBack.value = value,
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
                  returnPayment: payBack.value,
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
}
