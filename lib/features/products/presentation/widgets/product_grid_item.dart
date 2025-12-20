// File: lib/features/products/presentation/widgets/product_grid_item.dart

import 'dart:io';
import 'package:ehab_company_admin/features/products/data/models/product_model.dart';
import 'package:ehab_company_admin/features/products/presentation/screens/product_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;

class ProductGridItem extends StatelessWidget {
  final ProductModel product;
  final Color? cardColor;

  const ProductGridItem({
    super.key,
    required this.product,
    this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasImage = product.imageUrl != null &&
        product.imageUrl!.isNotEmpty &&
        File(product.imageUrl!).existsSync();
    final formatCurrency =
    intl.NumberFormat.currency(locale: 'ar_SA', symbol: ' ريال');

    return Card(
      color: cardColor,
      clipBehavior: Clip.antiAlias, // لقص المحتوى الزائد عن حواف البطاقة
      elevation: 2,
      child: InkWell(
        onTap: () => Get.to(() => ProductDetailScreen(product: product)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. الصورة
            Expanded(
              child: hasImage
                  ? Hero(
                tag: 'product_image_${product.id}',
                child: Image.file(
                  File(product.imageUrl!),
                  fit: BoxFit.cover,
                ),
              )
                  : Container(
                color: Colors.grey.shade200,
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: Colors.grey.shade400,
                  size: 40,
                ),
              ),
            ),
            // 2. التفاصيل
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatCurrency.format(product.salePrice),
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
