// File: lib/features/products/presentation/screens/product_detail_screen.dart

import 'dart:io';
import 'package:ehab_company_admin/features/products/data/models/product_model.dart';
import 'package:ehab_company_admin/features/products/presentation/screens/add_edit_product_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;

class ProductDetailScreen extends StatelessWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final bool hasImage = product.imageUrl != null && product.imageUrl!.isNotEmpty && File(product.imageUrl!).existsSync();
    final theme = Theme.of(context);
    final formatCurrency = intl.NumberFormat.currency(locale: 'ar_SA', symbol: ' ريال');

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 1. رأس الصفحة المرن الذي يحتوي على الصورة والـ AppBar
          SliverAppBar(
            expandedHeight: hasImage ? 300.0 : 0,
            floating: false,
            pinned: true,
            backgroundColor: theme.primaryColor,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () {
                  Get.to(() => AddEditProductScreen(product: product));
                },
              ),
            ],
            flexibleSpace: hasImage
                ? FlexibleSpaceBar(
              title: Text(
                product.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16.0,
                ),
              ),
              background: Hero( // لتأثير انتقال سلس للصورة
                tag: 'product_image_${product.id}',
                child: Image.file(
                  File(product.imageUrl!),
                  fit: BoxFit.cover,
                ),
              ),
            )
                : FlexibleSpaceBar(
              title: Text(
                product.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16.0,
                ),
              ),
            ),
          ),

          // 2. محتوى الصفحة الذي يتم تمريره
          SliverList(
            delegate: SliverChildListDelegate(
              [
                if (!hasImage) // إذا لم تكن هناك صورة، أظهر الاسم هنا بشكل بارز
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: Text(
                      product.name,
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),

                // بطاقة التسعير والكمية
                _buildPricingAndQuantityCard(formatCurrency, theme),

                // بطاقة حالة الصلاحية
                _buildExpiryCard(theme),

                // بطاقة معلومات إضافية
                _buildAdditionalInfoCard(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // بطاقة لعرض السعر والكمية
  Widget _buildPricingAndQuantityCard(intl.NumberFormat formatCurrency, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildInfoColumn(Icons.inventory_2_outlined, 'الكمية', '${product.quantity.toInt()} ${product.unit ?? 'قطعة'}', theme.primaryColor),
            _buildInfoColumn(Icons.sell_outlined, 'سعر البيع', formatCurrency.format(product.salePrice), Colors.green),
            _buildInfoColumn(Icons.money_off_csred_outlined, 'سعر الشراء', formatCurrency.format(product.purchasePrice), Colors.red),
          ],
        ),
      ),
    );
  }

  // ودجت مساعد لبناء كل عمود في بطاقة التسعير
  Widget _buildInfoColumn(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          child: Icon(icon),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  // بطاقة لعرض حالة الصلاحية
  Widget _buildExpiryCard(ThemeData theme) {
    if (product.expiryDate == null) return const SizedBox.shrink(); // لا تظهر البطاقة إذا لم يكن هناك تاريخ انتهاء

    final String statusText;
    final Color statusColor;
    final IconData statusIcon;

    if (product.isExpired) {
      statusText = 'منتهي الصلاحية';
      statusColor = Colors.red;
      statusIcon = Icons.error_outline;
    } else if (product.isExpiringSoon) {
      statusText = 'قريب من الانتهاء';
      statusColor = Colors.orange;
      statusIcon = Icons.warning_amber_rounded;
    } else {
      statusText = 'صالح';
      statusColor = Colors.green;
      statusIcon = Icons.check_circle_outline;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(statusIcon, color: statusColor, size: 40),
              title: Text(statusText, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: statusColor)),
              subtitle: const Text('حالة الصلاحية'),
            ),
            const Divider(),
            _buildDetailRow('تاريخ الإنتاج:', product.productionDate != null ? intl.DateFormat('yyyy-MM-dd').format(product.productionDate!) : 'غير محدد'),
            _buildDetailRow('تاريخ الانتهاء:', intl.DateFormat('yyyy-MM-dd').format(product.expiryDate!)),
          ],
        ),
      ),
    );
  }

  // بطاقة لعرض معلومات إضافية
  Widget _buildAdditionalInfoCard(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('القسم:', product.category ?? 'غير محدد'),
            const Divider(),
            _buildDetailRow('الكود (الباركود):', product.code ?? 'غير محدد'),
          ],
        ),
      ),
    );
  }

  // ودجت مساعد لعرض صف من التفاصيل
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
