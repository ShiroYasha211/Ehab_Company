// File: lib/features/products/presentation/screens/products_screen.dart

import 'package:ehab_company_admin/features/products/presentation/controllers/product_controller.dart';
import 'package:ehab_company_admin/features/products/presentation/widgets/product_list_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart'; // <-- إضافة جديدة
import 'package:visibility_detector/visibility_detector.dart';

import '../../../../core/services/report_service.dart';
import 'add_edit_product_screen.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get.find() سيعمل بشكل صحيح لأن الكنترولر تم إنشاؤه في شاشة لوحة التحكم
    final ProductController controller = Get.find<ProductController>();
    final TextEditingController searchController = TextEditingController();

    /// دالة لفتح الكاميرا ومسح الباركود للبحث
    Future<void> _scanBarcodeForSearch() async {
      await Get.dialog(
        Scaffold(
          appBar: AppBar(title: const Text('امسح الباركود للبحث'),
           ),
          body: MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String code = barcodes.first.rawValue ?? "";
                if (code.isNotEmpty) {
                  // تحديث حقل البحث والكنترولر
                  searchController.text = code;
                  controller.searchQuery.value = code;
                }
                Get.back(); // إغلاق شاشة الماسح
              }
            },
          ),
        ),
      );
    }


    return VisibilityDetector(
        key: const Key('products-screen-visibility-detector'),
        onVisibilityChanged: (visibilityInfo) {
          if (visibilityInfo.visibleFraction == 1.0) {
            // استدعاء دالة التحديث في الـ Controller
            controller.fetchAllProducts();
          }
        },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('قائمة المنتجات'),
          actions: [
            IconButton(
              icon: const Icon(Icons.print_outlined),
              onPressed: () {
                // استدعاء دالة طباعة التقرير وتمرير قائمة المنتجات الحالية
                // نمرر القائمة الكاملة وليس المصفاة
                ReportService.printInventoryReport(controller.filteredProducts);
              },
              tooltip: 'طباعة تقرير الجرد',
            ),
          ],
          // --- نهاية الإضافة ---

          // استخدام flexibleSpace لوضع حقل البحث تحت العنوان
          flexibleSpace: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60.0),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      onChanged: (value) => controller.searchQuery.value = value,
                      decoration: InputDecoration(
                        hintText: 'ابحث عن اسم المنتج أو الباركود...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
                        prefixIcon: const Icon(Icons.search, color: Colors.white),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        // إضافة زر لمسح حقل البحث
                        suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white70),
                          onPressed: () {
                            searchController.clear();
                            controller.searchQuery.value = '';
                          },
                        )
                            : const SizedBox.shrink()),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  // --- بداية الإضافة: زر مسح الباركود ---
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: IconButton(
                      icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
                      onPressed: _scanBarcodeForSearch,
                      tooltip: 'بحث بالباركود',
                    ),
                  ),
                  // --- نهاية الإضافة ---
                ],
              ),
            ),
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.isTrue) {
            return const Center(child: CircularProgressIndicator());
          }

          // --- بداية التعديل: تحسين منطق الواجهة الفارغة ---
          // الحالة الأولى: لا توجد نتائج للبحث
          if (controller.filteredProducts.isEmpty && controller.searchQuery.value.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'لا توجد منتجات تطابق بحثك.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      searchController.clear();
                      controller.searchQuery.value = '';
                    },
                    icon: const Icon(Icons.filter_alt_off_outlined),
                    label: const Text('إلغاء الفلترة'),
                  )
                ],
              ),
            );
          }
          // الحالة الثانية: لا توجد منتجات على الإطلاق
          else if (controller.filteredProducts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'مخزونك فارغ!',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'قم بإضافة منتجك الأول لتبدأ.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Get.to(() => const AddEditProductScreen()),
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة منتج جديد'),
                  )
                ],
              ),
            );
          }
          // --- نهاية التعديل ---

          // الحالة الطبيعية: عرض قائمة المنتجات
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80), // هامش للـ FAB
            itemCount: controller.filteredProducts.length,
            itemBuilder: (context, index) {
              final product = controller.filteredProducts[index];
              return ProductListItem(
                product: product,
                onDelete: () {
                  Get.defaultDialog(
                    title: 'تأكيد الحذف',
                    middleText: 'هل أنت متأكد من رغبتك في حذف المنتج "${product.name}"؟',
                    textConfirm: 'حذف',
                    textCancel: 'إلغاء',
                    confirmTextColor: Colors.white,
                    onConfirm: () {
                      controller.deleteProduct(product.id!);
                      Get.back(); // إغلاق نافذة التأكيد
                    },
                  );
                },
              );
            },
          );
        }),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Get.to(() => const AddEditProductScreen());
          },
          icon: const Icon(Icons.add),
          label: const Text('إضافة منتج'),
        ),
      ),
    );
  }
}
