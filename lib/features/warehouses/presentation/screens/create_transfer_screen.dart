// File: lib/features/warehouses/presentation/screens/create_transfer_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:get/get.dart';
import '../../../categories/data/models/category_model.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/presentation/controllers/product_controller.dart';
import '../../data/models/warehouse_model.dart';
import '../controllers/warehouse_controller.dart';
import '../controllers/inventory_transfer_controller.dart';

class CreateTransferScreen extends StatefulWidget {
  const CreateTransferScreen({super.key});

  @override
  State<CreateTransferScreen> createState() => _CreateTransferScreenState();
}

class _CreateTransferScreenState extends State<CreateTransferScreen> {
  final _searchController = TextEditingController();
  late final InventoryTransferController _transferController;
  late final WarehouseController _warehouseController;
  late final ProductController _productController;

  @override
  void initState() {
    super.initState();
    _warehouseController = Get.find<WarehouseController>();
    _productController = Get.find<ProductController>();

    if (!Get.isRegistered<InventoryTransferController>()) {
      Get.put(InventoryTransferController());
    }
    _transferController = Get.find<InventoryTransferController>();

    final main = _warehouseController.mainWarehouse;
    if (main != null) {
      _transferController.sourceWarehouse.value = main;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('سند تحويل مخزني (عُهدة)'),
      ),
      body: Column(
        children: [
          // القسم العلوي الثابت (مخازن وبحث)
          _buildTopSection(theme),
          
          // قائمة الأصناف (قابلة للتمرير)
          Expanded(
            child: Obx(() {
              final cart = _transferController.cartItems;
              if (cart.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_shopping_cart, size: 60, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text('ابحث عن منتجات وأضفها للسند',
                          style: TextStyle(color: Colors.grey.shade500)),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: cart.length,
                itemBuilder: (context, index) {
                  final item = cart[index];
                  return _buildCartItem(item, theme);
                },
              );
            }),
          ),
        ],
      ),
      bottomNavigationBar: Obx(() {
        if (_transferController.cartItems.isEmpty) return const SizedBox.shrink();
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _transferController.notesController,
                  decoration: InputDecoration(
                    labelText: 'ملاحظات (اختياري)',
                    prefixIcon: const Icon(Icons.note),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    isDense: true,
                  ),
                  maxLines: 1,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('الأصناف: ${_transferController.totalItems}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'قيمة العهدة (بيع): ${_transferController.totalSaleValue.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                        Text(
                          'التكلفة: ${_transferController.totalCostValue.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _transferController.isSaving.value
                        ? null
                        : _transferController.executeTransfer,
                    icon: _transferController.isSaving.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(_transferController.isSaving.value
                        ? 'جاري التنفيذ...'
                        : 'تأكيد وتسليم العُهدة'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTopSection(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // المصدر (ثابت) والوجهة
        Container(
          padding: const EdgeInsets.all(16),
          color: theme.primaryColor.withOpacity(0.03),
          child: Column(
            children: [
              // المخزن المصدر (ثابت)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warehouse_rounded, color: Colors.red),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('من المخزن (المصدر)', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          Text('المخزن الرئيسي (الإدارة)', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Icon(Icons.lock_outline_rounded, size: 16, color: Colors.grey.shade400),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Icon(Icons.arrow_downward_rounded, color: Colors.grey.shade400, size: 20),
              const SizedBox(height: 8),
              // المخزن الوجهة
              Obx(() => _buildWarehouseDropdown(
                label: 'إلى المخزن (الوجهة - مندوب المبيعات)',
                icon: Icons.local_shipping_rounded,
                color: Colors.green,
                selectedWarehouse: _transferController.destinationWarehouse.value,
                warehouses: _warehouseController.activeWarehouses
                    .where((w) => !w.isMain) // فقط المخازن الفرعية
                    .toList(),
                onChanged: (w) => _transferController.destinationWarehouse.value = w,
              )),
            ],
          ),
        ),
        _buildMagicSearchBar(context, theme),
      ],
    );
  }

  Widget _buildMagicSearchBar(BuildContext context, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
        final selectedCat = _transferController.selectedSearchCategory.value;

        return TypeAheadField<Object>(
          key: ValueKey('transfer_search_${selectedCat ?? "root"}'),
          controller: _transferController.productSearchController,
          suggestionsCallback: (pattern) async {
            if (selectedCat == null) {
              return _transferController.categoryController.categories.where((cat) {
                return cat.name.toLowerCase().contains(pattern.toLowerCase());
              }).toList();
            } else {
              return _productController.allProducts.where((product) {
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
                          Text(suggestion.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          if (suggestion.code != null)
                            Text(suggestion.code!, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        ],
                      ),
                    ),
                    Text(
                      suggestion.salePrice.toStringAsFixed(2),
                      style: TextStyle(fontWeight: FontWeight.bold, color: theme.primaryColor),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
          onSelected: (suggestion) {
            if (suggestion is CategoryModel) {
              _transferController.selectedSearchCategory.value = suggestion.name;
              _transferController.productSearchController.clear();
            } else if (suggestion is ProductModel) {
              _transferController.productSearchController.clear();
              _showQuantitySheet(suggestion);
            }
          },
          builder: (context, textEditingController, focusNode) {
            return TextField(
              controller: _transferController.productSearchController,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: _transferController.selectedSearchCategory.value == null
                    ? 'ابحث بالقسم أو اختر من القائمة...'
                    : 'ابحث في قسم ${_transferController.selectedSearchCategory.value}...',
                prefixIcon: (_transferController.selectedSearchCategory.value != null)
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ActionChip(
                          avatar: const Icon(Icons.folder_rounded, size: 16, color: Colors.white),
                          label: Text(
                            _transferController.selectedSearchCategory.value!,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          backgroundColor: Colors.orange,
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            _transferController.selectedSearchCategory.value = null;
                            _transferController.productSearchController.clear();
                          },
                        ),
                      )
                    : Icon(Icons.search_rounded, color: theme.primaryColor),
                suffixIcon: (_transferController.productSearchController.text.isNotEmpty || _transferController.selectedSearchCategory.value != null)
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _transferController.productSearchController.clear();
                          _transferController.selectedSearchCategory.value = null;
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildWarehouseDropdown({
    required String label,
    required IconData icon,
    required Color color,
    required WarehouseModel? selectedWarehouse,
    required List<WarehouseModel> warehouses,
    required ValueChanged<WarehouseModel?> onChanged,
  }) {
    return DropdownButtonFormField<int>(
      value: selectedWarehouse?.id,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: color),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
      ),
      items: warehouses.map((w) {
        return DropdownMenuItem<int>(
          value: w.id,
          child: Text(w.name),
        );
      }).toList(),
      onChanged: (id) {
        final selected = warehouses.firstWhereOrNull((w) => w.id == id);
        onChanged(selected);
      },
    );
  }

  Widget _buildCartItem(TransferCartItem item, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.inventory_2_outlined, color: theme.primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${item.quantity} ${item.unitName}',
                        style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'المجموع: ${item.totalSaleValue.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _transferController.removeFromCart(item.product.id!),
          ),
        ],
      ),
    );
  }

  void _showQuantitySheet(ProductModel product) {
    // حالة محلية لإدارة الكمية والوحدة داخل الـ BottomSheet
    final RxDouble quantity = 1.0.obs;
    final RxInt selectedUnitId = (product.unitId!).obs;
    final qtyController = TextEditingController(text: '1.0');

    // جلب الوحدات المسموحة لهذا المنتج وترتيبها من الأكبر للأصغر تلقائياً
    final List<int> allowedUnitIds = [];
    if (product.unitId != null) {
      // getUnitLevels يجلب ترتيب الشجرة من الأب إلى الأبناء (مثلاً كرتون -> باكت -> حبة) كـ UnitModel
      final levels = _transferController.unitController.getUnitLevels(product.unitId!);
      allowedUnitIds.addAll(levels.where((u) => (product.allowedUnits?.contains(u.id) ?? false) || u.id == product.unitId).map((u) => u.id!));
    }
    
    // إذا لم تكن هناك وحدات مخصصة، نستخدم الوحدة الافتراضية
    if (allowedUnitIds.isEmpty && product.unitId != null) {
      allowedUnitIds.add(product.unitId!);
    }

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

                // العنوان 
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
                  ],
                ),
                const SizedBox(height: 15),

                // اختيار الوحدة بأسلوب Chips
                const Text('اختر الوحدة للتسليم:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 12),
                Obx(() {
                  final uc = _transferController.unitController;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    children: allowedUnitIds.map((id) {
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
                    final uc = _transferController.unitController;
                    final currentUnit = uc.allUnits.firstWhereOrNull((u) => u.id == selectedUnitId.value);
                    if (currentUnit == null) return const SizedBox.shrink();
                    
                    String convertInfo = '';
                    if (currentUnit.childUnitId != null) {
                      final child = uc.allUnits.firstWhereOrNull((u) => u.id == currentUnit.childUnitId);
                      if (child != null) convertInfo = '1 ${currentUnit.name} = ${currentUnit.conversionFactor.toInt()} ${child.name}';
                    } else {
                      convertInfo = 'أصغر وحدة متوفرة';
                    }

                    final factor = _transferController.calculateConversionFactor(product, selectedUnitId.value);
                    final availablePrimary = _transferController.getAvailableQuantity(product);
                    
                    // الرصيد الأساسي (مثلاً 1 كرتون) نضربه في المعامل (مثلاً 6 بواكت للكرتون)
                    final stockInUnit = availablePrimary * factor;
                    final bool isOverStock = quantity.value > (stockInUnit + 0.0001);

                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.sync_alt_rounded, color: Colors.blue, size: 20),
                                const SizedBox(width: 8),
                                const Text('التحويل:', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Text(convertInfo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.inventory_2_outlined, color: isOverStock ? Colors.red : Colors.green, size: 20),
                                const SizedBox(width: 8),
                                const Text('المتوفر بالمخزون:', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Text(
                              '${stockInUnit.toStringAsFixed(stockInUnit == stockInUnit.toInt() ? 0 : 2)} ${currentUnit.name}', 
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isOverStock ? Colors.red : Colors.green),
                            ),
                          ],
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
                const Text('الكمية المراد تسليمها:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        if (quantity.value > 1) {
                          quantity.value--;
                          qtyController.text = quantity.value.toStringAsFixed(0);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Icon(Icons.remove_rounded, color: Colors.red.shade700),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: TextField(
                          controller: qtyController,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Get.theme.primaryColor, width: 2)),
                          ),
                          onChanged: (val) {
                            final parsed = double.tryParse(val) ?? 0;
                            quantity.value = parsed.floorToDouble(); // ضمان رقم صحيح
                          },
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        quantity.value++;
                        qtyController.text = quantity.value.toStringAsFixed(0);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Icon(Icons.add_rounded, color: Colors.green.shade700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // زر الإضافة
                Obx(() {
                  final factor = _transferController.calculateConversionFactor(product, selectedUnitId.value);
                  final availablePrimary = _transferController.getAvailableQuantity(product);
                  final stockInUnit = availablePrimary * factor;
                  bool isOverStock = quantity.value > (stockInUnit + 0.0001);
                  bool isZero = quantity.value <= 0;

                  return SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: (isOverStock || isZero) ? null : () {
                        _transferController.addToCart(
                          product, 
                          quantity.value, 
                          unitId: selectedUnitId.value,
                          unitName: _transferController.unitController.getUnitName(selectedUnitId.value),
                          factor: factor,
                        );
                        Get.back();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: (isOverStock || isZero) ? 0 : 2,
                      ),
                      child: const Text('إضافة للسند الآن', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}
