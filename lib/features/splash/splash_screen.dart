import 'dart:async';
import 'package:ehab_company_admin/core/services/auth_service.dart';
import 'package:ehab_company_admin/features/auth/presentation/screens/login_screen.dart';
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
    // الحصول على خدمة المصادقة
    final AuthService authService = Get.find<AuthService>();

    // الانتقال بعد 3 ثوانٍ
    Timer(const Duration(seconds: 3), () {
      if (authService.isLoggedIn) {
        // إذا كان مسجل الدخول، انتقل للرئيسية
        Get.offAll(() => const HomeScreen());
      } else {
        // إذا لم يكن مسجل الدخول، انتقل لشاشة الدخول
        Get.offAll(() => const LoginScreen());
      }
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
