// File: lib/main.dart

import 'package:ehab_company_admin/core/theme/app_theme.dart';
import 'package:ehab_company_admin/features/theme_showcase/theme_showcase_screen.dart'; // سنقوم بإنشاء هذا الملف
import 'package:flutter/material.dart';
import 'package:get/get.dart'; // قم بإضافة مكتبة GetX

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp( // استخدم GetMaterialApp بدلاً من MaterialApp
      title: 'Ehab Company',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme, // استدعاء الثيم من الملف الجديد
      home: const ThemeShowcaseScreen(), // الواجهة التي سنعرض فيها الثيم
      locale: const Locale('ar'), // تحديد اللغة العربية كلغة افتراضية
      fallbackLocale: const Locale('ar'),
    );
  }
}
