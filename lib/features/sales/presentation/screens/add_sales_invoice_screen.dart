// File: lib/features/sales/presentation/screens/add_sales_invoice_screen.dart

import 'package:ehab_company_admin/features/customers/data/models/customer_model.dart'; // <-- 1.
import 'package:ehab_company_admin/features/sales/presentation/controllers/add_sales_invoice_controller.dart'; // <-- 1.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart'; // <-- 1. إضافة import جديد

import '../../../../core/services/settings_service.dart';
import '../../../customers/presentation/screens/add_edit_customer_screen.dart';
import '../../../products/data/models/product_model.dart';
import '../../../units/presentation/controllers/unit_controller.dart'; // <-- إضافة
import '../../../categories/data/models/category_model.dart';
import 'package:ehab_company_admin/features/fund/data/models/fund_model.dart';

class AddSalesInvoiceScreen extends StatelessWidget {
  const AddSalesInvoiceScreen({super.key});

  String _formatPrice(double price) {
    final settings = Get.find<SettingsService>();
    final primarySymbol = settings.primaryCurrency.value.symbol;
    final primaryPrice = '${price.toStringAsFixed(2)} $primarySymbol';

    if (settings.showBothCurrenciesInInvoice.value &&
        !settings.isLocalSameAsPrimary.value) {
      final localPrice = price * settings.exchangeRate.value;
      final localSymbol = settings.localCurrency.value.symbol;
      return '$primaryPrice / ${localPrice.toStringAsFixed(2)} $localSymbol';
    }
    return primaryPrice;
  }

  // دالة تنسيق السعر بناءً على خيار الدفع (للمراجعة فقط)
  String _formatReviewPrice(double priceInPrimary, bool isLocalPayment) {
    final settings = Get.find<SettingsService>();
    if (isLocalPayment) {
      final localPrice = priceInPrimary * settings.exchangeRate.value;
      return '${localPrice.toStringAsFixed(2)} ${settings.localCurrency.value.symbol}';
    } else {
      return '${priceInPrimary.toStringAsFixed(2)} ${settings.primaryCurrency.value.symbol}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final AddSalesInvoiceController controller =
        Get.find<AddSalesInvoiceController>(); // <-- 2.

    return SafeArea(
      child: Scaffold(
      appBar: AppBar(title: const Text('فاتورة مبيعات جديدة')),
      bottomNavigationBar: _buildNewFooter(context, controller),
      body: Column(
        children: [
          _buildMagicSearchBar(context, controller),

          _buildHeader(context, controller),
          const Divider(height: 1),
          Expanded(
            child: Obx(
              () => controller.invoiceItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_shopping_cart_rounded,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'الفاتورة فارغة',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'استخدم شريط البحث أعلاه لإضافة الأصناف',
                            style: TextStyle(color: Colors.grey),
                          ),
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
    ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AddSalesInvoiceController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => DropdownButtonFormField<CustomerModel>(
                    // <-- 3.
                    value: controller.selectedCustomer.value,
                    items: controller.customerController.filteredCustomers.map((
                      customer,
                    ) {
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
                        value == null ? 'الرجاء اختيار عميل' : null,
                  ),
                ),
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

  Widget _buildMagicSearchBar(BuildContext context, AddSalesInvoiceController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Obx(() {
        final selectedCat = controller.selectedSearchCategory.value; 

        return TypeAheadField<Object>(
          key: ValueKey('sales_search_${selectedCat ?? "root"}'), // إجبار المكون على إعادة التصفير عند تغيير القسم
          controller: controller.productSearchController,
          suggestionsCallback: (pattern) async {
            final selectedCategory = controller.selectedSearchCategory.value;
            
            if (selectedCategory == null) {
              return controller.categoryController.categories.where((cat) {
                return cat.name.toLowerCase().contains(pattern.toLowerCase());
              }).toList();
            } else {
              return controller.productController.allProducts.where((product) {
                final isInCategory = product.category == selectedCategory;
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
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.folder_open_rounded, color: Colors.orange),
                ),
                title: Text(suggestion.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('تصفح منتجات هذا القسم', style: TextStyle(fontSize: 12, color: Colors.grey)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
              );
            } else if (suggestion is ProductModel) {
              final bool isAvailable = suggestion.quantity > 0;
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: Row(
                  children: [
                    Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: (isAvailable ? Colors.green : Colors.red).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          suggestion.quantity.toInt().toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isAvailable ? Colors.green.shade700 : Colors.red.shade700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(suggestion.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              if (suggestion.isSalesStopped)
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.lock, color: Colors.white, size: 10),
                                      SizedBox(width: 4),
                                      Text('موقوف', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          if (suggestion.code != null)
                             Text(suggestion.code!, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        ],
                      ),
                    ),
                    Text(
                      _formatPrice(suggestion.salePrice),
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        color: suggestion.isSalesStopped ? Colors.grey : Get.theme.primaryColor,
                        decoration: suggestion.isSalesStopped ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
          onSelected: (suggestion) {
            if (suggestion is CategoryModel) {
              controller.selectedSearchCategory.value = suggestion.name;
              controller.productSearchController.clear();
            } else if (suggestion is ProductModel) {
              _showProductSelectionSheet(context, controller, suggestion);
              controller.productSearchController.clear();
            }
          },
          builder: (context, textEditingController, focusNode) {
            return TextField(
              controller: controller.productSearchController,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: controller.selectedSearchCategory.value == null 
                    ? 'ابحث بالقسم أو اختر من القائمة...' 
                    : 'ابحث في قسم ${controller.selectedSearchCategory.value}...',
                prefixIcon: (controller.selectedSearchCategory.value != null)
                    ? Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ActionChip(
                        avatar: const Icon(Icons.folder_rounded, size: 16, color: Colors.white),
                        label: Text(
                          controller.selectedSearchCategory.value!,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        backgroundColor: Colors.orange,
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          controller.selectedSearchCategory.value = null;
                          controller.productSearchController.clear();
                        },
                      ),
                    )
                    : Icon(Icons.search_rounded, color: Get.theme.primaryColor),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (controller.productSearchController.text.isNotEmpty || controller.selectedSearchCategory.value != null)
                      IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          controller.productSearchController.clear();
                          if (controller.selectedSearchCategory.value != null) {
                              controller.selectedSearchCategory.value = null;
                          }
                        },
                      ),
                    IconButton(
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
                          controller.productSearchController.text = code;
                        }
                      },
                      tooltip: 'بحث بالباركود',
                    ),
                  ],
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            );
          },
          emptyBuilder: (context) {
            final isCatMode = controller.selectedSearchCategory.value == null;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                isCatMode ? 'لا توجد أقسام بهذا الاسم...' : 'لم يتم العثور على منتج في هذا القسم...', 
                style: const TextStyle(color: Colors.grey)
              ),
            );
          },
        );
      }),
    );
  }

  void _showProductSelectionSheet(
    BuildContext context,
    AddSalesInvoiceController controller,
    ProductModel product, {
    SalesInvoiceItem? existingItem,
  }) {
    // حالة محلية بسيطة لإدارة الكمية والوحدة داخل الـ BottomSheet
    final RxDouble quantity = (existingItem?.quantity ?? 1.0).obs;
    final RxDouble freeQuantity = (existingItem?.freeQuantity ?? 0.0).obs;
    final RxInt selectedUnitId = (existingItem?.selectedUnitId ?? product.unitId!).obs;
    
    final qtyController = TextEditingController(text: quantity.value.toStringAsFixed(quantity.value == quantity.value.toInt() ? 0 : 2));
    final freeQtyController = TextEditingController(text: freeQuantity.value.toStringAsFixed(freeQuantity.value == freeQuantity.value.toInt() ? 0 : 2));

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2)],
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // اسحب لأسفل (Handle)
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                ),
              ),

              // العنوان والسعر
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(product.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            if (product.isSalesStopped)
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                                child: const Text('موقوف', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                        if (product.code != null)
                          Text('كود: ${product.code}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: (product.isSalesStopped ? Colors.grey : Get.theme.primaryColor).withOpacity(0.1), 
                      borderRadius: BorderRadius.circular(12)
                    ),
                    child: Obx(() {
                      final price = controller.calculatePriceForUnit(product, selectedUnitId.value);
                      return Text(
                        _formatPrice(price),
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 18, 
                          color: product.isSalesStopped ? Colors.grey : Get.theme.primaryColor,
                          decoration: product.isSalesStopped ? TextDecoration.lineThrough : null,
                        ),
                      );
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // تنبيه إيقاف البيع
              if (product.isSalesStopped)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'عذراً، هذا المنتج موقف من البيع حالياً من قبل الإدارة.',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 10),

              // اختيار الوحدة بأسلوب Chips
              const Text('اختر وحدة البيع:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),
              Obx(() {
                final uc = Get.find<UnitController>();
                final allowedIds = controller.getAllowedUnitIds(product);
                return Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: allowedIds.map((id) {
                    final unit = uc.allUnits.firstWhereOrNull((u) => u.id == id);
                    if (unit == null) return const SizedBox.shrink();
                    final isSelected = selectedUnitId.value == id;
                    return ChoiceChip(
                      label: Text(unit.name, style: TextStyle(color: isSelected ? Colors.white : Colors.black87)),
                      selected: isSelected,
                      onSelected: (val) => selectedUnitId.value = id,
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

              // معلومات التحويل والمخزون
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Obx(() {
                  final uc = Get.find<UnitController>();
                  final currentUnit = uc.allUnits.firstWhereOrNull((u) => u.id == selectedUnitId.value);
                  if (currentUnit == null) return const SizedBox.shrink();
                  
                  String convertInfo = '';
                  if (currentUnit.childUnitId != null) {
                    final child = uc.allUnits.firstWhereOrNull((u) => u.id == currentUnit.childUnitId);
                    if (child != null) convertInfo = '1 ${currentUnit.name} = ${currentUnit.conversionFactor.toInt()} ${child.name}';
                  } else {
                    convertInfo = 'أصغر وحدة متوفرة';
                  }

                  final factor = controller.calculateConversionFactor(product, selectedUnitId.value);
                  // استخدام الكمية المتوفرة الحقيقية (المخصوم منها ما في الفاتورة مسبقاً)
                  final availablePrimary = controller.getAvailableQuantity(product);
                  
                  // إذا كان هذا العنصر موجوداً بالفعل في الفاتورة وبنفس الوحدة، نضيف كميته الحالية للرصيد المتاح لهذا الحوار فقط (لأنه سيتم استبداله)
                  double adjustedAvailablePrimary = availablePrimary;
                  if (existingItem != null) {
                    final existingFactor = controller.calculateConversionFactor(product, existingItem.selectedUnitId ?? product.unitId!);
                    adjustedAvailablePrimary += existingItem.quantity / (existingFactor > 0 ? existingFactor : 1.0);
                  }

                  final stockInUnit = adjustedAvailablePrimary * factor;
                  final bool isOverStock = (quantity.value + freeQuantity.value) > (stockInUnit + 0.0001);

                  return Column(
                    children: [
                      _buildDetailRow(Icons.sync_alt_rounded, 'التحويل:', convertInfo, Colors.blue),
                      const Divider(height: 20),
                      _buildDetailRow(
                        Icons.inventory_2_outlined, 
                        'المتوفر بالمخزون:', 
                        '${stockInUnit.toStringAsFixed(stockInUnit == stockInUnit.toInt() ? 0 : 2)} ${currentUnit.name}', 
                        isOverStock ? Colors.red : Colors.green
                      ),
                      if (isOverStock)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'الكمية المطلوبة تتجاوز المتاح حالياً!',
                            style: TextStyle(color: Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  );
                }),
              ),
              const SizedBox(height: 25),

              // التحكم في الكمية
              const Text('الكمية المطلوبة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildIconButton(Icons.remove_rounded, product.isSalesStopped ? null : () {
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
                        enabled: !product.isSalesStopped, 
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: TextStyle(
                          fontSize: 22, 
                          fontWeight: FontWeight.bold,
                          color: product.isSalesStopped ? Colors.grey : Colors.black,
                        ),
                        decoration: InputDecoration(
                          hintText: '1',
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade300)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade200)),
                        ),
                        onChanged: (v) => quantity.value = double.tryParse(v) ?? 0.0,
                      ),
                    ),
                  ),
                  _buildIconButton(Icons.add_rounded, product.isSalesStopped ? null : () {
                    quantity.value++;
                    qtyController.text = quantity.value.toStringAsFixed(0);
                  }),
                ],
              ),
              const SizedBox(height: 20),

              // التحكم في الكمية المجانية
              Row(
                children: [
                   Icon(Icons.card_giftcard_rounded, size: 18, color: Colors.orange.shade700),
                   const SizedBox(width: 8),
                   Text('الكمية المجانية (اختياري):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.orange.shade900)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildIconButton(Icons.remove_rounded, product.isSalesStopped ? null : () {
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
                        enabled: !product.isSalesStopped,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: TextStyle(
                          fontSize: 20, 
                          fontWeight: FontWeight.bold,
                          color: product.isSalesStopped ? Colors.grey : Colors.orange.shade900,
                        ),
                        decoration: InputDecoration(
                          hintText: '0',
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.orange.shade200)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.orange.shade100)),
                        ),
                        onChanged: (v) => freeQuantity.value = double.tryParse(v) ?? 0.0,
                      ),
                    ),
                  ),
                  _buildIconButton(Icons.add_rounded, product.isSalesStopped ? null : () {
                    freeQuantity.value++;
                    freeQtyController.text = freeQuantity.value.toStringAsFixed(0);
                  }, color: Colors.orange),
                ],
              ),
              const SizedBox(height: 35),

              // زر الإضافة النهائي
              Obx(() {
                final price = controller.calculatePriceForUnit(product, selectedUnitId.value);
                final total = quantity.value * price;
                final isUpdate = existingItem != null;
                
                final factor = controller.calculateConversionFactor(product, selectedUnitId.value);
                final availablePrimary = controller.getAvailableQuantity(product);
                
                // تعديل الرصيد المتاح عند التحديث (نفس المنطق أعلاه)
                double adjustedAvailablePrimary = availablePrimary;
                if (existingItem != null) {
                   final existingFactor = controller.calculateConversionFactor(product, existingItem.selectedUnitId ?? product.unitId!);
                   adjustedAvailablePrimary += existingItem.quantity / (existingFactor > 0 ? existingFactor : 1.0);
                }

                final stockInUnit = adjustedAvailablePrimary * factor;
                final bool isOverStock = quantity.value > (stockInUnit + 0.0001);
                final bool isStopped = product.isSalesStopped;

                return ElevatedButton(
                  onPressed: (isOverStock || isStopped) ? (isStopped ? null : () {
                    Get.snackbar('خطأ', 'إجمالي الكمية المطلوبة (بيع + مجانية) غير متوفرة بالمخزون!', backgroundColor: Colors.red.withOpacity(0.1), colorText: Colors.red);
                  }) : () {
                    if (isUpdate) {
                       controller.updateItemDetails(product.id!, newQuantity: quantity.value, newFreeQuantity: freeQuantity.value, newUnitId: selectedUnitId.value);
                    } else {
                       controller.addProductToInvoice(product, quantity.value, freeQuantity: freeQuantity.value, unitId: selectedUnitId.value);
                    }
                    Get.back();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (isOverStock || isStopped) ? Colors.grey : Get.theme.primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: (isOverStock || isStopped) ? 0 : 5,
                    shadowColor: Get.theme.primaryColor.withOpacity(0.4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(isStopped 
                          ? Icons.block 
                          : (isUpdate ? Icons.check_circle_outline : (isOverStock ? Icons.warning_amber_rounded : Icons.add_shopping_cart_rounded))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            isStopped
                              ? 'المنتج موقف من البيع من قبل الإدارة'
                              : (isOverStock 
                                  ? 'الكمية غير متوفرة بالمخزون'
                                  : '${isUpdate ? 'تحديث البيانات' : 'إضافة للفاتورة'} (الإجمالي: ${total.toStringAsFixed(2)})'),
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback? onTap, {Color? color}) {
    final bool isDisabled = onTap == null;
    final primaryColor = color ?? Get.theme.primaryColor;
    return Material(
      color: isDisabled ? Colors.grey.shade100 : primaryColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon, 
            color: isDisabled ? Colors.grey : primaryColor, 
            size: 28
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
        const Spacer(),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
      ],
    );
  }

  void _showEditItemDialog(
    BuildContext context,
    AddSalesInvoiceController controller,
    SalesInvoiceItem item,
  ) {
    _showProductSelectionSheet(context, controller, item.product, existingItem: item);
  }

  Widget _buildNewFooter(
    BuildContext context,
    AddSalesInvoiceController controller,
  ) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).canvasColor,
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
              child: Obx(
                () => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الإجمالي: ${_formatPrice(controller.grandTotal)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Get.theme.primaryColor,
                      ),
                    ),
                    Text(
                      'عدد الأصناف: ${controller.invoiceItems.length} | إجمالي الكمية: ${controller.totalItemsCount}',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
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
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReviewBottomSheet(
    BuildContext context,
    AddSalesInvoiceController controller,
  ) {
    controller.updateTotals(); // حساب الإجماليات أولاً

    Get.bottomSheet(
      isScrollControlled: true, // للسماح للواجهة بأخذ ارتفاع الشاشة
      ignoreSafeArea: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      Container(
        height:
            MediaQuery.of(context).size.height * 0.9, // 90% من ارتفاع الشاشة
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. هيدر الـ BottomSheet
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'مراجعة وحفظ الفاتورة',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                  // خيار تبديل العملة (يظهر فقط إذا كان الإعداد مفعلاً)
                  Obx(() {
                    final settings = Get.find<SettingsService>();
                    if (!settings.showBothCurrenciesInInvoice.value ||
                        settings.isLocalSameAsPrimary.value) {
                      return const SizedBox.shrink();
                    }
                    return Container(
                      margin: const EdgeInsets.only(top: 10),
                      width: double.infinity,
                      child: SegmentedButton<bool>(
                        segments: [
                          ButtonSegment(
                            value: false,
                            label: Text(
                              'دفع بالعملة الأساسية (${settings.primaryCurrency.value.symbol})',
                            ),
                          ),
                          ButtonSegment(
                            value: true,
                            label: Text(
                              'دفع بالعملة المحلية (${settings.localCurrency.value.symbol})',
                            ),
                          ),
                        ],
                        selected: {controller.isLocalCurrencyPayment.value},
                        onSelectionChanged: (newSelection) {
                          controller.togglePaymentCurrency(newSelection.first);
                        },
                      ),
                    );
                  }),
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
                  _buildPaymentSection(context, controller),
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
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
        const Text(
          'ملخص الأصناف',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
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
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('الوحدة: ${Get.find<UnitController>().getUnitName(item.selectedUnitId)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        Text('كمية: ${item.quantity.toInt()}', style: const TextStyle(fontSize: 11)),
                        Text('مجاني: ${item.freeQuantity.toInt()}', style: const TextStyle(fontSize: 11, color: Colors.orange)),
                        Text('سعر: ${_formatReviewPrice(item.salePrice, controller.isLocalCurrencyPayment.value)}', style: const TextStyle(fontSize: 11)),
                        Text('إجمالي: ${_formatReviewPrice(item.subtotal, controller.isLocalCurrencyPayment.value)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
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
        Obx(
          () => SegmentedButton<DiscountType>(
            segments: const [
              ButtonSegment(
                value: DiscountType.amount,
                label: Text('خصم مبلغ'),
              ),
              ButtonSegment(
                value: DiscountType.percentage,
                label: Text('خصم نسبة %'),
              ),
            ],
            selected: {controller.discountType.value},
            onSelectionChanged: (newSelection) {
              controller.discountType.value = newSelection.first;
              controller.updateTotals();
            },
          ),
        ),
        const SizedBox(height: 12),
        Obx(
          () => TextField(
            controller: controller.discountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(
              labelText: controller.discountType.value == DiscountType.amount
                  ? 'قيمة الخصم'
                  : 'نسبة الخصم %',
              border: const OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }

  // ودجت بناء قسم الدفع المطور
  Widget _buildPaymentSection(BuildContext context, AddSalesInvoiceController controller) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. خلاصة الأرقام النهائية
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Get.theme.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Get.theme.primaryColor.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                _buildDialogInfoRow(
                  'الإجمالي الفرعي:',
                  _formatReviewPrice(controller.subtotal, controller.isLocalCurrencyPayment.value),
                ),
                _buildDialogInfoRow(
                  'قيمة الخصم:',
                  '- ${_formatReviewPrice(controller.discountValue.value, controller.isLocalCurrencyPayment.value)}',
                  valueColor: Colors.red,
                ),
                const Divider(height: 20),
                _buildDialogInfoRow(
                  'الإجمالي النهائي:',
                  _formatReviewPrice(controller.grandTotal, controller.isLocalCurrencyPayment.value),
                  isBold: true,
                  fontSize: 18,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 2. اختيار وضع الفاتورة (نقد، آجل، مشترك)
          const Text(
            'حالة الفاتورة:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<PaymentMode>(
              segments: const [
                ButtonSegment(value: PaymentMode.cash, label: Text('نقد كامل'), icon: Icon(Icons.money)),
                ButtonSegment(value: PaymentMode.credit, label: Text('آجل كامل'), icon: Icon(Icons.timer_outlined)),
                ButtonSegment(value: PaymentMode.split, label: Text('تقسيم دفعات'), icon: Icon(Icons.account_balance_wallet_outlined)),
              ],
              selected: {controller.paymentMode.value},
              onSelectionChanged: (newSelection) {
                controller.setPaymentMode(newSelection.first);
              },
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 3. قائمة المدفوعات التفصيلية
          if (controller.paymentMode.value != PaymentMode.credit) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'تفاصيل سداد المبالغ:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                if (controller.paymentMode.value == PaymentMode.split)
                  TextButton.icon(
                    onPressed: controller.addPaymentEntry,
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    label: const Text('إضافة طريقة دفع'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            
            // عرض بطاقات الدفع
            ...controller.paymentEntries.asMap().entries.map((entry) {
              return _buildPaymentEntryCard(context, controller, entry.value, entry.key);
            }).toList(),
            
            const SizedBox(height: 16),
            
            // مؤشر السداد
            _buildBalanceIndicator(controller),
          ] else ...[
             // في حالة الآجل الكامل
             Container(
               width: double.infinity,
               padding: const EdgeInsets.all(20),
               decoration: BoxDecoration(
                 color: Colors.red.shade50,
                 borderRadius: BorderRadius.circular(15),
                 border: Border.all(color: Colors.red.shade100),
               ),
               child: Column(
                 children: [
                   Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 40),
                   const SizedBox(height: 12),
                   const Text(
                     'سيتم تسجيل كامل المبلغ كدين على حساب العميل',
                     textAlign: TextAlign.center,
                     style: TextStyle(fontWeight: FontWeight.bold),
                   ),
                 ],
               ),
             ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPaymentEntryCard(BuildContext context, AddSalesInvoiceController controller, PaymentEntry entry, int index) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            // هيدر البطاقة
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Get.theme.primaryColor.withOpacity(0.1),
                    child: Text('${index + 1}', style: TextStyle(fontSize: 10, color: Get.theme.primaryColor, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  const Text('طريقة الدفع', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const Spacer(),
                  if (controller.paymentEntries.length > 1)
                    IconButton(
                        onPressed: () => controller.removePaymentEntry(index),
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                        visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // اختيار الطريقة والمبلغ
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Obx(() => DropdownButtonFormField<PaymentMethod>(
                          value: entry.method.value,
                          decoration: const InputDecoration(
                            labelText: 'الوسيلة',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: PaymentMethod.cash, child: Text('كاش (نقد)')),
                            DropdownMenuItem(value: PaymentMethod.transfer, child: Text('حوالة مصرفية')),
                            DropdownMenuItem(value: PaymentMethod.bank, child: Text('بنك / مسبق')),
                          ],
                          onChanged: (val) {
                            if (val != null) entry.method.value = val;
                          },
                        )),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: entry.amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textDirection: TextDirection.ltr,
                          readOnly: controller.paymentMode.value != PaymentMode.split,
                          decoration: InputDecoration(
                            labelText: 'المبلغ',
                            isDense: true,
                            border: const OutlineInputBorder(),
                            suffixText: controller.isLocalCurrencyPayment.value 
                                ? Get.find<SettingsService>().localCurrency.value.symbol 
                                : Get.find<SettingsService>().primaryCurrency.value.symbol,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // اختيار الصندوق المفلتر (جديد)
                  Obx(() {
                    FundType targetType = FundType.cash;
                    if (entry.method.value == PaymentMethod.transfer) targetType = FundType.transfer;
                    else if (entry.method.value == PaymentMethod.bank) targetType = FundType.bank;

                    final filteredFunds = controller.fundController.getFundsByType(targetType);
                    
                    // فحص أمان: إذا كانت القيمة المختارة غير موجودة في القائمة المفلترة، اجعلها null لمنع الخطأ
                    int? selectedVal = entry.fundId.value;
                    if (selectedVal != null && !filteredFunds.any((f) => f.id == selectedVal)) {
                        selectedVal = null;
                    }

                    return DropdownButtonFormField<int>(
                      value: selectedVal,
                      decoration: const InputDecoration(
                        labelText: 'اختيار الصندوق / الحساب المالي *',
                        prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('اضغط لاختيار الصندوق...'),
                      items: filteredFunds.map((fund) {
                        return DropdownMenuItem<int>(
                          value: fund.id,
                          child: Text('${fund.displayIcon} ${fund.name}'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        entry.fundId.value = val;
                      },
                    );
                  }),
                  const SizedBox(height: 12),
                  
                  // حقل الملاحظات العامة للدفعة (جديد)
                  TextField(
                    controller: entry.notesController,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظات الدفعة (اختياري)',
                      prefixIcon: Icon(Icons.note_alt_outlined, size: 18),
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  
                  // الحقول الديناميكية بناءً على الطريقة المختارة
                  Obx(() {
                    if (entry.method.value == PaymentMethod.transfer) {
                       return _buildTransferFields(controller, entry);
                    } else if (entry.method.value == PaymentMethod.bank) {
                       return _buildBankFields(controller, entry);
                    }
                    return const SizedBox.shrink();
                  }),
                ],
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildTransferFields(AddSalesInvoiceController controller, PaymentEntry entry) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: entry.transferNoController,
                decoration: const InputDecoration(
                  labelText: 'رقم الحوالة *',
                  isDense: true,
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers, size: 18),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: entry.senderNameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المرسل',
                  isDense: true,
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline, size: 18),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: entry.transferCompanyController,
          decoration: const InputDecoration(
            labelText: 'اسم شركة التحويل',
            isDense: true,
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.business_outlined, size: 18),
          ),
        ),
        const SizedBox(height: 10),
        _buildImagePickerRow(
          'صورة الحوالة / السند', 
          entry.transferImagePath, 
          () => controller.pickEntryImage(entry, true)
        ),
      ],
    );
  }

  Widget _buildBankFields(AddSalesInvoiceController controller, PaymentEntry entry) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: entry.bankNameController,
                decoration: const InputDecoration(
                  labelText: 'اسم البنك',
                  isDense: true,
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_balance_outlined, size: 18),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: entry.bankReferenceController,
                decoration: const InputDecoration(
                  labelText: 'الرقم المرجعي *',
                  isDense: true,
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.confirmation_number_outlined, size: 18),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildImagePickerRow(
          'صورة الإيداع / السند', 
          entry.bankImagePath, 
          () => controller.pickEntryImage(entry, false)
        ),
      ],
    );
  }

  Widget _buildImagePickerRow(String label, RxnString imagePath, VoidCallback onPick) {
    return Obx(() => Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.image_outlined, color: Get.theme.primaryColor, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
          if (imagePath.value != null)
             const Icon(Icons.check_circle, color: Colors.green, size: 18)
          else
            TextButton(
              onPressed: onPick,
              child: const Text('التقاط صورة', style: TextStyle(fontSize: 12)),
            ),
          if (imagePath.value != null)
            IconButton(
              onPressed: () => imagePath.value = null,
              icon: const Icon(Icons.delete_forever, color: Colors.red, size: 18),
            ),
        ],
      ),
    ));
  }

  Widget _buildBalanceIndicator(AddSalesInvoiceController controller) {
      return Obx(() {
        final settings = Get.find<SettingsService>();
        double totalNeeded = controller.grandTotal;
        if (controller.isLocalCurrencyPayment.value) {
           totalNeeded = controller.grandTotal * settings.exchangeRate.value;
        }
        
        double totalPaid = controller.paidAmount.value;
        double remaining = totalNeeded - totalPaid;
        bool isPerfect = remaining.abs() < 0.01;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isPerfect ? Colors.green.shade50 : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isPerfect ? Colors.green.shade100 : Colors.blue.shade100),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isPerfect ? 'المبلغ مغطى بالكامل' : 'المبلغ المتبقي (آجل):',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isPerfect ? Colors.green.shade700 : Colors.blue.shade700,
                ),
              ),
              Text(
                _formatBalance(remaining, controller.isLocalCurrencyPayment.value),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isPerfect ? Colors.green.shade700 : Colors.blue.shade700,
                ),
              ),
            ],
          ),
        );
      });
  }

  String _formatBalance(double amount, bool isLocal) {
    final settings = Get.find<SettingsService>();
    final symbol = isLocal ? settings.localCurrency.value.symbol : settings.primaryCurrency.value.symbol;
    return '${amount.toStringAsFixed(2)} $symbol';
  }

  Widget _buildDialogInfoRow(String label, String value, {Color? valueColor, bool isBold = false, double fontSize = 14}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontSize: fontSize,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(
    BuildContext context,
    AddSalesInvoiceController controller,
    SalesInvoiceItem item,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showEditItemDialog(context, controller, item),
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.product.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.remove_circle_outline, color: Colors.red.shade300, size: 18),
                      onPressed: () => controller.removeProductFromInvoice(item.product.id!, item.selectedUnitId!),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const Divider(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMiniBadge(Get.find<UnitController>().getUnitName(item.selectedUnitId), Colors.blue),
                    _buildSubData('كمية', item.quantity.toInt().toString()),
                    _buildSubData('مجاني', item.freeQuantity.toInt().toString(), color: Colors.orange),
                    _buildSubData('السعر', _formatPrice(item.salePrice)),
                    _buildSubData('الإجمالي', _formatPrice(item.subtotal), isBold: true, color: Get.theme.primaryColor),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSubData(String label, String value, {Color? color, bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
        Text(
          value,
          style: TextStyle(
            fontSize: 11, 
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}
