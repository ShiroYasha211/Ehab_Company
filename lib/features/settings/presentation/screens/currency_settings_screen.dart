// File: lib/features/settings/presentation/screens/currency_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/currency_model.dart';
import '../controllers/settings_controller.dart';

class CurrencySettingsScreen extends StatelessWidget {
  const CurrencySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // نستخدم الـ Controller المحقون سابقاً
    final SettingsController controller = Get.find<SettingsController>();

    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات العملة'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // بطاقة العملة الأساسية
              _buildSectionCard(
                title: 'العملة الأساسية',
                subtitle:
                    'العملة التي تستخدم لحساب التقارير والأرباح بشكل رئيسي',
                icon: Icons.monetization_on,
                child: Obx(
                  () => _buildCurrencySelector(
                    context: context,
                    label: 'اختر العملة',
                    selectedCurrency: controller.primaryCurrency,
                    onTap: () => _showCurrencyPicker(
                      context,
                      (currency) => controller.updatePrimaryCurrency(currency),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // بطاقة العملة المحلية
              Obx(
                () => _buildSectionCard(
                  title: 'العملة المحلية',
                  subtitle:
                      'العملة المستخدمة في البيع اليومي (إذا كانت مختلفة)',
                  icon: Icons.storefront,
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('نفس العملة الأساسية'),
                        subtitle: const Text(
                          'تفعيل هذا يعني أنك تبيع بنفس عملة النظام',
                        ),
                        value: controller.isLocalSameAsPrimary,
                        onChanged: (val) =>
                            controller.toggleLocalSameAsPrimary(val),
                        contentPadding: EdgeInsets.zero,
                      ),

                      // إذا لم تكن نفس الأساسية، نظهر خيارات اختيار العملة وسعر الصرف
                      if (!controller.isLocalSameAsPrimary) ...[
                        const Divider(),
                        const SizedBox(height: 10),
                        _buildCurrencySelector(
                          context: context,
                          label: 'اختر العملة المحلية',
                          selectedCurrency: controller.localCurrency,
                          onTap: () => _showCurrencyPicker(
                            context,
                            (currency) =>
                                controller.updateLocalCurrency(currency),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          textDirection: TextDirection.ltr,
                          decoration: InputDecoration(
                            labelText:
                                'سعر الصرف (مقابل 1 ${controller.primaryCurrency.symbol})',
                            hintText: 'مثلاً: 3.75',
                            border: const OutlineInputBorder(),
                            suffixText: controller.localCurrency.symbol,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (val) =>
                              controller.updateExchangeRate(val),
                          // قيمة ابتدائية
                          controller:
                              TextEditingController(
                                  text: controller.exchangeRate.toString(),
                                )
                                ..selection = TextSelection.fromPosition(
                                  TextPosition(
                                    offset: controller.exchangeRate
                                        .toString()
                                        .length,
                                  ),
                                ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // خيار عرض العملتين في الفاتورة
              Obx(() {
                if (controller.isLocalSameAsPrimary) {
                  return const SizedBox.shrink();
                }
                return _buildSectionCard(
                  title: 'خيارات الفاتورة',
                  subtitle: 'تخصيص ما يظهر للعميل',
                  icon: Icons.receipt_long,
                  child: SwitchListTile(
                    title: const Text('إظهار العملتين في الفاتورة'),
                    subtitle: Text(
                      'عرض السعر بـ ${controller.primaryCurrency.symbol} و ${controller.localCurrency.symbol}',
                    ),
                    value: controller.showBothCurrenciesInInvoice,
                    onChanged: (val) =>
                        controller.toggleShowBothCurrencies(val),
                    contentPadding: EdgeInsets.zero,
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  /// ويدجت لبناء بطاقة القسم بشكل موحد وجميل
  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Get.theme.primaryColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: Get.textTheme.bodySmall,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }

  /// ويدجت لاختيار العملة (يظهر كزر أنيق)
  Widget _buildCurrencySelector({
    required BuildContext context,
    required String label,
    required CurrencyModel selectedCurrency,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${selectedCurrency.name} (${selectedCurrency.code})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Get.theme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Text(
                selectedCurrency.symbol,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Get.theme.primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  /// إظهار نافذة اختيار العملة
  void _showCurrencyPicker(
    BuildContext context,
    Function(CurrencyModel) onSelect,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'اختر العملة',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                itemCount: CurrencyModel.availableCurrencies.length,
                separatorBuilder: (_, __) =>
                    const Divider(indent: 20, endIndent: 20),
                itemBuilder: (ctx, index) {
                  final currency = CurrencyModel.availableCurrencies[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        currency.symbol,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    title: Text(currency.name),
                    subtitle: Text(currency.code),
                    onTap: () {
                      onSelect(currency);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
