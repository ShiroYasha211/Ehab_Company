// File: lib/features/home/presentation/widgets/stats_carousel.dart

import 'package:ehab_company_admin/features/home/presentation/controllers/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;

class StatsCarousel extends StatelessWidget {
  final HomeController controller;
  const StatsCarousel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {

    final formatCurrency = intl.NumberFormat.currency(locale: 'ar_SA', symbol: 'ر.ي');

    return SizedBox(
        height: 150, // زيادة ارتفاع الشريط قليلاً
        child: Obx(() {
          if (controller.isLoading.isTrue) {
            return const Center(child: CircularProgressIndicator());
          }

          final List<Map<String, dynamic>> stats = [
          {
            'title': 'رصيد الصندوق',
          'value': formatCurrency.format(controller.currentFundBalance.value),
          'icon': Icons.account_balance_wallet_outlined,
          'color': Colors.green,
        },
        {
          'title': 'قيمة المخزون',
          'value': formatCurrency.format(controller.totalInventoryValue.value),
          'icon': Icons.inventory_2_outlined,
          'color': Colors.blue,
        },
          {
          'title': 'ديون الموردين',
          'value': formatCurrency.format(controller.totalSuppliersDebt.value),
          'icon': Icons.local_shipping_outlined,
          'color': Colors.purple,
          },
        {
          'title': 'فواتير آجلة',
          'value': formatCurrency.format(controller.totalPurchasesDue.value),
        'icon': Icons.receipt_long_outlined,
        'color': Colors.orange,
        },
        {
          'title': 'عدد المنتجات',
          'value': controller.totalProductsCount.value.toString(),
          'icon': Icons.category_outlined,
          'color': Colors.teal,
        },
          ];

          return ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: stats.length,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemBuilder: (context, index) {
                return StatCard(
                  title: stats[index]['title'],
                  value: stats[index]['value'],
                  icon: stats[index]['icon'],
                  color: stats[index]['color'],
                );
              },
          );
        }),
    );
  }
}

// ------------------- ودجت بطاقة الإحصائيات (النسخة الاحترافية) -------------------
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      margin: const EdgeInsets.symmetric(horizontal: 5.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color,
            color.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
          color: color.withOpacity(0.3),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Icon(
                      icon, color: Colors.white.withOpacity(0.5), size: 36),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}












