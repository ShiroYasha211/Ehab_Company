// File: lib/features/products/presentation/screens/products_screen.dart

import 'package:ehab_company_admin/features/products/data/models/product_model.dart';import 'package:ehab_company_admin/features/products/presentation/controllers/product_controller.dart';
import 'package:ehab_company_admin/features/products/presentation/widgets/product_list_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../../core/services/report_service.dart';
import 'add_edit_product_screen.dart';
import 'package:ehab_company_admin/features/products/presentation/widgets/product_grid_item.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ProductController controller = Get.find<ProductController>();
    final TextEditingController searchController = TextEditingController();

    return VisibilityDetector(
      key: const Key('products-screen-visibility-detector'),
      onVisibilityChanged: (visibilityInfo) {
        if (visibilityInfo.visibleFraction == 1.0) {
          controller.fetchAllProducts();
        }
      },
      child: Scaffold(
        // --- 1. بداية التعديل: AppBar جديد ومحسن ---
        appBar: AppBar(
          title: const Text('قائمة المنتجات'),
          actions: [
            Obx(() => IconButton(
              icon: Icon(controller.viewMode.value == ProductViewMode.list
                  ? Icons.grid_view_outlined
                  : Icons.view_list_outlined),
              onPressed: controller.toggleViewMode,
              tooltip: 'تغيير طريقة العرض',
            )),
            // زر طباعة التقرير
            IconButton(
              icon: const Icon(Icons.print_outlined),
              onPressed: () {
                ReportService.printInventoryReport(controller.filteredProducts);
              },
              tooltip: 'طباعة تقرير الجرد',
            ),
            // زر خيارات الفرز
            _buildSortMenu(controller),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(120.0), // زيادة الارتفاع
            child: Column(
              children: [
                _buildSearchBar(searchController, controller),
                _buildExpiryFilter(controller),
              ],
            ),
          ),
        ),
        // --- نهاية التعديل ---
        body: SafeArea(
          child: Obx(() {
            if (controller.isLoading.isTrue) {
              return const Center(child: CircularProgressIndicator());
            }
          
            if (controller.filteredProducts.isEmpty && (controller.searchQuery.value.isNotEmpty || controller.expiryFilter.value != ExpiryFilterOption.all)) {
              return _buildEmptyState(
                icon: Icons.search_off,
                title: 'لا توجد منتجات تطابق بحثك أو فلترتك.',
                onClear: () {
                  searchController.clear();
                  controller.searchQuery.value = '';
                  controller.expiryFilter.value = ExpiryFilterOption.all;
                },
              );
            } else if (controller.filteredProducts.isEmpty) {
              return _buildEmptyState(
                icon: Icons.inventory_2_outlined,
                title: 'مخزونك فارغ!',
                subtitle: 'قم بإضافة منتجك الأول لتبدأ.',
              );
            }
          
            return Obx(() {
              if (controller.viewMode.value == ProductViewMode.list) {
                // عرض القائمة (نفس الكود السابق)
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: controller.filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = controller.filteredProducts[index];
                    Color? cardColor;
                    if (product.isExpired) {
                      cardColor = Colors.red.withOpacity(0.1);
                    } else if (product.isExpiringSoon) {
                      cardColor = Colors.orange.withOpacity(0.1);
                    }
                    return ProductListItem(
                      product: product,
                      cardColor: cardColor,
                      onDelete: () => _showDeleteDialog(product, controller),
                    );
                  },
                );
              } else {
                // عرض الشبكة
                return GridView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: controller.filteredProducts.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // عدد الأعمدة
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.75, // نسبة العرض إلى الارتفاع للبطاقة
                  ),
                  itemBuilder: (context, index) {
                    final product = controller.filteredProducts[index];
                    Color? cardColor;
                    if (product.isExpired) {
                      cardColor = Colors.red.withOpacity(0.1);
                    } else if (product.isExpiringSoon) {
                      cardColor = Colors.orange.withOpacity(0.1);
                    }
                    return ProductGridItem(
                      product: product,
                      cardColor: cardColor,
                    );
                  },
                );
              }
            });
          }),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Get.to(() => const AddEditProductScreen()),
          icon: const Icon(Icons.add),
          label: const Text('إضافة منتج'),
        ),
      ),
    );
  }

  // ودجت بناء شريط البحث
  Widget _buildSearchBar(TextEditingController searchController, ProductController controller) {
    Future<void> scanBarcode() async {
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
        searchController.text = code;
        controller.searchQuery.value = code;
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: TextField(
        controller: searchController,
        onChanged: (value) => controller.searchQuery.value = value,
        decoration: InputDecoration(
          hintText: 'ابحث بالاسم أو الباركود...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          isDense: true,
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(() => controller.searchQuery.value.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  searchController.clear();
                  controller.searchQuery.value = '';
                },
              )
                  : const SizedBox.shrink()),
              IconButton(
                icon: const Icon(Icons.qr_code_scanner_rounded),
                onPressed: scanBarcode,
                tooltip: 'بحث بالباركود',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ودجت بناء قائمة الفرز
  Widget _buildSortMenu(ProductController controller) {
    return PopupMenuButton<ProductSortOption>(
      icon: const Icon(Icons.sort),
      tooltip: 'ترتيب حسب',
      onSelected: (option) {
        controller.sortOption.value = option;
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: ProductSortOption.newest,
          child: Text('الأحدث أولاً'),
        ),
        const PopupMenuItem(
          value: ProductSortOption.oldest,
          child: Text('الأقدم أولاً'),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: ProductSortOption.nameAsc,
          child: Text('الاسم (أ - ي)'),
        ),
        const PopupMenuItem(
          value: ProductSortOption.nameDesc,
          child: Text('الاسم (ي - أ)'),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: ProductSortOption.quantityDesc,
          child: Text('الأكثر توفرًا'),
        ),
        const PopupMenuItem(
          value: ProductSortOption.quantityAsc,
          child: Text('الأقل توفرًا'),
        ),
      ],
    );
  }

  // ودجت بناء فلتر الصلاحية
  Widget _buildExpiryFilter(ProductController controller) {
    return Obx(() => SegmentedButton<ExpiryFilterOption>(
      segments: const [
        ButtonSegment(value: ExpiryFilterOption.all, label: Text('الكل')),
        ButtonSegment(
            value: ExpiryFilterOption.expiringSoon, label: Text('قريب الانتهاء')),
        ButtonSegment(
            value: ExpiryFilterOption.expired, label: Text('منتهي الصلاحية')),
      ],
      selected: {controller.expiryFilter.value},
      onSelectionChanged: (newSelection) {
        controller.expiryFilter.value = newSelection.first;
      },
    ));
  }

  // ودجت بناء الحالات الفارغة
  Widget _buildEmptyState({required IconData icon, required String title, String? subtitle, VoidCallback? onClear}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          ],
          if (onClear != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.filter_alt_off_outlined),
              label: const Text('إلغاء كل الفلاتر'),
            )
          ] else ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Get.to(() => const AddEditProductScreen()),
              icon: const Icon(Icons.add),
              label: const Text('إضافة منتج جديد'),
            )
          ]
        ],
      ),
    );
  }

  // دالة ديالوج الحذف
  void _showDeleteDialog(ProductModel product, ProductController controller) {
    Get.defaultDialog(
      title: 'تأكيد الحذف',
      middleText: 'هل أنت متأكد من رغبتك في حذف المنتج "${product.name}"؟',
      textConfirm: 'حذف',
      textCancel: 'إلغاء',
      confirmTextColor: Colors.white,
      onConfirm: () {
        controller.deleteProduct(product.id!);
        Get.back();
      },
    );
  }
}
