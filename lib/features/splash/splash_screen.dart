// File: lib/features/splash/splash_screen.dart

import 'dart:async';
import 'package:ehab_company_admin/features/home/presentation/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // الانتقال بعد 3 ثوانٍ
    Timer(const Duration(seconds: 3), () {
      // استخدام GetX للانتقال مع إزالة الشاشة السابقة من الـ stack
      Get.off(() => const HomeScreen());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // استخدم اللون الأساسي من الثيم كخلفية
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // عرض الشعار
            Image.asset(
              'assets/images/logo.png', // تأكد من أن اسم الملف صحيح
              width: 150,
            ),
            const SizedBox(height: 20),
            // إضافة مؤشر تحميل لتحسين التجربة
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
