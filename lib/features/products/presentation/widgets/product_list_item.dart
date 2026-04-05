// File: lib/features/products/presentation/widgets/product_list_item.dart

import 'dart:io';
import 'package:ehab_company_admin/features/products/data/models/product_model.dart';
import 'package:ehab_company_admin/features/products/presentation/screens/product_detail_screen.dart';
import 'package:ehab_company_admin/features/units/presentation/controllers/unit_controller.dart'; // <-- إضافة
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/services/settings_service.dart';

class ProductListItem extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onDelete;
  final Color? cardColor; // <-- إضافة جديدة

  const ProductListItem({
    super.key,
    required this.product,
    required this.onDelete,
    this.cardColor, // <-- إضافة جديدة
  });

  @override
  Widget build(BuildContext context) {
    final currency = Get.find<SettingsService>();
    final unitController = Get.find<UnitController>(); // <-- إضافة
    final theme = Theme.of(context);
    final bool hasImage =
        product.imageUrl != null && product.imageUrl!.isNotEmpty;

    return InkWell(
      onTap: () {
        Get.to(() => ProductDetailScreen(product: product));
      },
      child: Card(
        color: cardColor,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          leading: CircleAvatar(
            radius: 28,
            backgroundColor: theme.primaryColor.withOpacity(0.1),
            backgroundImage: hasImage
                ? FileImage(File(product.imageUrl!))
                : null,
            child: !hasImage
                ? Text(
                    product.name.length >= 2
                        ? product.name.substring(0, 2).toUpperCase()
                        : product.name.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  )
                : null,
          ),
          title: Row(
            children: [
              Text(
                product.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (product.isSalesStopped) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Text(
                    'موقوف',
                    style: TextStyle(
                      color: Colors.red.shade900,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Obx(() => Text(
              'الكمية: ${unitController.formatSmartQuantity(product.unitId, product.quantity)} | سعر البيع: ${product.salePrice} ${currency.primaryCurrency.value.symbol}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            )),
          ),
          trailing: IconButton(
            icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
            onPressed: onDelete,
          ),
        ),
      ),
    );
  }
}
