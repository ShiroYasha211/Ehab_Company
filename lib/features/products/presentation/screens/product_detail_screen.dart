// File: lib/features/products/presentation/screens/product_detail_screen.dart

import 'dart:io';
import 'package:ehab_company_admin/features/products/data/models/product_model.dart';
import 'package:ehab_company_admin/features/products/presentation/controllers/product_controller.dart';
import 'package:ehab_company_admin/features/products/presentation/screens/add_edit_product_screen.dart';
import 'package:ehab_company_admin/features/units/presentation/controllers/unit_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/services/settings_service.dart';

class ProductDetailScreen extends StatelessWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final currencyService = Get.find<SettingsService>();
    final unitController = Get.find<UnitController>();
    final productController = Get.find<ProductController>();

    return Obx(() {
      // جلب النسخة الأحدث من المنتج من الـ Controller لضمان تحديث الواجهة فوراً
      final p = productController.allProducts.firstWhereOrNull((item) => item.id == product.id) ?? product;

      final bool hasImage =
          p.imageUrl != null &&
          p.imageUrl!.isNotEmpty &&
          File(p.imageUrl!).existsSync();
      final theme = Theme.of(context);
      final formatCurrency = intl.NumberFormat.currency(
        locale: 'ar_SA',
        symbol: currencyService.primaryCurrency.value.symbol,
      );

      return Scaffold(
        body: CustomScrollView(
          slivers: [
            // 1. رأس الصفحة المرن
            SliverAppBar(
              expandedHeight: hasImage ? 300.0 : 0,
              floating: false,
              pinned: true,
              backgroundColor: theme.primaryColor,
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {
                    Get.to(() => AddEditProductScreen(product: p));
                  },
                ),
              ],
              flexibleSpace: hasImage
                  ? FlexibleSpaceBar(
                      title: Text(
                        p.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16.0,
                        ),
                      ),
                      background: Hero(
                        tag: 'product_image_${p.id}',
                        child: Image.file(
                          File(p.imageUrl!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  : FlexibleSpaceBar(
                      title: Text(
                        p.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16.0,
                        ),
                      ),
                    ),
            ),

            // 2. محتوى الصفحة
            SliverList(
              delegate: SliverChildListDelegate([
                if (!hasImage)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: Text(
                      p.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                  ),

                // زر إيقاف البيع السريع (السويتش الجديد)
                _buildSuspensionControl(p, productController, theme),

                // بطاقة الأسعار الرئيسية
                _buildPricingCard(p, formatCurrency, theme),

                // لوحة الجرد البصرية
                _buildInventoryDashboard(p, theme, unitController),

                // بطاقة معلومات إضافية
                _buildInfoSections(p, theme),

                const SizedBox(height: 30),
              ]),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSuspensionControl(ProductModel p, ProductController controller, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.isSalesStopped ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: p.isSalesStopped ? Colors.red.shade200 : Colors.green.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (p.isSalesStopped ? Colors.red : Colors.green).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SwitchListTile(
        title: Text(
          'حالة بيع المنتج',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: p.isSalesStopped ? Colors.red.shade900 : Colors.green.shade900,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          p.isSalesStopped ? 'موقف حالياً - لن يظهر في فواتير المبيعات' : 'مفعل حالياً - يمكن للموظفين بيعه',
          style: TextStyle(fontSize: 11, color: p.isSalesStopped ? Colors.red.shade700 : Colors.green.shade700),
        ),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: p.isSalesStopped ? Colors.red : Colors.green,
            shape: BoxShape.circle,
          ),
          child: Icon(
            p.isSalesStopped ? Icons.block : Icons.check_circle_outline,
            color: Colors.white,
            size: 20,
          ),
        ),
        value: !p.isSalesStopped, // نستخدم العكس لأننا نريد "مفعل" = true
        onChanged: (val) => controller.toggleProductSalesStatus(p),
        activeColor: Colors.green,
        inactiveThumbColor: Colors.red,
        inactiveTrackColor: Colors.red.shade200,
      ),
    );
  }

  Widget _buildPricingCard(ProductModel product, intl.NumberFormat formatCurrency, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildPriceItem(
            'سعر البيع',
            formatCurrency.format(product.salePrice),
            Colors.green,
            Icons.trending_up,
          ),
          Container(height: 40, width: 1, color: Colors.grey.shade200),
          _buildPriceItem(
            'التكلفة',
            formatCurrency.format(product.purchasePrice),
            Colors.orange.shade700,
            Icons.shopping_cart_outlined,
          ),
          Container(height: 40, width: 1, color: Colors.grey.shade200),
          _buildPriceItem(
            'الربح المتوقع',
            formatCurrency.format(product.salePrice - product.purchasePrice),
            theme.primaryColor,
            Icons.analytics_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceItem(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryDashboard(ProductModel product, ThemeData theme, UnitController unitController) {
    final levels = unitController.getUnitLevels(product.unitId ?? -1);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'حالة المخزون الحالية',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('مفصل', style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (levels.isEmpty)
            Text(
              '${product.quantity.toInt()} قطعة',
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: levels.length,
              separatorBuilder: (context, index) => 
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Icon(Icons.keyboard_arrow_down, color: Colors.white.withOpacity(0.5), size: 16),
                ),
              itemBuilder: (context, index) {
                final level = levels[index];
                final isAllowed = product.allowedUnits?.contains(level.id) ?? true;
                
                // حساب المعامل العكسي للسعر
                double priceDivisor = 1.0;
                for(int k=0; k<index; k++) {
                  priceDivisor *= levels[k].conversionFactor;
                }
                final levelSalePrice = product.salePrice / priceDivisor;

                // حساب المعادل الإجمالي للكمية
                final equivalentTotal = product.quantity * priceDivisor;

                return Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            index == 0 ? Icons.inventory_2 : Icons.subdirectory_arrow_left,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    level.name,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  if (isAllowed)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade400,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text('متاح للبيع', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade400.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text('للعرض فقط', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                                    ),
                                ],
                              ),
                              Text(
                                'السعر: ${levelSalePrice.toStringAsFixed(2)}',
                                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              equivalentTotal.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '').replaceAll(RegExp(r'\.0$'), ''),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
                            ),
                            Text(
                              'إجمالي المخزون',
                              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          const SizedBox(height: 15),
          Divider(color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 5),
          Center(
            child: Text(
              '💡 القراءة الإجمالية: ${unitController.formatSmartQuantity(product.unitId, product.quantity)}',
              style: const TextStyle(color: Colors.white, fontSize: 13, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSections(ProductModel product, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildInfoTile(
            Icons.category_outlined,
            'القسم التصنيفي',
            product.category ?? 'غير مصنف',
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildInfoTile(
            Icons.qr_code_scanner,
            'الباركود / الكود',
            product.code ?? '---',
            Colors.purple,
          ),
          const SizedBox(height: 12),
          if (product.expiryDate != null)
            _buildExpiryTile(product, theme),
          const SizedBox(height: 12),
          _buildInfoTile(
            Icons.notification_important_outlined,
            'حد الطلب (الحد الأدنى)',
            '${product.minStockLevel.toInt()} قطعة',
            Colors.redAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpiryTile(ProductModel product, ThemeData theme) {
    final bool isExpired = product.isExpired;
    final bool isSoon = product.isExpiringSoon;
    final Color color = isExpired ? Colors.red : (isSoon ? Colors.orange : Colors.green);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(isExpired ? Icons.event_busy : Icons.event_available, color: color, size: 20),
              const SizedBox(width: 12),
              Text(
                isExpired ? 'منتهي الصلاحية!' : (isSoon ? 'تنتهي الصالحية قريباً' : 'المنتج صالح'),
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDateInfo('تاريخ الإنتاج', product.productionDate),
              _buildDateInfo('تاريخ الانتهاء', product.expiryDate),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateInfo(String label, DateTime? date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(
          date != null ? intl.DateFormat('yyyy-MM-dd').format(date) : '---',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }
}
