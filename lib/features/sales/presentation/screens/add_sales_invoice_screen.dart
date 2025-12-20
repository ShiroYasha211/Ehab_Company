// File: lib/features/sales/presentation/screens/add_sales_invoice_screen.dart

import 'package:ehab_company_admin/features/customers/data/models/customer_model.dart'; // <-- 1.
import 'package:ehab_company_admin/features/sales/presentation/controllers/add_sales_invoice_controller.dart'; // <-- 1.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart'; // <-- 1. إضافة import جديد

import '../../../customers/presentation/screens/add_edit_customer_screen.dart';
import '../../../products/data/models/product_model.dart';

class AddSalesInvoiceScreen extends StatelessWidget {
  const AddSalesInvoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AddSalesInvoiceController controller = Get.find<
        AddSalesInvoiceController>(); // <-- 2.

    return Scaffold(
      appBar: AppBar(
        title: const Text('فاتورة مبيعات جديدة'),
      ),
      bottomNavigationBar: _buildNewFooter(context, controller),
      body: Column(
        children: [
          _buildMagicSearchBar(controller),

          _buildHeader(context, controller),
          const Divider(height: 1),
          Expanded(
            child: Obx(
                  () =>
              controller.invoiceItems.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_shopping_cart_rounded, size: 80,
                        color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text('الفاتورة فارغة', style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('استخدم شريط البحث أعلاه لإضافة الأصناف',
                        style: TextStyle(color: Colors.grey)),
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

  Widget _buildHeader(BuildContext context,
      AddSalesInvoiceController controller) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Obx(() =>
                    DropdownButtonFormField<CustomerModel>( // <-- 3.
                      value: controller.selectedCustomer.value,
                      items: controller.customerController.filteredCustomers
                          .map((customer) {
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
                        isDense: true,
                      ),
                      validator: (value) =>
                      value == null
                          ? 'الرجاء اختيار عميل'
                          : null,
                    )),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.person_add_alt_1),
                tooltip: 'إضافة عميل جديد',
                onPressed: () {
                  Get.to(() => const AddEditCustomerScreen());
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
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMagicSearchBar(AddSalesInvoiceController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: TypeAheadField<ProductModel>(
        suggestionsCallback: (pattern) async {
          if (pattern.isEmpty) {
            return [];
          }
          return controller.productController.allProducts.where((product) {
            final nameMatches = product.name.toLowerCase().contains(
                pattern.toLowerCase());
            final codeMatches = product.code?.toLowerCase().contains(
                pattern.toLowerCase()) ?? false;
            return nameMatches || codeMatches;
          }).toList();
        },
        itemBuilder: (context, suggestion) {
          final bool isAvailable = suggestion.quantity > 0;
          return ListTile(
            enabled: isAvailable,
            leading: Text(
              suggestion.quantity.toInt().toString(),
              style: TextStyle(
                  fontSize: 16, color: isAvailable ? Colors.green : Colors.red),
            ),
            title: Text(suggestion.name),
            trailing: Text('${suggestion.salePrice.toStringAsFixed(2)} ريال'),
          );
        },
        onSelected: (suggestion) {
          controller.addProductToInvoice(suggestion, 1);
          controller.productSearchController.clear();
        },
        builder: (context, textEditingController, focusNode) {
          // 2. ربط الـ Controller الخاص بنا بالـ TextField
          return TextField(
            controller: textEditingController,
            focusNode: focusNode,
            decoration: InputDecoration(
              hintText: 'ابحث بالاسم أو الباركود لإضافة صنف...',
              prefixIcon: const Icon(Icons.search),
              // 3. إضافة أيقونة ماسح الباركود
              suffixIcon: IconButton(
                icon: const Icon(Icons.qr_code_scanner_rounded),
                onPressed: () async {
                  final code = await Get.dialog<String>(
                    Scaffold(
                      appBar: AppBar(title: const Text('امسح الباركود للبحث')),
                      body: MobileScanner(
                        onDetect: (capture) {
                          if (capture.barcodes.isNotEmpty) {
                            Get.back(result: capture.barcodes.first.rawValue);
                          }
                        },
                      ),
                    ),
                  );
                  if (code != null) {
                    // بعد المسح، قم بوضع الباركود في الحقل وتشغيل البحث
                    textEditingController.text = code;
                  }
                },
                tooltip: 'بحث بالباركود',
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              isDense: true,
            ),
          );
        },
        emptyBuilder: (context) =>
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text('لم يتم العثور على منتج يطابق بحثك.',
              style: TextStyle(color: Colors.grey)),
        ),
      ),
    );
  }

  void _showEditItemDialog(BuildContext context,
      AddSalesInvoiceController controller, SalesInvoiceItem item) {
    // <-- 8.
    final qtyController = TextEditingController(
        text: item.quantity.toStringAsFixed(0));
    final salePriceController = TextEditingController(
        text: item.salePrice.toString());

    Get.dialog(
      AlertDialog(
        title: Text(item.product.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogInfoRow('الكمية المتوفرة:',
                  '${item.product.quantity} ${item.product.unit ?? ''}'),
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
              final newQty = double.tryParse(qtyController.text) ??
                  item.quantity;
              final newSalePrice = double.tryParse(salePriceController.text) ??
                  item.salePrice;
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

  Widget _buildDialogEditableRow(String label,
      TextEditingController controller) {
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

  Widget _buildNewFooter(BuildContext context,
      AddSalesInvoiceController controller) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme
              .of(context)
              .canvasColor,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2))
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Obx(() =>
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الإجمالي: ${controller.grandTotal.toStringAsFixed(
                            2)} ريال', // <-- 9.
                        style: TextStyle(fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Get.theme.primaryColor),
                      ),
                      Text(
                        'عدد الأصناف: ${controller.invoiceItems
                            .length} | إجمالي الكمية: ${controller
                            .totalItemsCount}',
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 13),
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
                  _showReviewBottomSheet(context, controller);
                },
                icon: const Icon(Icons.payment_rounded),
                label: const Text('مراجعة وحفظ'),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReviewBottomSheet(BuildContext context,
      AddSalesInvoiceController controller) {
    controller.updateTotals(); // حساب الإجماليات أولاً

    Get.bottomSheet(
      isScrollControlled: true, // للسماح للواجهة بأخذ ارتفاع الشاشة
      ignoreSafeArea: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      Container(
        height: MediaQuery
            .of(context)
            .size
            .height * 0.9, // 90% من ارتفاع الشاشة
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. هيدر الـ BottomSheet
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('مراجعة وحفظ الفاتورة', style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),

            // 2. محتوى قابل للتمرير
            Expanded(
              child: ListView(
                children: [
                  // ملخص الأصناف
                  _buildItemsSummary(controller),
                  const Divider(height: 24),
                  // قسم الخصم
                  _buildDiscountSection(controller),
                  const Divider(height: 24),
                  // قسم الدفع
                  _buildPaymentSection(controller),
                ],
              ),
            ),

            // 3. زر الحفظ في الأسفل
            SafeArea(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.done_all_rounded),
                label: const Text('تأكيد وحفظ الفاتورة'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                onPressed: controller.saveSalesInvoice,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ودجت بناء ملخص الأصناف
  Widget _buildItemsSummary(AddSalesInvoiceController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ملخص الأصناف',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 150),
          // تحديد ارتفاع أقصى
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: controller.invoiceItems.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = controller.invoiceItems[index];
              // --- بداية التعديل: تحسين عرض تفاصيل الصنف ---
              return ListTile(
                dense: true,
                title: Text(item.product.name),
                subtitle: Text(
                  '${item.quantity.toInt()} × ${item.salePrice.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                trailing: Text(
                  '${item.subtotal.toStringAsFixed(2)} ريال',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ودجت بناء قسم الخصم
  Widget _buildDiscountSection(AddSalesInvoiceController controller) {
    return Column(
      children: [
        Obx(() =>
            SegmentedButton<DiscountType>(
              segments: const [
                ButtonSegment(
                    value: DiscountType.amount, label: Text('خصم مبلغ')),
                ButtonSegment(
                    value: DiscountType.percentage, label: Text('خصم نسبة %')),
              ],
              selected: {controller.discountType.value},
              onSelectionChanged: (newSelection) {
                controller.discountType.value = newSelection.first;
                controller.updateTotals();
              },
            )),
        const SizedBox(height: 12),
        Obx(() =>
            TextField(
              controller: controller.discountController,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true),
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                labelText: controller.discountType.value == DiscountType.amount
                    ? 'قيمة الخصم'
                    : 'نسبة الخصم %',
                border: const OutlineInputBorder(),
              ),
            )),
      ],
    );
  }

  // ودجت بناء قسم الدفع
  Widget _buildPaymentSection(AddSalesInvoiceController controller) {
    final formatCurrency = (double val) => '${val.toStringAsFixed(2)} ريال';
    return Obx(() =>
        Column(
          children: [
            _buildDialogInfoRow(
                'الإجمالي الفرعي:', formatCurrency(controller.subtotal)),
            _buildDialogInfoRow(
              'قيمة الخصم:',
              '- ${formatCurrency(controller.discountValue.value)}',
            ),
            const Divider(thickness: 1.5),
            _buildDialogInfoRow(
              'الإجمالي النهائي:', formatCurrency(controller.grandTotal),),
            const SizedBox(height: 16),
            TextField(
              controller: controller.paidAmountController,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true),
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                labelText: 'المبلغ المدفوع',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _buildDialogInfoRow(
                'المبلغ المتبقي:', formatCurrency(controller.remainingAmount),),
            ),
          ],
        ));
  }

  Widget _buildItemCard(BuildContext context,
      AddSalesInvoiceController controller, SalesInvoiceItem item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text(item.product.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          'الكمية: ${item.quantity.toStringAsFixed(0)} × ${item.salePrice
              .toStringAsFixed(2)}  =  ${item.subtotal.toStringAsFixed(
              2)} ريال',
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: Colors.red.shade700),
          onPressed: () =>
              controller.removeProductFromInvoice(item.product.id!),
        ),
        onTap: () => _showEditItemDialog(context, controller, item),
      ),
    );
  }
}
