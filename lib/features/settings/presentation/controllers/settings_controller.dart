// File: lib/features/settings/presentation/controllers/settings_controller.dart

import 'package:ehab_company_admin/core/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsController extends GetxController {
  // الوصول إلى سيرفس الإعدادات الذي قمنا بتسجيله
  final SettingsService settingsService = Get.find<SettingsService>();

  // --- Text Editing Controllers for the UI ---
  late TextEditingController primaryCurrencyNameController;
  late TextEditingController primaryCurrencySymbolController;
  late TextEditingController localCurrencyNameController;
  late TextEditingController localCurrencySymbolController;
  late TextEditingController exchangeRateController;

  @override
  void onInit() {
    super.onInit();
    // تهيئة الـ controllers بالقيم الحالية من الـ SettingsService
    primaryCurrencyNameController =
        TextEditingController(text: settingsService.primaryCurrencyName.value);
    primaryCurrencySymbolController =
        TextEditingController(text: settingsService.primaryCurrencySymbol.value);
    localCurrencyNameController =
        TextEditingController(text: settingsService.localCurrencyName.value);
    localCurrencySymbolController =
        TextEditingController(text: settingsService.localCurrencySymbol.value);
    exchangeRateController =
        TextEditingController(text: settingsService.exchangeRate.value.toString());
  }

  /// دالة لحفظ كل إعدادات العملة دفعة واحدة
  void saveCurrencySettings() {
    // تحديث العملة الأساسية
    settingsService.updatePrimaryCurrency(
      name: primaryCurrencyNameController.text,
      symbol: primaryCurrencySymbolController.text,
    );

    // تحديث العملة المحلية
    settingsService.updateLocalCurrency(
      name: localCurrencyNameController.text,
      symbol: localCurrencySymbolController.text,
    );

    // تحديث سعر الصرف
    final rate = double.tryParse(exchangeRateController.text) ?? 1.0;
    settingsService.updateExchangeRate(rate);

    Get.back(); // العودة من شاشة الإعدادات
    Get.snackbar('نجاح', 'تم حفظ إعدادات العملة بنجاح.',
        backgroundColor: Colors.green, colorText: Colors.white);
  }

  @override
  void onClose() {
    // التخلص من الـ controllers
    primaryCurrencyNameController.dispose();
    primaryCurrencySymbolController.dispose();
    localCurrencyNameController.dispose();
    localCurrencySymbolController.dispose();
    exchangeRateController.dispose();
    super.onClose();
  }
}
