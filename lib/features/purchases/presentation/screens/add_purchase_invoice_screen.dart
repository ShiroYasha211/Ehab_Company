import 'package:ehab_company_admin/features/purchases/presentation/controllers/add_purchase_controller.dart';
import 'package:ehab_company_admin/features/suppliers/data/models/supplier_model.dart';
import 'package:ehab_company_admin/features/suppliers/presentation/screens/add_edit_supplier_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ehab_company_admin/features/products/data/models/product_model.dart';
import 'package:ehab_company_admin/features/categories/data/models/category_model.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ehab_company_admin/features/units/presentation/controllers/unit_controller.dart';
import 'package:ehab_company_admin/features/purchases/data/models/purchase_invoice_item.dart';
import 'package:ehab_company_admin/core/services/settings_service.dart';
import 'package:intl/intl.dart' as intl;
import 'package:ehab_company_admin/features/fund/data/models/fund_model.dart';

class AddPurchaseInvoiceScreen extends StatelessWidget {
  const AddPurchaseInvoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AddPurchaseController controller = Get.find<AddPurchaseController>();

    return SafeArea(
      child: Scaffold(
      appBar: AppBar(title: const Text('فاتورة مشتريات جديدة')),
      bottomNavigationBar: _buildNewFooter(context, controller),
      body: Column(
        children: [
          _buildMagicSearchBar(context, controller),
          _buildHeader(context, controller),
          const Divider(height: 1),
          Expanded(
            child: Obx(() {
              if (controller.invoiceItems.isEmpty) {
                return _buildEmptyState();
              }
              final unitController = Get.find<UnitController>();
              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: controller.invoiceItems.length,
                itemBuilder: (context, index) {
                  final item = controller.invoiceItems[index];
                  return _buildItemCard(context, controller, item, unitController);
                },
              );
            }),
          ),
        ],
      ),
      ),
    );
  }

  // --- شريط البحث السحري (الهرمي - مطابق للمبيعات) ---
  Widget _buildMagicSearchBar(BuildContext context, AddPurchaseController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Obx(() {
        final selectedCat = controller.selectedSearchCategory.value;

        return TypeAheadField<Object>(
          key: ValueKey('purchase_search_${selectedCat ?? "root"}'),
          suggestionsCallback: (pattern) async {
            if (selectedCat == null) {
              return controller.categoryController.categories.where((cat) {
                return cat.name.toLowerCase().contains(pattern.toLowerCase());
              }).toList();
            } else {
              if (controller.productController.allProducts.isEmpty) {
                await controller.productController.fetchAllProducts();
              }
              return controller.productController.allProducts.where((product) {
                final isInCategory = product.category == selectedCat;
                if (!isInCategory) return false;
                if (pattern.isEmpty) return true;
                final nameMatches = product.name.toLowerCase().contains(pattern.toLowerCase());
                final codeMatches = product.code?.toLowerCase().contains(pattern.toLowerCase()) ?? false;
                return nameMatches || codeMatches;
              }).toList();
            }
          },
          itemBuilder: (context, suggestion) {
            if (suggestion is CategoryModel) {
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.folder_open_rounded, color: Colors.orange),
                ),
                title: Text(suggestion.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('تصفح منتجات هذا القسم', style: TextStyle(fontSize: 12, color: Colors.grey)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
              );
            } else if (suggestion is ProductModel) {
              return ListTile(
                leading: Container(
                  width: 45, height: 45,
                  decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Center(child: Text(suggestion.quantity.toInt().toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
                ),
                title: Text(suggestion.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('كود: ${suggestion.code ?? "---"}'),
                trailing: Text('${suggestion.purchasePrice.toStringAsFixed(2)} ${Get.find<SettingsService>().primaryCurrency.value.symbol}'),
              );
            }
            return const SizedBox.shrink();
          },
          onSelected: (suggestion) {
            if (suggestion is CategoryModel) {
              controller.selectedSearchCategory.value = suggestion.name;
            } else if (suggestion is ProductModel) {
              _showProductSelectionSheet(context, controller, suggestion);
            }
          },
          builder: (context, textEditingController, focusNode) {
            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: selectedCat == null ? 'اختر قسماً أو ابحث بالاسم...' : 'بحث في قسم $selectedCat...',
                prefixIcon: selectedCat != null 
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ActionChip(
                          avatar: const Icon(Icons.folder_rounded, size: 16, color: Colors.white),
                          label: Text(selectedCat, style: const TextStyle(color: Colors.white, fontSize: 12)),
                          backgroundColor: Colors.orange,
                          padding: EdgeInsets.zero,
                          onPressed: () => controller.selectedSearchCategory.value = null,
                        ),
                      )
                    : const Icon(Icons.search),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (textEditingController.text.isNotEmpty || selectedCat != null)
                      IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          textEditingController.clear();
                          controller.selectedSearchCategory.value = null;
                        },
                      ),
                    _buildQRScannerIcon(context, textEditingController),
                  ],
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              ),
            );
          },
        );
      }),
    );
  }

  // --- نافذة اختيار الأصناف المتطورة (BottomSheet - مطابق للمبيعات) ---
  void _showProductSelectionSheet(
    BuildContext context,
    AddPurchaseController controller,
    ProductModel product, {
    PurchaseInvoiceItem? existingItem,
  }) {
    final quantity = (existingItem?.quantity ?? 1.0).obs;
    final freeQuantity = (existingItem?.freeQuantity ?? 0.0).obs;
    final selectedUnitId = (existingItem?.selectedUnitId ?? product.unitId!).obs;
    
    final purchasePrice = (existingItem?.purchasePrice ?? product.purchasePrice).obs;
    final salePrice = (existingItem?.newSalePrice ?? product.salePrice).obs;

    final qtyController = TextEditingController(text: quantity.value.toStringAsFixed(quantity.value == quantity.value.toInt() ? 0 : 2));
    final freeQtyController = TextEditingController(text: freeQuantity.value.toStringAsFixed(freeQuantity.value == freeQuantity.value.toInt() ? 0 : 2));
    final purchasePriceController = TextEditingController(text: purchasePrice.value.toStringAsFixed(2));
    final salePriceController = TextEditingController(text: salePrice.value.toStringAsFixed(2));

    final unitController = Get.find<UnitController>();
    final currency = Get.find<SettingsService>().primaryCurrency.value.symbol;

    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2)],
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 50, height: 5,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                  ),
                ),

                // 1. هيدر النافذة (اسم المنتج + السعر)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          if (product.code != null)
                            Text('كود: ${product.code}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(color: Get.theme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Obx(() => Text(
                        '${purchasePrice.value.toStringAsFixed(2)} $currency',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Get.theme.primaryColor),
                      )),
                    ),
                  ],
                ),
                const Divider(height: 35),

                // 2. اختيار الوحدة (سلسلة الوحدات)
                const Text('اختر وحدة الشراء:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 12),
                Obx(() {
                  final allowedIds = controller.getAllowedUnitIds(product);
                  return Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    children: allowedIds.map((id) {
                      final unit = unitController.allUnits.firstWhereOrNull((u) => u.id == id);
                      if (unit == null) return const SizedBox.shrink();
                      final isSelected = selectedUnitId.value == id;
                      return ChoiceChip(
                        label: Text(unit.name, style: TextStyle(color: isSelected ? Colors.white : Colors.black87)),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) {
                            selectedUnitId.value = id;
                            // تمت إزالة تحديث السعر هنا ليبقى السعر ثابتاً للوحدة الكبرى كما طلب المستخدم
                          }
                        },
                        selectedColor: Get.theme.primaryColor,
                        backgroundColor: Colors.grey.shade100,
                        checkmarkColor: Colors.white,
                        elevation: isSelected ? 4 : 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      );
                    }).toList(),
                  );
                }),
                const SizedBox(height: 20),

                // 3. معلومات التحويل والمخزون
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Obx(() {
                    final factor = controller.calculateConversionFactor(product, selectedUnitId.value);
                    final currentUnit = unitController.allUnits.firstWhereOrNull((u) => u.id == selectedUnitId.value);
                    if (currentUnit == null) return const SizedBox.shrink();
                    
                    String convertInfo = '';
                    if (currentUnit.childUnitId != null) {
                      final childUnit = unitController.allUnits.firstWhereOrNull((u) => u.id == currentUnit.childUnitId);
                      if (childUnit != null) {
                        convertInfo = '1 ${currentUnit.name} = ${currentUnit.conversionFactor.toInt()} ${childUnit.name}';
                      }
                    } else {
                        convertInfo = 'أصغر وحدة متوفرة';
                    }

                    // حساب الرصيد الحالي بالوحدة المختارة (مع مراعاة التحديث)
                    double adjustedAvailablePrimary = product.quantity;
                    if (existingItem != null) {
                       final existingFactor = controller.calculateConversionFactor(product, existingItem.selectedUnitId ?? product.unitId!);
                       adjustedAvailablePrimary += existingItem.quantity / (existingFactor > 0 ? existingFactor : 1.0);
                    }

                    final stockInUnit = adjustedAvailablePrimary * factor;

                    return Column(
                      children: [
                        _buildDetailRow(Icons.sync_alt_rounded, 'التحويل:', convertInfo, Colors.blue),
                        const Divider(height: 15),
                        _buildDetailRow(
                          Icons.inventory_2_outlined, 
                          'المتوفر بالمخزون:', 
                          '${stockInUnit.toStringAsFixed(stockInUnit == stockInUnit.toInt() ? 0 : 2)} ${currentUnit.name}', 
                          Colors.green
                        ),
                      ],
                    );
                  }),
                ),
                const SizedBox(height: 25),

                // 4. التحكم في الكمية المشتراة
                const Text('الكمية المشتراة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildIconButton(Icons.remove_rounded, () {
                      if (quantity.value > 1) {
                        quantity.value--;
                        qtyController.text = quantity.value.toStringAsFixed(0);
                      }
                    }),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: TextField(
                          controller: qtyController,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.zero,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          onChanged: (v) => quantity.value = double.tryParse(v) ?? 1.0,
                        ),
                      ),
                    ),
                    _buildIconButton(Icons.add_rounded, () {
                      quantity.value++;
                      qtyController.text = quantity.value.toStringAsFixed(0);
                    }),
                  ],
                ),
                const SizedBox(height: 20),

                // 5. التحكم في الكمية المجانية (Bonus)
                Row(
                  children: [
                     Icon(Icons.card_giftcard_rounded, size: 18, color: Colors.orange.shade700),
                     const SizedBox(width: 8),
                     Text('الكمية المجانية (Bonus):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.orange.shade900)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildIconButton(Icons.remove_rounded, () {
                      if (freeQuantity.value > 0) {
                        freeQuantity.value--;
                        freeQtyController.text = freeQuantity.value.toStringAsFixed(0);
                      }
                    }, color: Colors.orange),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: TextField(
                          controller: freeQtyController,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                          decoration: InputDecoration(
                            hintText: '0',
                            contentPadding: EdgeInsets.zero,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.orange)),
                          ),
                          onChanged: (v) => freeQuantity.value = double.tryParse(v) ?? 0.0,
                        ),
                      ),
                    ),
                    _buildIconButton(Icons.add_rounded, () {
                      freeQuantity.value++;
                      freeQtyController.text = freeQuantity.value.toStringAsFixed(0);
                    }, color: Colors.orange),
                  ],
                ),
                const SizedBox(height: 20),

                // 6. بطاقة الأسعار الموحدة (Premium Pricing Card)
                Obx(() {
                  final uc = Get.find<UnitController>();
                  final rootUnit = uc.allUnits.firstWhereOrNull((u) => u.id == product.unitId);
                  final rootName = rootUnit?.name ?? "الوحدة الكبرى";
                  final factor = controller.calculateConversionFactor(product, selectedUnitId.value);
                  final currentUnitPrice = purchasePrice.value / (factor > 0 ? factor : 1.0);
                  final selectedUnitName = uc.getUnitName(selectedUnitId.value);

                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.blue.shade100.withOpacity(0.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.monetization_on_outlined, color: Colors.blue.shade700, size: 20),
                                const SizedBox(width: 8),
                                Text('تسعير المنتج ($rootName)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                                const Spacer(),
                                if (selectedUnitId.value != product.unitId)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(20)),
                                    child: Text('سعر الـ $selectedUnitName: ${currentUnitPrice.toStringAsFixed(2)}', style: TextStyle(fontSize: 11, color: Colors.orange.shade900, fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: purchasePriceController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                    decoration: InputDecoration(
                                      labelText: 'سعر الشراء',
                                      filled: true,
                                      fillColor: Colors.white,
                                      prefixIcon: const Icon(Icons.arrow_downward_rounded, color: Colors.blue, size: 18),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                    onChanged: (v) => purchasePrice.value = double.tryParse(v) ?? 0.0,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: salePriceController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                    decoration: InputDecoration(
                                      labelText: 'سعر البيع',
                                      filled: true,
                                      fillColor: Colors.white,
                                      prefixIcon: const Icon(Icons.arrow_upward_rounded, color: Colors.green, size: 18),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                    onChanged: (v) => salePrice.value = double.tryParse(v) ?? 0.0,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 35),

                      // 7. زر الحفظ النهائي
                      Obx(() {
                        final isUpdate = existingItem != null;
                        final factor2 = controller.calculateConversionFactor(product, selectedUnitId.value);
                        final perUnitPrice = purchasePrice.value / (factor2 > 0 ? factor2 : 1.0);
                        final total = quantity.value * perUnitPrice;
                        
                        return ElevatedButton(
                          onPressed: () {
                            if (isUpdate) {
                              controller.updateItemDetails(
                                product.id!,
                                newQuantity: quantity.value,
                                newFreeQuantity: freeQuantity.value,
                                newUnitId: selectedUnitId.value,
                                newRootPurchasePrice: purchasePrice.value,
                                newRootSalePrice: salePrice.value,
                              );
                            } else {
                              controller.addProductToInvoice(
                                product,
                                quantity.value,
                                freeQuantity: freeQuantity.value,
                                rootPrice: purchasePrice.value,
                                rootSalePrice: salePrice.value,
                                unitId: selectedUnitId.value,
                              );
                            }
                            Get.back();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Get.theme.primaryColor,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 60),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            elevation: 4,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(isUpdate ? Icons.check_circle_outline : Icons.add_shopping_cart_rounded),
                              const SizedBox(width: 12),
                              Text(
                                '${isUpdate ? 'تحديث البيانات' : 'إضافة للفاتورة'} (الإجمالي: ${total.toStringAsFixed(2)})',
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  );
                }),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback? onTap, {Color? color}) {
    final primaryColor = color ?? Get.theme.primaryColor;
    return Material(
      color: primaryColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: primaryColor, size: 24),
        ),
      ),
    );
  }

  Widget _buildQRScannerIcon(BuildContext context, TextEditingController textController) {
    return IconButton(
      icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.blue),
      onPressed: () async {
        final code = await Get.dialog<String>(Scaffold(
          appBar: AppBar(title: const Text('امسح الباركود')),
          body: MobileScanner(onDetect: (capture) {
            if (capture.barcodes.isNotEmpty) Get.back(result: capture.barcodes.first.rawValue);
          }),
        ));
        if (code != null) textController.text = code;
      },
    );
  }

  Widget _buildItemCard(BuildContext context, AddPurchaseController controller, PurchaseInvoiceItem item, UnitController unitController) {
    final currency = Get.find<SettingsService>().primaryCurrency.value.symbol;
    return InkWell(
      onTap: () => _showProductSelectionSheet(context, controller, item.product, existingItem: item),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(width: 5, color: Get.theme.primaryColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                              onPressed: () => controller.removeProductFromInvoice(item.product.id!),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 15,
                          runSpacing: 8,
                          children: [
                            _buildMiniInfo(Icons.shopping_basket_outlined, '${item.quantity.toStringAsFixed(0)} ${unitController.getUnitName(item.selectedUnitId)}', Colors.blue),
                            if (item.freeQuantity > 0)
                               _buildMiniInfo(Icons.card_giftcard_rounded, 'بونص: ${item.freeQuantity.toStringAsFixed(0)}', Colors.orange),
                            _buildMiniInfo(Icons.sell_outlined, '${item.purchasePrice.toStringAsFixed(2)} $currency', Colors.green),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 80,
                  color: Colors.grey.shade50,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('الإجمالي', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        Text(item.subtotal.toStringAsFixed(1), style: TextStyle(fontWeight: FontWeight.bold, color: Get.theme.primaryColor, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniInfo(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('لا توجد أصناف في الفاتورة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
          const Text('استخدم شريط البحث بالأعلى لإضافة منتجاتك', style: TextStyle(color: Colors.grey)),
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
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, -2)),
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
                        'الإجمالي: ${controller.subtotal.toStringAsFixed(2)} ${Get.find<SettingsService>().primaryCurrency.value.symbol}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
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
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- الـ Header الجديد (مطابق للمبيعات) ---
  Widget _buildHeader(BuildContext context, AddPurchaseController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Obx(() {
                  if (controller.supplierController.isLoading.isTrue) {
                    return const Center(child: LinearProgressIndicator());
                  }
                  return DropdownButtonFormField<SupplierModel>(
                    value: controller.supplierController.filteredSuppliers
                        .firstWhereOrNull((s) => s.id == controller.selectedSupplier.value?.id),
                    items: controller.supplierController.filteredSuppliers.map((s) {
                      return DropdownMenuItem(value: s, child: Text(s.name));
                    }).toList(),
                    onChanged: (val) => controller.selectedSupplier.value = val,
                    decoration: const InputDecoration(
                      labelText: 'اسم المورد *',
                      prefixIcon: Icon(Icons.person_pin_rounded),
                      border: OutlineInputBorder(),
                    ),
                  );
                }),
              ),
              const SizedBox(width: 8),
              Container(
                height: 55, width: 55,
                decoration: BoxDecoration(color: Get.theme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: IconButton(
                  icon: Icon(Icons.person_add_alt_1_rounded, color: Get.theme.primaryColor),
                  onPressed: () => Get.to(() => const AddEditSupplierScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller.dateController,
            readOnly: true,
            onTap: () => controller.selectInvoiceDate(context),
            decoration: const InputDecoration(
              labelText: 'تاريخ الفاتورة',
              prefixIcon: Icon(Icons.calendar_month_rounded),
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  void _showReviewBottomSheet(BuildContext context, AddPurchaseController controller) {
    controller.updateTotals();
    Get.bottomSheet(
      isScrollControlled: true,
      ignoreSafeArea: false,
      backgroundColor: Colors.white,
      elevation: 20,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      Container(
        height: MediaQuery.of(context).size.height * 0.92,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('مراجعة وحفظ الفاتورة', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Text('أدخل تفاصيل الدفع لإكمال العملية', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
                IconButton(
                  icon: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle), child: const Icon(Icons.close, size: 20)),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Obx(() => ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildReviewSummaryCard(controller),
                  const SizedBox(height: 24),
                  const Text('الأصناف المضافة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  _buildItemsSummaryList(controller),
                  const SizedBox(height: 24),
                  const Text('حالة الفاتورة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  _buildPaymentModeSelection(controller),
                  const SizedBox(height: 24),
                  if (controller.paymentMode.value != PaymentMode.credit) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('تفاصيل سداد المبالغ:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        if (controller.paymentMode.value == PaymentMode.split)
                          TextButton.icon(onPressed: controller.addPaymentEntry, icon: const Icon(Icons.add_circle_outline, size: 20), label: const Text('إضافة طريقة دفع')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...controller.paymentEntries.asMap().entries.map((entry) {
                      return _buildPaymentEntryCard(context, controller, entry.value, entry.key);
                    }).toList(),
                    const SizedBox(height: 16),
                    _buildBalanceIndicator(controller),
                  ] else ...[
                    _buildFullCreditWarning(),
                  ],
                  const SizedBox(height: 20),
                  TextField(
                    controller: controller.notesController,
                    maxLines: 2,
                    decoration: InputDecoration(labelText: 'ملاحظات الفاتورة النهائية', prefixIcon: const Icon(Icons.note_alt_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.grey.shade50),
                  ),
                  const SizedBox(height: 100),
                ],
              )),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: const BoxDecoration(color: Colors.white),
              child: SafeArea(
                child: Obx(() => ElevatedButton(
                  onPressed: controller.isSaving.value ? null : controller.savePurchaseInvoice,
                  style: ElevatedButton.styleFrom(backgroundColor: Get.theme.primaryColor, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 4),
                  child: controller.isSaving.value 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.check_circle_outline), SizedBox(width: 12), Text('تـأكـيـد وحـفـظ الـفـاتـورة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewSummaryCard(AddPurchaseController controller) {
    final settings = Get.find<SettingsService>();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [Get.theme.primaryColor, Get.theme.primaryColor.withOpacity(0.8)]), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Get.theme.primaryColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('الإجمالي النهائي', style: TextStyle(color: Colors.white70, fontSize: 14)),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)), child: Text(intl.DateFormat('yyyy/MM/dd').format(controller.invoiceDate.value), style: const TextStyle(color: Colors.white, fontSize: 11))),
        ]),
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(controller.grandTotal.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(settings.primaryCurrency.value.symbol, style: const TextStyle(color: Colors.white70, fontSize: 16))),
        ]),
        if (settings.primaryCurrency.value.code != settings.localCurrency.value.code) ...[
          const Divider(color: Colors.white24, height: 32),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('عملة الدفع:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            SizedBox(height: 36, child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: Text(settings.primaryCurrency.value.symbol), icon: const Icon(Icons.language, size: 16)),
                ButtonSegment(value: true, label: Text(settings.localCurrency.value.symbol), icon: const Icon(Icons.location_on, size: 16)),
              ],
              selected: {controller.isLocalCurrencyPayment.value},
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? Colors.white : Colors.transparent),
                foregroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? Get.theme.primaryColor : Colors.white),
              ),
              onSelectionChanged: (newSelection) => controller.togglePaymentCurrency(newSelection.first),
            )),
          ]),
        ],
      ]),
    );
  }

  Widget _buildItemsSummaryList(AddPurchaseController controller) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 180),
      child: ListView.builder(shrinkWrap: true, itemCount: controller.invoiceItems.length, itemBuilder: (context, index) {
          final item = controller.invoiceItems[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
            child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('${item.quantity} × ${item.purchasePrice.toStringAsFixed(2)}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ])),
                Text(item.subtotal.toStringAsFixed(2), style: TextStyle(fontWeight: FontWeight.bold, color: Get.theme.primaryColor)),
            ]),
          );
      }),
    );
  }

  Widget _buildPaymentModeSelection(AddPurchaseController controller) {
    return SizedBox(width: double.infinity, child: SegmentedButton<PaymentMode>(
        segments: const [
          ButtonSegment(value: PaymentMode.cash, label: Text('نقد كامل'), icon: Icon(Icons.money)),
          ButtonSegment(value: PaymentMode.credit, label: Text('آجل كامل'), icon: Icon(Icons.timer_outlined)),
          ButtonSegment(value: PaymentMode.split, label: Text('تقسيم دفعات'), icon: Icon(Icons.account_balance_wallet_outlined)),
        ],
        selected: {controller.paymentMode.value},
        onSelectionChanged: (newSelection) => controller.setPaymentMode(newSelection.first),
    ));
  }

  Widget _buildPaymentEntryCard(BuildContext context, AddPurchaseController controller, PaymentEntry entry, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2))]),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: const BorderRadius.vertical(top: Radius.circular(15))),
          child: Row(children: [
            CircleAvatar(radius: 12, backgroundColor: Get.theme.primaryColor.withOpacity(0.1), child: Text('${index + 1}', style: TextStyle(fontSize: 10, color: Get.theme.primaryColor, fontWeight: FontWeight.bold))),
            const SizedBox(width: 8),
            const Text('طريقة الدفع', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const Spacer(),
            if (controller.paymentEntries.length > 1)
              IconButton(onPressed: () => controller.removePaymentEntry(index), icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20), visualDensity: VisualDensity.compact),
          ]),
        ),
        Padding(padding: const EdgeInsets.all(12), child: Column(children: [
            Row(children: [
              Expanded(flex: 2, child: Obx(() => DropdownButtonFormField<PaymentMethod>(
                value: entry.method.value,
                decoration: const InputDecoration(labelText: 'الوسيلة', isDense: true, border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: PaymentMethod.cash, child: Text('كاش (نقد)')),
                  DropdownMenuItem(value: PaymentMethod.transfer, child: Text('حوالة مصرفية')),
                  DropdownMenuItem(value: PaymentMethod.bank, child: Text('بنك / حساب')),
                ],
                onChanged: (val) { if (val != null) entry.method.value = val; },
              ))),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: TextField(
                controller: entry.amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textDirection: TextDirection.ltr,
                readOnly: controller.paymentMode.value != PaymentMode.split,
                decoration: InputDecoration(
                  labelText: 'المبلغ', isDense: true, border: const OutlineInputBorder(),
                  suffixText: controller.isLocalCurrencyPayment.value ? Get.find<SettingsService>().localCurrency.value.symbol : Get.find<SettingsService>().primaryCurrency.value.symbol,
                ),
              )),
            ]),
            const SizedBox(height: 12),
            Obx(() {
              FundType targetType = entry.method.value == PaymentMethod.transfer ? FundType.transfer : (entry.method.value == PaymentMethod.bank ? FundType.bank : FundType.cash);
              final filteredFunds = controller.fundController.getFundsByType(targetType);
              int? selectedVal = entry.fundId.value;
              if (selectedVal != null && !filteredFunds.any((f) => f.id == selectedVal)) selectedVal = null;
              return DropdownButtonFormField<int>(
                value: selectedVal,
                decoration: const InputDecoration(labelText: 'اختيار الصندوق / الحساب المالي *', prefixIcon: Icon(Icons.account_balance_wallet_outlined), isDense: true, border: OutlineInputBorder()),
                hint: const Text('اضغط لاختيار الصندوق...'),
                items: filteredFunds.map((fund) => DropdownMenuItem<int>(value: fund.id, child: Text('${fund.displayIcon} ${fund.name}'))).toList(),
                onChanged: (val) => entry.fundId.value = val,
              );
            }),
            const SizedBox(height: 12),
            TextField(controller: entry.notesController, decoration: const InputDecoration(labelText: 'ملاحظات الدفعة (اختياري)', prefixIcon: Icon(Icons.note_alt_outlined, size: 18), isDense: true, border: OutlineInputBorder())),
            Obx(() {
              if (entry.method.value == PaymentMethod.transfer) return _buildTransferFields(controller, entry);
              if (entry.method.value == PaymentMethod.bank) return _buildBankFields(controller, entry);
              return const SizedBox.shrink();
            }),
        ])),
      ]),
    );
  }

  Widget _buildTransferFields(AddPurchaseController controller, PaymentEntry entry) {
    return Column(children: [
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: TextField(controller: entry.transferNoController, decoration: const InputDecoration(labelText: 'رقم الحوالة *', isDense: true, border: OutlineInputBorder(), prefixIcon: Icon(Icons.numbers, size: 18)))),
        const SizedBox(width: 10),
        Expanded(child: TextField(controller: entry.senderNameController, decoration: const InputDecoration(labelText: 'اسم المرسل', isDense: true, border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_outline, size: 18)))),
      ]),
      const SizedBox(height: 10),
      TextField(controller: entry.transferCompanyController, decoration: const InputDecoration(labelText: 'شركة التحويل', isDense: true, border: OutlineInputBorder(), prefixIcon: Icon(Icons.business_outlined, size: 18))),
      const SizedBox(height: 10),
      _buildImagePickerRow('صورة السند', entry.transferImagePath, () => controller.pickEntryImage(entry, true)),
    ]);
  }

  Widget _buildBankFields(AddPurchaseController controller, PaymentEntry entry) {
    return Column(children: [
      const SizedBox(height: 12),
      TextField(controller: entry.bankNameController, decoration: const InputDecoration(labelText: 'اسم البنك', isDense: true, border: OutlineInputBorder(), prefixIcon: Icon(Icons.account_balance_outlined, size: 18))),
      const SizedBox(height: 10),
      TextField(controller: entry.bankReferenceController, decoration: const InputDecoration(labelText: 'الرقم المرجعي *', isDense: true, border: OutlineInputBorder(), prefixIcon: Icon(Icons.confirmation_number_outlined, size: 18))),
      const SizedBox(height: 10),
      _buildImagePickerRow('صورة السند البنكي', entry.bankImagePath, () => controller.pickEntryImage(entry, false)),
    ]);
  }

  Widget _buildImagePickerRow(String label, RxnString imagePath, VoidCallback onTap) {
    return Obx(() => InkWell(onTap: onTap, child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade100)),
        child: Row(children: [
          Icon(imagePath.value == null ? Icons.camera_alt_outlined : Icons.check_circle, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Text(imagePath.value == null ? label : 'تم اختيار الصورة', style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
          const Spacer(),
          if (imagePath.value != null) const Icon(Icons.edit, size: 16, color: Colors.blue),
        ]),
    )));
  }

  Widget _buildBalanceIndicator(AddPurchaseController controller) {
    final remaining = controller.remainingAmount;
    final isDone = remaining.abs() < 0.01;
    final isOverflow = remaining < -0.01;
    final color = isDone ? Colors.green : (isOverflow ? Colors.orange : Colors.red);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))),
      child: Row(children: [
        Icon(isDone ? Icons.check_circle : (isOverflow ? Icons.info_outline : Icons.warning_amber_rounded), color: color),
        const SizedBox(width: 12),
        Expanded(child: Text(isDone ? 'تم تغطية كامل مبلغ الفاتورة' : (isOverflow ? 'المبلغ المدفوع يتجاوز الإجمالي' : 'المبلغ المتبقي كدين: ${remaining.toStringAsFixed(2)}'), style: TextStyle(color: color, fontWeight: FontWeight.bold))),
      ]),
    );
  }

  Widget _buildFullCreditWarning() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.red.shade100)),
      child: Column(children: [
        Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 40),
        const SizedBox(height: 12),
        const Text('سيتم تسجيل كامل المبلغ كدين للمورد', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
      ]),
    );
  }

}
