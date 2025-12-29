// File: lib/features/home/presentation/screens/home_screen.dart

import 'package:ehab_company_admin/core/services/auth_service.dart';
import 'package:ehab_company_admin/features/customers/presentation/screens/customers_dashboard_screen.dart';
import 'package:ehab_company_admin/features/expenses/presentation/screens/expenses_binding.dart';
// --- 1. بداية الإضافة: إضافة import جديد ---
import 'package:ehab_company_admin/features/expenses/presentation/screens/expenses_dashboard_screen.dart';
import 'package:ehab_company_admin/features/financial_docs/presentation/screens/financial_docs_binding.dart';
// --- نهاية الإضافة ---
import 'package:ehab_company_admin/features/home/presentation/widgets/feature_card.dart';
import 'package:ehab_company_admin/features/home/presentation/widgets/stats_carousel.dart';
import 'package:ehab_company_admin/features/purchases/presentation/screens/add_purchase_binding.dart';
import 'package:ehab_company_admin/features/purchases/presentation/screens/purchases_dashboard_screen.dart';
import 'package:ehab_company_admin/features/reports/presentation/screens/reports_binding.dart';
import 'package:ehab_company_admin/features/sales/presentation/screens/sales_dashboard_screen.dart';
import 'package:ehab_company_admin/features/suppliers/presentation/screens/suppliers_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:get/get.dart';

import '../../../employees/presentation/screens/employee_list_screen.dart';
import '../../../financial_docs/presentation/screens/financial_docs_dashboard_screen.dart';
import '../../../fund/presentation/screens/fund_screen.dart';
import '../../../products/presentation/screens/inventory_dashboard_binding.dart';
import '../../../products/presentation/screens/inventory_dashboard_screen.dart';
import '../../../reports/presentation/screens/reports_dashboard_screen.dart';
import '../../../settings/presentation/controllers/settings_binding.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../controllers/home_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();

    // قائمة الوظائف التي ستعرض في البطاقات مع ربطها بالصلاحيات
    final List<Map<String, dynamic>> allFeatures = [
      {
        'title': 'المخازن',
        'icon': Icons.inventory_2_outlined,
        'permission': AuthService.pViewInventory,
      },
      {
        'title': 'المبيعات',
        'icon': Icons.point_of_sale_outlined,
        'permission': AuthService.pViewSales,
      },
      {
        'title': 'الصندوق',
        'icon': Icons.account_balance_wallet_outlined,
        'permission': AuthService.pManageMoney,
      },
      {
        'title': 'المشتريات',
        'icon': Icons.shopping_cart_outlined,
        'permission': AuthService.pViewPurchases,
      },
      {
        'title': 'المصروفات',
        'icon': Icons.receipt_long_outlined,
        'permission': AuthService.pManageMoney,
      },
      {
        'title': 'العملاء',
        'icon': Icons.people_outline,
        'permission': AuthService.pViewSales,
      },
      {
        'title': 'الموردين',
        'icon': Icons.local_shipping_outlined,
        'permission': AuthService.pViewPurchases,
      },
      {
        'title': 'الفواتير',
        'icon': Icons.description_outlined,
        'permission': AuthService.pViewSales, // أو أي صلاحية تناسبها
      },
      {
        'title': 'التقارير',
        'icon': Icons.bar_chart_outlined,
        'permission': AuthService.pViewReports,
      },
      {
        'title': 'الموظفين',
        'icon': Icons.badge_outlined,
        'permission': AuthService.pManageUsers,
      },
      {
        'title': 'الإعدادات',
        'icon': Icons.settings_outlined,
        'permission': AuthService.pManageSettings,
      },
    ];

    // تصفية القائمة بناءً على صلاحيات المستخدم الحالي
    final List<Map<String, dynamic>> features = allFeatures.where((f) {
      return authService.hasPermission(f['permission']);
    }).toList();

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
          title: Column(
            children: [
              const Text(
                'لوحة التحكم الرئيسية',
                style: TextStyle(fontSize: 18),
              ),
              Obx(
                () => Text(
                  'مرحباً، ${authService.currentUser.value?.name ?? ""}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              tooltip: 'تسجيل الخروج',
              onPressed: () {
                Get.defaultDialog(
                  title: 'تسجيل الخروج',
                  middleText: 'هل أنت متأكد أنك تريد تسجيل الخروج؟',
                  textConfirm: 'نعم',
                  textCancel: 'إلغاء',
                  confirmTextColor: Colors.white,
                  buttonColor: Colors.red,
                  onConfirm: () {
                    Get.back();
                    authService.logout();
                  },
                );
              },
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () => homeController.refreshStats(),
          child: ListView(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'نظرة عامة',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              StatsCarousel(controller: homeController),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  'أقسام النظام',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
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
                      } else if (featureTitle == 'المبيعات') {
                        Get.to(() => const SalesDashboardScreen());
                      }
                      // --- 2. بداية التعديل: إضافة شرط المصروفات ---
                      else if (featureTitle == 'المصروفات') {
                        Get.to(
                          () => const ExpensesDashboardScreen(),
                          binding: ExpensesBinding(),
                        );
                      }
                      // --- نهاية التعديل ---
                      else if (featureTitle == 'الصندوق') {
                        Get.to(() => const FundScreen());
                      } else if (featureTitle == 'الموردين') {
                        Get.to(() => const SuppliersDashboardScreen());
                      } else if (featureTitle == 'المشتريات') {
                        Get.to(
                          () => const PurchasesDashboardScreen(),
                          binding: AddPurchaseBinding(),
                        );
                      } else if (featureTitle == 'العملاء') {
                        Get.to(() => const CustomersDashboardScreen());
                      } else if (featureTitle == 'التقارير') {
                        Get.to(
                          () => const ReportsDashboardScreen(),
                          binding: ReportsBinding(),
                        );
                      } else if (featureTitle == 'الفواتير') {
                        Get.to(
                          () => const FinancialDocsDashboardScreen(),
                          binding: FinancialDocsBinding(),
                        );
                      } else if (featureTitle == 'الإعدادات') {
                        Get.to(
                          () => const SettingsScreen(),
                          binding: SettingsBinding(),
                        );
                      } else if (featureTitle == 'الموظفين') {
                        Get.to(() => const EmployeeListScreen());
                      } else {
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
      ),
    );
  }
}
