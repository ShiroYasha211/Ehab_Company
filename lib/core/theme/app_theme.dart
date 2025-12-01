// File: lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // اجعل الكونستركتور برايفت لمنع إنشاء نسخ من هذا الكلاس
  AppTheme._();

  // ----------------- الألوان الأساسية ----------------- //
  static const Color primaryColor = Color(0xFF0F1A4E); // كحلي داكن
  static const Color secondaryColor = Color(0xFFD4AF37); // ذهبي/برونزي
  static const Color backgroundColor = Color(0xFFF5F5F5); // خلفية التطبيق
  static const Color surfaceColor = Colors.white; // لون البطاقات

  // ----------------- الألوان الدلالية ----------------- //
  static const Color successColor = Color(0xFF28a745);
  static const Color errorColor = Color(0xFFdc3545);
  static const Color warningColor = Color(0xFFffc107);

  // ----------------- النص والألوان المحايدة ----------------- //
  static const Color textPrimaryColor = Color(0xFF1F1F1F);
  static const Color textSecondaryColor = Color(0xFF6c757d);


  // =================================================================================
  //                                  الثيم الرئيسي للتطبيق
  // =================================================================================
  static ThemeData get lightTheme {
    final textTheme = GoogleFonts.cairoTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // 1. تحديد الألوان
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        background: backgroundColor,
        surface: surfaceColor,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onBackground: textPrimaryColor,
        onSurface: textPrimaryColor,
        onError: Colors.white,
      ),

      // 2. تحديد الخطوط
      textTheme: textTheme.apply(
        bodyColor: textPrimaryColor,
        displayColor: textPrimaryColor,
      ),

      // 3. تخصيص مظهر الويدجتس
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: secondaryColor,
        foregroundColor: Colors.white,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceColor,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: primaryColor, width: 2),
          ),
          labelStyle: const TextStyle(color: textSecondaryColor),
          floatingLabelStyle: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold)
      ),

      cardTheme: CardThemeData(
        elevation: 2,
        color: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      listTileTheme: const ListTileThemeData(
        iconColor: primaryColor,
      ),
    );
  }
}
