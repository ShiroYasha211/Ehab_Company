// File: lib/features/purchases/presentation/widgets/product_search_sheet.dart

import 'package:ehab_company_admin/features/products/data/models/product_model.dart';
import 'package:ehab_company_admin/features/products/presentation/screens/add_edit_product_screen.dart';
import 'package:ehab_company_admin/features/purchases/presentation/controllers/add_purchase_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ProductSearchSheet extends StatelessWidget {
  final AddPurchaseController mainController;

  const ProductSearchSheet({super.key, required this.mainController});

  @override
  Widget build(BuildContext context) {
    // Controllers محلية خاصة بهذه الشاشة فقط
    final searchController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final purchasePriceController = TextEditingController();
    final salePriceController = TextEditingController();
    final Rx<ProductModel?> selectedProduct = Rx<ProductModel?>(null);

    // دالة مساعدة لملء بيانات النموذج عند اختيار منتج
    void fillFormWithProduct(ProductModel product) {
      purchasePriceController.text = product.purchasePrice.toString();
      salePriceController.text = product.salePrice.toString();
      selectedProduct.value = product;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة صنف للفاتورة'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'ابحث بالاسم أو الباركود...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: () async {
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
                      searchController.text = code;
                      mainController.productController.searchQuery.value = code;
                    }
                  },
                ),
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => mainController.productController.searchQuery.value = value,
            ),
          ),
        ),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. القسم الأيمن: قائمة نتائج البحث
          Expanded(
            flex: 2,
            child: Obx(() {
              final products = mainController.productController.filteredProducts;
              if (products.isEmpty && mainController.productController.searchQuery.isNotEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('لم يتم العثور على المنتج.'),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: () {
                          // إغلاق الشاشة المنزلقة ثم فتح شاشة إضافة المنتج
                          Get.back();
                          Get.to(() => const AddEditProductScreen());
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('إضافة منتج جديد'),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: ListTile(
                      title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('المتوفر: ${product.quantity}'),
                      onTap: () => fillFormWithProduct(product),
                    ),
                  );
                },
              );
            }),
          ),
          const VerticalDivider(),
          // 2. القسم الأيسر: نموذج الإضافة
          Expanded(
            flex: 3,
            child: Obx(() {
              if (selectedProduct.value == null) {
                return const Center(child: Text('اختر منتجًا من القائمة لعرض التفاصيل'));
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedProduct.value!.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'الكمية المتوفرة حاليًا: ${selectedProduct.value!.quantity}',
                      style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 30),
                    TextField(controller: quantityController, decoration: const InputDecoration(labelText: 'الكمية المشتراة *', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                    const SizedBox(height: 16),
                    TextField(controller: purchasePriceController, decoration: const InputDecoration(labelText: 'سعر الشراء *', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                    const SizedBox(height: 16),
                    TextField(controller: salePriceController, decoration: const InputDecoration(labelText: 'سعر البيع (لتحديثه)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text('إضافة إلى الفاتورة'),
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                        onPressed: () {
                          final quantity = double.tryParse(quantityController.text) ?? 0;
                          final price = double.tryParse(purchasePriceController.text) ?? 0;
                          mainController.addProductToInvoice(selectedProduct.value!, quantity, price);
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
