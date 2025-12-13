// File: lib/features/products/presentation/screens/inventory_dashboard_screen.dart

import 'package:ehab_company_admin/features/products/presentation/screens/add_edit_product_screen.dart';
import 'package:ehab_company_admin/features/products/presentation/screens/inventory_dashboard_binding.dart';
import 'package:ehab_company_admin/features/products/presentation/screens/products_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../categories/presentation/screens/categories_screen.dart';
import '../../../units/presentation/screens/units_screen.dart';
import 'bulk_price_editor_screen.dart';
import 'import_products_screen.dart';

class InventoryDashboardScreen  extends StatelessWidget {
  const InventoryDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المخزون'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // الخيار الأول: عرض المنتجات
          _buildDashboardItem(
            context: context,
            icon: Icons.list_alt_rounded,
            title: 'عرض كل المنتجات',
            subtitle: 'تصفح، بحث، وتعديل المنتجات الموجودة',
            onTap: () {
              Get.to(() => const ProductsScreen(),
                  binding: InventoryDashboardBinding());
            },
          ),

          // الخيار الثاني: إضافة منتج جديد
          _buildDashboardItem(
            context: context,
            icon: Icons.add_shopping_cart_rounded,
            title: 'إضافة منتج جديد',
            subtitle: 'إدخال منتج جديد يدويًا إلى المخزون',
            onTap: () {
              Get.to(() => const AddEditProductScreen(),
              binding: InventoryDashboardBinding());
            },
          ),

          // الخيار الثالث: إضافة تصنيف
          _buildDashboardItem(
            context: context,
            icon: Icons.category_outlined,
            title: 'إدارة التصنيفات',
            subtitle: 'إضافة أو تعديل أقسام وتصنيفات المنتجات',
            onTap: () {
              Get.to(() => const CategoriesScreen());            },
          ),

          _buildDashboardItem(
            context: context,
            icon: Icons.all_inbox, // أيقونة مناسبة
            title: 'إدارة الوحدات',
            subtitle: 'إضافة أو تعديل وحدات القياس (قطعة، كرتون)',
            onTap: () {
              Get.to(() => const UnitsScreen(),
              binding: InventoryDashboardBinding());

            },
          ),

          // الخيار الرابع: تعديل الأسعار (قيد التنفيذ)
          _buildDashboardItem(
            context: context,
            icon: Icons.price_change_outlined,
            title: 'تعديل أسعار المنتجات',
            subtitle: 'تحديث أسعار البيع أو الشراء لمجموعة من المنتجات',
            onTap: () {
              // --- بداية التعديل ---
              Get.to(() => const BulkPriceEditorScreen(),
              binding: InventoryDashboardBinding());
              // --- نهاية التعديل ---
            },
          ),

          // الخيار الخامس: استيراد من Excel (قيد التنفيذ)
          _buildDashboardItem(
            context: context,
            icon: Icons.file_upload_outlined,
            title: 'استيراد من ملف Excel',
            subtitle: 'إضافة أو تحديث المنتجات دفعة واحدة من ملف',
            onTap: () {
              // --- بداية التعديل ---
              Get.to(() => const ImportProductsScreen(),
              binding: InventoryDashboardBinding());
              // --- نهاية التعديل ---
            },
            isAdvanced: true, // تمييز الميزات المتقدمة
          ),
        ],
      ),
    );
  }

  /// ودجت مساعد لبناء كل عنصر في لوحة التحكم
  Widget _buildDashboardItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isAdvanced = false,
  }) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: isAdvanced
              ? theme.colorScheme.secondary.withOpacity(0.15)
              : theme.primaryColor.withOpacity(0.1),
          child: Icon(
            icon,
            size: 30,
            color: isAdvanced ? theme.colorScheme.secondary : theme.primaryColor,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.grey),
      ),
    );
  }
}

