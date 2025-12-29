// File: lib/features/home/presentation/widgets/stats_carousel.dart

import 'package:ehab_company_admin/core/services/auth_service.dart';
import 'package:ehab_company_admin/core/services/settings_service.dart';
import 'package:ehab_company_admin/features/home/presentation/controllers/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;

class StatsCarousel extends StatelessWidget {
  final HomeController controller;
  const StatsCarousel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final currencySymbol =
        Get.find<SettingsService>().primaryCurrency.value.symbol;
    final formatCurrency = intl.NumberFormat.currency(
      locale: 'ar_SA',
      symbol: currencySymbol,
    );
    final authService = Get.find<AuthService>();

    return SizedBox(
      height: 160,
      child: Obx(() {
        if (controller.isLoading.isTrue) {
          return const Center(child: CircularProgressIndicator());
        }

        final List<Map<String, dynamic>> allStats = [
          {
            'title': 'رصيد الصندوق',
            'value': formatCurrency.format(controller.currentFundBalance.value),
            'icon': Icons.account_balance_wallet_outlined,
            'color': const Color(0xFF00B894), // Teal
            'permission': AuthService.pManageMoney,
          },
          {
            'title': 'قيمة المخزون',
            'value': formatCurrency.format(
              controller.totalInventoryValue.value,
            ),
            'icon': Icons.inventory_2_outlined,
            'color': const Color(0xFF0984E3), // Blue
            'permission': AuthService.pViewInventory,
          },
          {
            'title': 'ديون الموردين',
            'value': formatCurrency.format(controller.totalSuppliersDebt.value),
            'icon': Icons.local_shipping_outlined,
            'color': const Color(0xFF6C5CE7), // Purple
            'permission': AuthService.pViewPurchases,
          },
          {
            'title': 'فواتير آجلة',
            'value': formatCurrency.format(controller.totalPurchasesDue.value),
            'icon': Icons.receipt_long_outlined,
            'color': const Color(0xFFD63031), // Red/Coral
            'permission': AuthService.pViewPurchases,
          },
          {
            'title': 'عدد المنتجات',
            'value': controller.totalProductsCount.value.toString(),
            'icon': Icons.category_outlined,
            'color': const Color(0xFFE17055), // Orange
            'permission': AuthService.pViewInventory,
          },
        ];

        // تصفية الإحصائيات بناءً على الصلاحيات
        final List<Map<String, dynamic>> stats = allStats.where((s) {
          return authService.hasPermission(s['permission']);
        }).toList();

        if (stats.isEmpty) return const SizedBox.shrink();

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
      width: 220,
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: color,
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // خلفية زخرفية للأيقونة
              Positioned(
                right: -10,
                top: -10,
                child: Icon(
                  icon,
                  color: Colors.white.withOpacity(0.15),
                  size: 100,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: Colors.white, size: 24),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            value,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
