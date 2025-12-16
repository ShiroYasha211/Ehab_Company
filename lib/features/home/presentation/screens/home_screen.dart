// File: lib/features/home/presentation/screens/home_screen.dart

import 'package:ehab_company_admin/features/customers/presentation/screens/customers_dashboard_screen.dart';
import 'package:ehab_company_admin/features/expenses/presentation/screens/expenses_binding.dart';
// --- 1. بداية الإضافة: إضافة import جديد ---
import 'package:ehab_company_admin/features/expenses/presentation/screens/expenses_dashboard_screen.dart';
// --- نهاية الإضافة ---
import 'package:ehab_company_admin/features/home/presentation/widgets/feature_card.dart';
import 'package:ehab_company_admin/features/home/presentation/widgets/stats_carousel.dart';
import 'package:ehab_company_admin/features/purchases/presentation/screens/add_purchase_binding.dart';
import 'package:ehab_company_admin/features/purchases/presentation/screens/purchases_dashboard_screen.dart';
import 'package:ehab_company_admin/features/sales/presentation/screens/sales_dashboard_screen.dart';
import 'package:ehab_company_admin/features/suppliers/presentation/screens/suppliers_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:get/get.dart';

import '../../../fund/presentation/screens/fund_screen.dart';
import '../../../products/presentation/screens/inventory_dashboard_binding.dart';
import '../../../products/presentation/screens/inventory_dashboard_screen.dart';
import '../controllers/home_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // قائمة الوظائف التي ستعرض في البطاقات
    final List<Map<String, dynamic>> features = [
      {'title': 'المخازن', 'icon': Icons.inventory_2_outlined},
      {'title': 'المبيعات', 'icon': Icons.point_of_sale_outlined},
      {'title': 'الصندوق', 'icon': Icons.account_balance_wallet_outlined},
      {'title': 'المشتريات', 'icon': Icons.shopping_cart_outlined},
      {'title': 'المصروفات', 'icon': Icons.receipt_long_outlined},
      {'title': 'العملاء', 'icon': Icons.people_outline},
      {'title': 'الموردين', 'icon': Icons.local_shipping_outlined},
      {'title': 'الفواتير', 'icon': Icons.description_outlined},
      {'title': 'التقارير', 'icon': Icons.bar_chart_outlined},
      {'title': 'الموظفين', 'icon': Icons.badge_outlined},
      {'title': 'الإعدادات', 'icon': Icons.settings_outlined},
    ];
    final HomeController homeController = Get.find<HomeController>();
    return VisibilityDetector(
        key: const Key('home-screen-visibility-detector'),
        onVisibilityChanged: (visibilityInfo) {
          if (visibilityInfo.visibleFraction > 0.5) {
            homeController.refreshStats();
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('لوحة التحكم الرئيسية'),
            centerTitle: true,
          ),
          body: RefreshIndicator(
            onRefresh: () => homeController.refreshStats(),
            child: ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text('نظرة عامة', style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
                ),
                StatsCarousel(controller: homeController),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text('أقسام النظام', style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
                ),
                GridView.builder(
                  padding: const EdgeInsets.all(12),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: features.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                  ),
                  itemBuilder: (context, index) {
                    return FeatureCard(
                      title: features[index]['title'],
                      icon: features[index]['icon'],
                      onTap: () {
                        final featureTitle = features[index]['title'];
                        if (featureTitle == 'المخازن') {
                          Get.to(
                                () => const InventoryDashboardScreen(),
                            binding: InventoryDashboardBinding(),
                          );
                        }
                        else if (featureTitle == 'المبيعات') {
                          Get.to(() => const SalesDashboardScreen());
                        }
                        // --- 2. بداية التعديل: إضافة شرط المصروفات ---
                        else if (featureTitle == 'المصروفات') {
                          Get.to(() => const ExpensesDashboardScreen(),
                          binding: ExpensesBinding());
                        }
                        // --- نهاية التعديل ---
                        else if (featureTitle == 'الصندوق') {
                          Get.to(() => const FundScreen());
                        } else if (featureTitle == 'الموردين') {
                          Get.to(() => const SuppliersDashboardScreen());
                        }
                        else if (featureTitle == 'المشتريات') {
                          Get.to(() => const PurchasesDashboardScreen(),
                              binding: AddPurchaseBinding());
                        }
                        else if(featureTitle == 'العملاء'){
                          Get.to(() => const CustomersDashboardScreen());
                        }
                        else {
                          print('$featureTitle card tapped');
                        }
                      },
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        )
    );
  }
}
