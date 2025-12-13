// File: lib/features/products/presentation/screens/product_detail_screen.dart

import 'dart:io';
import 'package:ehab_company_admin/features/products/data/models/product_model.dart';
import 'package:ehab_company_admin/features/products/presentation/screens/add_edit_product_screen.dart';
import 'package:ehab_company_admin/features/products/presentation/screens/inventory_dashboard_binding.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;

class ProductDetailScreen extends StatelessWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final bool hasImage = product.imageUrl != null && product.imageUrl!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Get.to(() => AddEditProductScreen(product: product),
              binding: InventoryDashboardBinding());
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          if (hasImage)
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: FileImage(File(product.imageUrl!)),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('الكود (الباركود)', product.code ?? 'غير محدد', Icons.qr_code),
                const Divider(),
                _buildDetailRow('الكمية المتوفرة', '${product.quantity.toInt()} ${product.unit ?? 'قطعة'}', Icons.inventory_2_outlined),
                const Divider(),
                _buildDetailRow('سعر البيع', '${product.salePrice} ريال', Icons.attach_money),
                const Divider(),
                _buildDetailRow('سعر الشراء (التكلفة)', '${product.purchasePrice} ريال', Icons.money_off),
                const Divider(),
                _buildDetailRow('القسم', product.category ?? 'غير محدد', Icons.folder_open_outlined),
                const Divider(),
                _buildDetailRow('تاريخ الإنتاج', product.productionDate != null ? intl.DateFormat('yyyy-MM-dd').format(product.productionDate!) : 'غير محدد', Icons.calendar_today_outlined),
                const Divider(),
                _buildDetailRow('تاريخ الانتهاء', product.expiryDate != null ? intl.DateFormat('yyyy-MM-dd').format(product.expiryDate!) : 'غير محدد', Icons.event_busy_outlined),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDetailRow(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 22),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
