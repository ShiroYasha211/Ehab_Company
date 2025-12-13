// File: lib/features/purchases/presentation/screens/add_purchase_invoice_screen.dart

import 'package:ehab_company_admin/features/products/presentation/screens/add_edit_product_screen.dart';
import 'package:ehab_company_admin/features/purchases/presentation/controllers/add_purchase_controller.dart';
import 'package:ehab_company_admin/features/suppliers/data/models/supplier_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// ------------------- ودجت بطاقة الصنف -------------------
class InvoiceItemCard extends StatelessWidget {
  final InvoiceItem item;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const InvoiceItemCard({
    super.key,
    required this.item,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Text(
                      item.product.name.length >= 2 ? item.product.name.substring(0, 2).toUpperCase() : item.product.name.toUpperCase(),
                      style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.product.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.close_rounded, color: Colors.red, size: 20),
                      onPressed: onDelete,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.1),
                      ),
                    ),
                  )
                ],
              ),
              const Divider(height: 12, thickness: 0.5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoColumn('الكمية', '${item.quantity.toStringAsFixed(0)} ${item.product.unit ?? ''}'),
                  _buildInfoColumn('التكلفة', '${item.purchasePrice.toStringAsFixed(2)} ريال'),
                  _buildInfoColumn('الإجمالي', '${item.subtotal.toStringAsFixed(2)} ريال', isTotal: true),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, {bool isTotal = false}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: FontWeight.bold,
            color: isTotal ? Get.theme.primaryColor : null,
          ),
        ),
      ],
    );
  }
}

// ------------------- الشاشة الرئيسية -------------------
class AddPurchaseInvoiceScreen extends StatelessWidget {
  const AddPurchaseInvoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AddPurchaseController controller = Get.find<AddPurchaseController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('فاتورة شراء جديدة'),
      ),
      bottomNavigationBar: _buildNewFooter(context, controller),
      body: Column(
        children: [
          _buildHeader(context, controller),
          const Divider(height: 1, thickness: 1),
          Expanded(
            child: Obx(() {
              if (controller.invoiceItems.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('فاتورة فارغة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text('اضغط على زر + لإضافة أول صنف', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 80),
                itemCount: controller.invoiceItems.length,
                itemBuilder: (context, index) {
                  final item = controller.invoiceItems[index];
                  return InvoiceItemCard(
                    item: item,
                    onDelete: () => controller.removeProductFromInvoice(item.product.id!),
                    onTap: () => _showEditItemDialog(context, controller, item),
                  );
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSearchDialog(context, controller),
        label: const Text('إضافة صنف'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AddPurchaseController controller) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('اختيار المورد', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Obx(() {
            if (controller.supplierController.isLoading.isTrue) {
              return const Center(child: Text("جاري تحميل قائمة الموردين..."));
            }
            return DropdownButtonFormField<SupplierModel>(
              value: controller.selectedSupplier.value,
              items: controller.supplierController.filteredSuppliers.map((supplier) {
                return DropdownMenuItem<SupplierModel>(
                  value: supplier,
                  child: Text(supplier.name),
                );
              }).toList(),
              onChanged: (value) {
                controller.selectedSupplier.value = value;
              },
              decoration: const InputDecoration(
                hintText: 'اختر اسم المورد',
                prefixIcon: Icon(Icons.person_search_outlined),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (value) => value == null ? 'الرجاء اختيار مورد' : null,
            );
          }),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('رقم الفاتورة', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller.invoiceIdController,
                      readOnly: true,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.confirmation_number_outlined),
                        border: OutlineInputBorder(),
                        isDense: true,
                        filled: true,
                        fillColor: Color.fromARGB(255, 236, 236, 236),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('تاريخ الفاتورة', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller.dateController,
                      readOnly: true,
                      onTap: () => controller.selectInvoiceDate(context),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSearchDialog(BuildContext context, AddPurchaseController mainController) {
    final searchController = TextEditingController(text: mainController.productController.searchQuery.value);

    Get.dialog(
      AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        title: const Text('بحث عن صنف'),
        content: SizedBox(
          width: Get.width * 0.9,
          height: Get.height * 0.5,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: TextField(
                  controller: searchController,
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

                  if (products.isEmpty && query.isEmpty) {
                    return const Center(child: Text('تصفح المنتجات أو ابدأ البحث...'));
                  }

                  return ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(

                            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                            foregroundColor: Theme.of(context).primaryColor,

                            child: Text(product.quantity.toInt().toString()),
                          ),
                          title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text('سعر الشراء: ${product.purchasePrice} ريال'),
                          onTap: () {
                            mainController.addProductToInvoice(
                              product,
                              1,
                              product.purchasePrice,
                            );
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
          OutlinedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('منتج جديد'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.green.shade700),
            onPressed: () {
              Get.back();
              Get.to(() => const AddEditProductScreen());
            },
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
      barrierDismissible: false,
    ).whenComplete(() => mainController.clearProductSearch());
  }

  void _showEditItemDialog(BuildContext context, AddPurchaseController controller, InvoiceItem item) {
    final qtyController = TextEditingController(text: item.quantity.toStringAsFixed(0));
    final purchasePriceController = TextEditingController(text: item.purchasePrice.toString());
    final salePriceController = TextEditingController(text: item.product.salePrice.toString());

    Get.dialog(
      AlertDialog(
        title: Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogInfoRow('الكمية الحالية في المخزن:', '${item.product.quantity} ${item.product.unit ?? ''}'),
              const Divider(),
              _buildDialogEditableRow('الكمية الجديدة في الفاتورة:', qtyController),
              const Divider(),
              _buildDialogInfoRow('آخر سعر شراء:', '${item.product.purchasePrice} ريال'),
              _buildDialogEditableRow('سعر الشراء الجديد:', purchasePriceController),
              const Divider(),
              _buildDialogInfoRow('سعر البيع الحالي:', '${item.product.salePrice} ريال'),
              _buildDialogEditableRow('سعر البيع الجديد:', salePriceController),
              const Divider(),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              final newQty = double.tryParse(qtyController.text) ?? item.quantity;
              final newPurchasePrice = double.tryParse(purchasePriceController.text) ?? item.purchasePrice;
              final newSalePrice = double.tryParse(salePriceController.text);
              controller.updateInvoiceItem(
                productId: item.product.id!,
                newQuantity: newQty,
                newPurchasePrice: newPurchasePrice,
                newSalePrice: newSalePrice,
              );
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

  Widget _buildNewFooter(BuildContext context, AddPurchaseController controller) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Obx(() => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الإجمالي: ${controller.subtotal.toStringAsFixed(2)} ريال',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Get.theme.primaryColor,
                    ),
                  ),
                  Text(
                    'عدد الأصناف: ${controller.invoiceItems.length} | عدد القطع: ${controller.totalItemsCount}',
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
                  _showPaymentDialog(context, controller);
                },
                icon: const Icon(Icons.payment_rounded),
                label: const Text('مراجعة وحفظ'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _showPaymentDialog(BuildContext context, AddPurchaseController controller) {
    controller.preparePaymentDialog(); // تهيئة حقول الديالوج

    Get.dialog(
        AlertDialog(
            title: const Text('مراجعة الدفع والحفظ'),
            content: Obx(() => SingleChildScrollView(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                // طريقة الدفع
                DropdownButtonFormField<String>(
                value: controller.paidAmount.value == 0
                ? 'آجل'
                    : controller.paidAmount.value == controller.grandTotal
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
                // الحسابات المالية
                _buildDialogInfoRow('الإجمالي الفرعي:', '${controller.subtotal.toStringAsFixed(2)} ريال'),
                _buildDialogEditableRow('الخصم (مبلغ)', controller.discountController),
                _buildDialogEditableRow('الضريبة (%)', controller.taxController),
                const SizedBox(height: 10),
                _buildDialogInfoRow('الإجمالي النهائي:', '${controller.grandTotal.toStringAsFixed(2)} ريال'),

                const Divider(height: 20),
                _buildDialogEditableRow('المبلغ المدفوع:', controller.paidAmountController),
                const SizedBox(height: 10),
                _buildDialogInfoRow('المبلغ المتبقي:', '${controller.remainingAmount.toStringAsFixed(2)} ريال',),
              const Divider(height: 20),

              // --- بداية الإضافة ---
              SwitchListTile(
                title: const Text('خصم المبلغ المدفوع من الصندوق'),
                value: controller.shouldDeductFromFund.value,
                onChanged: (value) {
                  controller.shouldDeductFromFund.value = value;
                },
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),

                    ],
                ),
            )),
            actions: [
            TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
    Obx(() {
    if (controller.isSaving.isTrue) {
    return const CircularProgressIndicator();
    }
    return ElevatedButton.icon(
    onPressed: controller.savePurchaseInvoice,
    icon: const Icon(Icons.save_alt_rounded),
      label: const Text('تأكيد وحفظ'),
    );
    }),
            ],
        ),
    );
  }
}