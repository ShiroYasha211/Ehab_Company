// File: lib/features/sales/presentation/screens/add_sales_invoice_screen.dart

import 'package:ehab_company_admin/features/customers/data/models/customer_model.dart'; // <-- 1.
import 'package:ehab_company_admin/features/sales/presentation/controllers/add_sales_invoice_controller.dart'; // <-- 1.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../products/data/models/product_model.dart';

class AddSalesInvoiceScreen extends StatelessWidget {
  const AddSalesInvoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AddSalesInvoiceController controller = Get.find<AddSalesInvoiceController>(); // <-- 2.

    return Scaffold(
      appBar: AppBar(
        title: const Text('فاتورة مبيعات جديدة'),
      ),
      bottomNavigationBar: _buildNewFooter(context, controller),
      body: Column(
        children: [
          _buildHeader(context, controller),
          Expanded(
            child: Obx(
                  () => controller.invoiceItems.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_shopping_cart_rounded, size: 80, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text('الفاتورة فارغة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('قم بإضافة أصناف لبدء فاتورة المبيعات', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: controller.invoiceItems.length,
                itemBuilder: (context, index) {
                  final item = controller.invoiceItems[index];
                  return _buildItemCard(context, controller, item);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AddSalesInvoiceController controller) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Obx(() => DropdownButtonFormField<CustomerModel>( // <-- 3.
                  value: controller.selectedCustomer.value,
                  items: controller.customerController.filteredCustomers.map((customer) {
                    return DropdownMenuItem<CustomerModel>(
                      value: customer,
                      child: Text(customer.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    controller.selectedCustomer.value = value;
                  },
                  decoration: const InputDecoration(
                    labelText: 'اختر العميل *',
                    prefixIcon: Icon(Icons.person_search_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null ? 'الرجاء اختيار عميل' : null,
                )),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.person_add_alt_1),
                tooltip: 'إضافة عميل جديد',
                onPressed: () {
                  // TODO: Get.to(() => const AddEditCustomerScreen());
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: controller.dateController,
            readOnly: true,
            onTap: () => controller.selectInvoiceDate(context),
            decoration: const InputDecoration(
              labelText: 'تاريخ الفاتورة',
              prefixIcon: Icon(Icons.calendar_today_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _showSearchDialog(context, controller),
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('إضافة صنف إلى الفاتورة'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, AddSalesInvoiceController controller, SalesInvoiceItem item) { // <-- 4.
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          'الكمية: ${item.quantity.toStringAsFixed(0)} × ${item.salePrice.toStringAsFixed(2)}  =  ${item.subtotal.toStringAsFixed(2)} ريال',
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: Colors.red.shade700),
          onPressed: () => controller.removeProductFromInvoice(item.product.id!),
        ),
        onTap: () => _showEditItemDialog(context, controller, item),
      ),
    );
  }

  void _showSearchDialog(BuildContext context, AddSalesInvoiceController mainController) { // <-- 5.
    Get.dialog(
      AlertDialog(
        title: const Text('البحث عن منتج'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'ابحث بالاسم أو الباركود...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.qr_code_scanner),
                      onPressed: () async {
                        Get.back();
                        final code = await Get.dialog<String>(
                          Scaffold(
                            appBar: AppBar(title: const Text('امسح الباركود')),
                            body: MobileScanner(
                              onDetect: (capture) {
                                final String? detectedCode = capture.barcodes.first.rawValue;
                                if (detectedCode != null) {
                                  Get.back(result: detectedCode);
                                }
                              },
                            ),
                          ),
                        );
                        if (code != null) {
                          mainController.productController.searchQuery.value = code;
                          _showSearchDialog(context, mainController);
                        }
                      },
                    ),
                  ),
                  onChanged: (value) => mainController.productController.searchQuery.value = value,
                ),
              ),
              const Divider(),
              Expanded(
                child: Obx(() {
                  final products = mainController.productController.filteredProducts;
                  final query = mainController.productController.searchQuery.value;

                  if (mainController.productController.isLoading.isTrue) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (products.isEmpty && query.isEmpty) {
                    return const Center(child: Text('تصفح المنتجات أو ابدأ البحث...'));
                  }

                  return ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final bool isAvailable = product.quantity > 0;
                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          enabled: isAvailable, // تعطيل العنصر إذا كانت الكمية صفر
                          leading: CircleAvatar(
                            backgroundColor: isAvailable ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.grey.shade200,
                            foregroundColor: isAvailable ? Theme.of(context).primaryColor : Colors.grey,
                            child: Text(product.quantity.toInt().toString()),
                          ),
                          title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text('سعر البيع: ${product.salePrice} ريال'), // <-- 6.
                          onTap: () {
                            _showQuantityDialog(context, mainController, product); // <-- 7.
                          },
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إغلاق')),
        ],
      ),
      barrierDismissible: false,
    ).whenComplete(() => mainController.clearProductSearch());
  }

  void _showQuantityDialog(BuildContext context, AddSalesInvoiceController controller, ProductModel product) { // <-- 7.
    final qtyController = TextEditingController(text: '1');
    Get.dialog(
      AlertDialog(
        title: Text(product.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('الكمية المتوفرة: ${product.quantity.toInt()}'),
            const SizedBox(height: 16),
            TextField(
              controller: qtyController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: false),
              decoration: const InputDecoration(labelText: 'أدخل الكمية المطلوبة'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              final qty = double.tryParse(qtyController.text) ?? 0;
              controller.addProductToInvoice(product, qty);
              // Get.back() is called inside addProductToInvoice
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _showEditItemDialog(BuildContext context, AddSalesInvoiceController controller, SalesInvoiceItem item) { // <-- 8.
    final qtyController = TextEditingController(text: item.quantity.toStringAsFixed(0));
    final salePriceController = TextEditingController(text: item.salePrice.toString());

    Get.dialog(
      AlertDialog(
        title: Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogInfoRow('الكمية المتوفرة:', '${item.product.quantity} ${item.product.unit ?? ''}'),
              _buildDialogEditableRow('الكمية في الفاتورة:', qtyController),
              const Divider(),
              _buildDialogEditableRow('سعر البيع:', salePriceController),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              final newQty = double.tryParse(qtyController.text) ?? item.quantity;
              final newSalePrice = double.tryParse(salePriceController.text) ?? item.salePrice;
              controller.updateItemQuantity(item.product.id!, newQty);
              controller.updateItemPrice(item.product.id!, newSalePrice);
              Get.back();
            },
            child: const Text('حفظ التعديلات'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDialogEditableRow(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textDirection: TextDirection.ltr,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildNewFooter(BuildContext context, AddSalesInvoiceController controller) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).canvasColor,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, -2))],
        ),
        child: Row(
          children: [
            Expanded(
              child: Obx(() => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الإجمالي: ${controller.grandTotal.toStringAsFixed(2)} ريال', // <-- 9.
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Get.theme.primaryColor),
                  ),
                  Text(
                    'عدد الأصناف: ${controller.invoiceItems.length} | إجمالي الكمية: ${controller.totalItemsCount}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              )),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 150,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (controller.invoiceItems.isEmpty) {
                    Get.snackbar('خطأ', 'لا يمكن المتابعة، الفاتورة فارغة.');
                    return;
                  }
                  if (controller.selectedCustomer.value == null) {
                    Get.snackbar('خطأ', 'الرجاء اختيار عميل أولاً.');
                    return;
                  }
                  _showPaymentDialog(context, controller);
                },
                icon: const Icon(Icons.payment_rounded),
                label: const Text('مراجعة وحفظ'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, AddSalesInvoiceController controller) { // <-- 10.
    controller.preparePaymentDialog();

    Get.dialog(
      AlertDialog(
        title: const Text('مراجعة الدفع والحفظ'),
        content: Obx(() => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: controller.paidAmount.value == 0
                    ? 'آجل'
                    : controller.paidAmount.value >= controller.grandTotal // >= to handle rounding issues
                    ? 'نقداً'
                    : 'مختلط',
                items: const [
                  DropdownMenuItem(value: 'نقداً', child: Text('نقداً')),
                  DropdownMenuItem(value: 'آجل', child: Text('آجل')),
                  DropdownMenuItem(value: 'مختلط', child: Text('نقداً وآجل')),
                ],
                onChanged: (value) {
                  if (value == 'نقداً') {
                    controller.paidAmountController.text = controller.grandTotal.toStringAsFixed(2);
                  } else if (value == 'آجل') {
                    controller.paidAmountController.text = '0.0';
                  }
                },
                decoration: const InputDecoration(labelText: 'طريقة الدفع', border: OutlineInputBorder()),
              ),
              const Divider(height: 20),
              _buildDialogInfoRow('الإجمالي الفرعي:', '${controller.subtotal.toStringAsFixed(2)} ريال'),
              _buildDialogEditableRow('الخصم (مبلغ)', controller.discountController),
              // الضريبة غير ضرورية في فاتورة البيع عادةً
              const SizedBox(height: 10),
              _buildDialogInfoRow('الإجمالي النهائي:', '${controller.grandTotal.toStringAsFixed(2)} ريال'),
              const Divider(height: 20),
              _buildDialogEditableRow('المبلغ المقبوض:', controller.paidAmountController),
              const SizedBox(height: 10),
              _buildDialogInfoRow('المبلغ المتبقي:', '${controller.remainingAmount.toStringAsFixed(2)} ريال'),
            ],
          ),
        )),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          Obx(() {
            if (controller.isSaving.isTrue) {
              return const CircularProgressIndicator();
            }
            return ElevatedButton(
              onPressed: () => controller.saveSalesInvoice(),
              style: ElevatedButton.styleFrom(backgroundColor: Get.theme.primaryColor, foregroundColor: Colors.white),
              child: const Text('تأكيد وحفظ الفاتورة'),
            );
          }),
        ],
      ),
    );
  }
}
