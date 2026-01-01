// File: lib/main.dart

import 'package:ehab_company_admin/core/database/database_service.dart';
import 'package:ehab_company_admin/core/theme/app_theme.dart';
import 'package:ehab_company_admin/features/auth/presentation/screens/login_screen.dart';
import 'package:ehab_company_admin/features/purchases/presentation/screens/add_purchase_binding.dart';
import 'package:ehab_company_admin/features/purchases/presentation/screens/add_purchase_invoice_screen.dart';
import 'package:ehab_company_admin/features/splash/splash_screen.dart';
import 'package:ehab_company_admin/initial_binding.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/services/settings_service.dart';
import 'features/sales/presentation/screens/add_sales_invoice_binding.dart';
import 'features/sales/presentation/screens/add_sales_invoice_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DatabaseService().database;

  await Get.putAsync(() => SettingsService().init());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Ehab Company',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      fallbackLocale: const Locale('ar'),

      // 2. إضافة وكلاء الترجمة اللازمين
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialBinding: InitialBinding(),

      // 3. تحديد اللغات التي يدعمها التطبيق
      supportedLocales: const [
        Locale('ar', ''), // العربية
        Locale('en', ''), // الإنجليزية (كخيار احتياطي)
      ],
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),

      getPages: [
        GetPage(
          name: '/add_sales_invoice',
          page: () => const AddSalesInvoiceScreen(),
          binding: AddSalesInvoiceBinding(),
        ),
        GetPage(
          name: '/add_purchase_invoice',
          page: () => const AddPurchaseInvoiceScreen(),
          binding: AddPurchaseBinding(),
        ),
        GetPage(name: '/login', page: () => const LoginScreen()),
      ],
    );
  }
}
