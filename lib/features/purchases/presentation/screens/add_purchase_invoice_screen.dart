import 'package:ehab_company_admin/features/purchases/presentation/controllers/add_purchase_controller.dart';
import 'package:ehab_company_admin/features/suppliers/data/models/supplier_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ehab_company_admin/features/products/data/models/product_model.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class AddPurchaseInvoiceScreen extends StatelessWidget {
  const AddPurchaseInvoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AddPurchaseController controller = Get.find<AddPurchaseController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('فاتورة مشتريات جديدة'),
      ),
      bottomNavigationBar: _buildNewFooter(context, controller),
      body: Column(
        children: [
          // --- الترتيب الجديد ---
          _buildMagicSearchBar(controller),
          const Divider(height: 1),
          _buildHeader(context, controller),
          const Divider(height: 1),
          Expanded(
            child: Obx(
                  () => controller.invoiceItems.isEmpty
                  ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('الفاتورة فارغة',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('استخدم شريط البحث أعلاه لإضافة الأصناف',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: controller.invoiceItems.length,
                itemBuilder: (context, index) {
                  final item = controller.invoiceItems[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    child: ListTile(
                      title: Text(item.product.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          'الكمية: ${item.quantity.toInt()} × ${item.purchasePrice.toStringAsFixed(2)} ريال'),
                      trailing: IconButton(
                        icon: Icon(Icons.delete_outline,
                            color: Colors.red.shade700),
                        onPressed: () =>
                            controller.removeProductFromInvoice(item.product.id!),
                      ),
                      onTap: () =>
                          _showEditItemDialog(context, controller, item),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ودجت الهيدر لعرض المورد والتاريخ
  Widget _buildHeader(BuildContext context, AddPurchaseController controller) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() {
            if (controller.supplierController.isLoading.isTrue) {
              return const Center(child: Text("جاري تحميل قائمة الموردين..."));
            }
            return DropdownButtonFormField<SupplierModel>(
              value: controller.selectedSupplier.value,
              items:
              controller.supplierController.filteredSuppliers.map((supplier) {
                return DropdownMenuItem<SupplierModel>(
                  value: supplier,
                  child: Text(supplier.name),
                );
              }).toList(),
              onChanged: (value) {
                controller.selectedSupplier.value = value;
              },
              decoration: const InputDecoration(
                hintText: 'اختر اسم المورد *',
                prefixIcon: Icon(Icons.person_search_outlined),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (value) => value == null ? 'الرجاء اختيار مورد' : null,
            );
          }),
          const SizedBox(height: 16),
          TextField(
            controller: controller.dateController,
            readOnly: true,
            onTap: () => controller.selectInvoiceDate(context),
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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

  // ديالوج تعديل الصنف
  void _showEditItemDialog(BuildContext context, AddPurchaseController controller, InvoiceItem item) {
    final qtyController = TextEditingController(text: item.quantity.toStringAsFixed(0));
    final purchasePriceController = TextEditingController(text: item.purchasePrice.toString());
    final salePriceController = TextEditingController(text: item.product.salePrice.toString());

    Get.dialog(
      AlertDialog(
        title: Text(item.product.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // حقول التعديل
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextField(
                  controller: qtyController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(

                    labelText: 'الكمية في الفاتورة',
                    helperText: 'المتوفر في المخزن: ${item.product.quantity.toInt()}',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextField(
                  controller: purchasePriceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: 'سعر الشراء الجديد',
                    helperText: 'آخر سعر شراء: ${item.product.purchasePrice}',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextField(
                  controller: salePriceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textDirection: TextDirection.ltr,

                  decoration: InputDecoration(
                    labelText: 'سعر البيع الجديد',
                    helperText: 'سعر البيع الحالي: ${item.product.salePrice}',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
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

  // ودجت الفوتر لعرض الإجمالي وزر الحفظ
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
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  Text(
                    'عدد الأصناف: ${controller.invoiceItems.length} | إجمالي القطع: ${controller.totalItemsCount}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              )),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 150,
              child: ElevatedButton.icon(
                // استدعاء دالة عرض شاشة المراجعة الجديدة
                onPressed: () {
                  if (controller.invoiceItems.isEmpty) {
                    Get.snackbar('خطأ', 'لا يمكن المتابعة، الفاتورة فارغة.');
                    return;
                  }
                  if (controller.selectedSupplier.value == null) {
                    Get.snackbar('خطأ', 'الرجاء اختيار مورد أولاً.');
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

  // --- ودجت شريط البحث السحري الجديد ---
  Widget _buildMagicSearchBar(AddPurchaseController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: TypeAheadField<ProductModel>(
        suggestionsCallback: (pattern) async {
          // التأكد من جلب المنتجات أولاً
          if (controller.productController.allProducts.isEmpty) {
            await controller.productController.fetchAllProducts();
          }
          if (pattern.isEmpty) {
            return [];
          }
          return controller.productController.allProducts.where((product) {
            final nameMatches =
            product.name.toLowerCase().contains(pattern.toLowerCase());
            final codeMatches = product.code
                ?.toLowerCase()
                .contains(pattern.toLowerCase()) ??
                false;
            return nameMatches || codeMatches;
          }).toList();
        },
        itemBuilder: (context, suggestion) {
          return ListTile(
            leading: Text(suggestion.quantity.toInt().toString(),
                style: const TextStyle(fontSize: 16, color: Colors.blue)),
            title: Text(suggestion.name),
            trailing: Text(
                '${suggestion.purchasePrice.toStringAsFixed(2)} ريال'),
          );
        },
        onSelected: (suggestion) {
          controller.addProductToInvoice(
            suggestion,
            1, // كمية افتراضية
            suggestion.purchasePrice, // سعر الشراء الافتراضي
          );
          controller.productSearchController.clear();
        },
        builder: (context, textEditingController, focusNode) {
          //controller.productSearchController = textEditingController;
          return TextField(
            controller: textEditingController,
            focusNode: focusNode,
            decoration: InputDecoration(
              hintText: 'ابحث بالاسم أو الباركود لإضافة صنف...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.qr_code_scanner_rounded),
                onPressed: () async {
                  final code = await Get.dialog<String>(
                    Scaffold(
                      appBar: AppBar(title: const Text('امسح الباركود')),
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
                    textEditingController.text = code;
                  }
                },
                tooltip: 'بحث بالباركود',
              ),
              border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
          );
        },
        emptyBuilder: (context) => const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text('لم يتم العثور على منتج يطابق بحثك.',
              style: TextStyle(color: Colors.grey)),
        ),
      ),
    );
  }

  // --- بداية الإضافة: دوال بناء شاشة المراجعة الجديدة ---

  /// الدالة الرئيسية لبناء وعرض شاشة المراجعة
  void _showReviewBottomSheet(BuildContext context,
      AddPurchaseController controller) {
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
            .height * 0.9,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. هيدر الـ BottomSheet
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('مراجعة وحفظ الفاتورة',
                      style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                  _buildItemsSummary(controller),
                  const Divider(height: 24),
                  _buildDiscountSection(controller),
                  const Divider(height: 24),
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
                onPressed: controller.savePurchaseInvoice
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ودجت بناء ملخص الأصناف
  Widget _buildItemsSummary(AddPurchaseController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ملخص الأصناف',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          constraints:
          const BoxConstraints(maxHeight: 150), // تحديد ارتفاع أقصى
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
              return ListTile(
                dense: true,
                title: Text(item.product.name),
                subtitle: Text(
                  '${item.quantity.toInt()} × ${item.purchasePrice
                      .toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                trailing: Text(
                  '${(item.quantity * item.purchasePrice).toStringAsFixed(
                      2)} ريال',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// ودجت بناء قسم الخصم
  Widget _buildDiscountSection(AddPurchaseController controller) {
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
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
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

  /// ودجت بناء قسم الدفع والملخص المالي
  Widget _buildPaymentSection(AddPurchaseController controller) {
    final formatCurrency = (double val) => '${val.toStringAsFixed(2)} ريال';
    return Obx(() =>
        Column(
          children: [
            _buildDialogInfoRow(
                'الإجمالي الفرعي:', formatCurrency(controller.subtotal)),
            _buildDialogInfoRow('قيمة الخصم:',
                '- ${formatCurrency(controller.discountValue.value)}',
                color: Colors.orange.shade700),
            const Divider(thickness: 1.5),
            _buildDialogInfoRow(
                'الإجمالي النهائي:', formatCurrency(controller.grandTotal),
                isLarge: true, isBold: true, color: Get.theme.primaryColor),
            const SizedBox(height: 16),
            TextField(
              controller: controller.paidAmountController,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
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
                  'المبلغ المتبقي:', formatCurrency(controller.remainingAmount),
                  isLarge: true, isBold: true),
            ),
          ],
        ));
  }

  /// ودجت مساعد لعرض صف معلومات داخل شاشة المراجعة
  Widget _buildDialogInfoRow(String label, String value,
      {bool isLarge = false, bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 15)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isLarge ? 18 : 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
// --- نهاية الإضافة ---
}
