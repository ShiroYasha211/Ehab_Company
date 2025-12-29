// File: lib/features/settings/presentation/controllers/settings_controller.dart

import 'package:ehab_company_admin/core/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:currency_picker/currency_picker.dart';

class SettingsController extends GetxController {
  // الوصول إلى سيرفس الإعدادات الذي قمنا بتسجيله
  final SettingsService settingsService = Get.find<SettingsService>();

  // --- 1. بداية التعديل: متغيرات جديدة ---
  late TextEditingController exchangeRateController;
  final RxBool isSameAsPrimary = true.obs;
  // --- نهاية التعديل ---

  @override
  void onInit() {
    super.onInit();
    // تهيئة الـ controller بالقيم الحالية
    exchangeRateController =
        TextEditingController(text: settingsService.exchangeRate.value?.toString() ?? '');

    // تحديد الحالة الأولية للـ Checkbox بناءً على الإعدادات المحفوظة
    isSameAsPrimary.value = settingsService.areCurrenciesTheSame;

    // --- 2. بداية الإضافة: مراقبة الـ Checkbox ---
    // هذا الـ listener سيقوم بتحديث العملة المحلية تلقائيًا
    ever(isSameAsPrimary, (bool isSame) {
      if (isSame) {
        // إذا كانت العملتان متطابقتين، قم بمزامنة العملة المحلية مع الأساسية
        settingsService.updateLocalCurrency(
          name: settingsService.primaryCurrencyName.value,
          symbol: settingsService.primaryCurrencySymbol.value,
        );
        // واجعل سعر الصرف 1
        exchangeRateController.text = '1.0';
      }
    });
    // --- نهاية الإضافة ---
  }

  // --- 3. بداية الإضافة: دالة جديدة لاختيار العملة ---
  void pickCurrency({required bool isPrimary}) {
    showCurrencyPicker(
      context: Get.context!,
      showFlag: true,
      showCurrencyName: true,
      showCurrencyCode: true,
      onSelect: (Currency currency) {
        if (isPrimary) {
          settingsService.updatePrimaryCurrency(
            name: currency.name,
            symbol: currency.symbol,
          );
          // إذا كانت العملتان متطابقتين، قم بتحديث المحلية أيضًا
          if (isSameAsPrimary.isTrue) {
            settingsService.updateLocalCurrency(
              name: currency.name,
              symbol: currency.symbol,
            );
          }
        } else {
          settingsService.updateLocalCurrency(
            name: currency.name,
            symbol: currency.symbol,
          );
        }
      },
      // لتحديد العملة الحالية في القائمة
      favorite: [isPrimary ? settingsService.primaryCurrencySymbol.value : settingsService.localCurrencySymbol.value],
    );
  }
  // --- نهاية الإضافة ---

  /// دالة لحفظ كل إعدادات العملة دفعة واحدة
  void saveCurrencySettings() {
    // --- 4. بداية التعديل: تبسيط منطق الحفظ ---
    if (isSameAsPrimary.isTrue) {
      // إذا كانت العملتان متطابقتين، احفظ سعر الصرف كـ 1.0
      settingsService.updateExchangeRate(1.0);
    } else {
      // إذا كانتا مختلفتين، احفظ سعر الصرف الذي أدخله المستخدم
      final rate = double.tryParse(exchangeRateController.text);
      if (rate == null || rate <= 0) {
        Get.snackbar('خطأ', 'الرجاء إدخال سعر صرف صحيح وأكبر من الصفر.',
            backgroundColor: Colors.red, colorText: Colors.white);
        return; // أوقف الحفظ
      }
      settingsService.updateExchangeRate(rate);
    }
    // --- نهاية التعديل ---

    Get.back(); // العودة من شاشة الإعدادات
    Get.snackbar('نجاح', 'تم حفظ إعدادات العملة بنجاح.',
        backgroundColor: Colors.green, colorText: Colors.white);
  }

  @override
  void onClose() {
    // التخلص من الـ controller
    exchangeRateController.dispose();
    super.onClose();
  }
}
