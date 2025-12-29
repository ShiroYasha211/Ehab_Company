// File: lib/features/settings/presentation/screens/currency_settings_screen.dart

import 'package:ehab_company_admin/features/settings/presentation/controllers/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:currency_picker/currency_picker.dart';

class CurrencySettingsScreen extends StatelessWidget {
  const CurrencySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SettingsController>();
    final settingsService = controller.settingsService;
    return Scaffold(
        appBar: AppBar(
          title: const Text('إعدادات العملة'),
        ),
        body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
            // --- 1. اختيار العملة الأساسية ---
            _buildSectionHeader('العملة الأساسية (للتسعير والشراء)'),
        Obx(() =>
                _buildCurrencyCard(
                    context: context,
                    title: 'العملة الأساسية',
                    currencyName: settingsService.primaryCurrencyName.value,
                    currencySymbol: settingsService.primaryCurrencySymbol.value,
                  onTap: () => controller.pickCurrency(isPrimary: true),
                ),),
        const Divider(height: 32),
        // --- 2. خيار "العملة المحلية هي نفسها" ---
        _buildIsSameCurrencyCheckbox(controller),
        // --- 3. اختيار العملة المحلية وسعر الصرف (مشروط) ---
        Obx(() {
          if (controller.isSameAsPrimary.isTrue) {
            return const SizedBox.shrink(); // لا تظهر شيئًا
          }
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildSectionHeader('العملة المحلية (للبيع)'),
          _buildCurrencyCard(
          context: context,
          title: 'العملة المحلية'
          ,currencyName: settingsService.localCurrencyName.value,
          currencySymbol: settingsService.localCurrencySymbol.value,
          onTap: () => controller.pickCurrency(isPrimary: false),),
          const SizedBox(height: 16),
          _buildSectionHeader('إعدادات سعر الصرف'),
          Card(
          child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
          children: [
          Text('أدخل كم يساوي 1 ${settingsService.primaryCurrencyName.value} بالعملة المحلية (${settingsService.localCurrencyName.value})',
          textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextField(controller: controller.exchangeRateController,
          keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
          labelText: 'سعر الصرف',
          border:OutlineInputBorder(),
          ),
          textAlign: TextAlign.center,),
          ],
          ),
          ),),],
          );
        }),
              const SizedBox(height: 40),
              ElevatedButton(
        onPressed: controller.saveCurrencySettings,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        child: const Text('حفظالإعدادات'),
              ),
            ],
        ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(
            title,
            style: Get.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold),
        ),
    );
  }

  Widget _buildCurrencyCard({
  required BuildContext context,
  required String title,
  required String currencyName,
  required String currencySymbol,
    required VoidCallback onTap,
  }) {
    return Card(
        child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12), child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Text(title,
                style: const TextStyle(
                    color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(
                    currencyName,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
            ),
            Row(
                children: [Text(
              currencySymbol,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Get.theme.primaryColor),
            ),
          const SizedBox(width: 8),
                  const Icon(Icons.edit_outlined, color: Colors.grey),
                ],
            ),
                ],
            ),
        ),
        ),
    );
  }

  Widget _buildIsSameCurrencyCheckbox(SettingsController controller) {
    return Obx(() =>
            Card(
                child: CheckboxListTile(
                    title: const Text(
                        'العملة المحلية هي نفسها العملة الأساسية'),
                    value: controller.isSameAsPrimary.value,
                    onChanged: (bool? value) {
                      controller.isSameAsPrimary.value = value ?? true;
                    },
                  activeColor: Get.theme.primaryColor,
                ),
            ),
    );
  }
}