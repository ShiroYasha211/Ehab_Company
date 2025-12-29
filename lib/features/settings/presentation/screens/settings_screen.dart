import 'package:ehab_company_admin/core/services/auth_service.dart';
import 'package:ehab_company_admin/features/settings/presentation/controllers/settings_controller.dart';
import 'package:ehab_company_admin/features/settings/presentation/screens/about_developer_screen.dart';
import 'package:ehab_company_admin/features/settings/presentation/screens/currency_settings_screen.dart';
import 'package:ehab_company_admin/features/settings/presentation/screens/data_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'لوحة التحكم والإعدادات',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('إعدادات النظام'),
            const SizedBox(height: 10),
            _buildSettingsCard(
              context,
              icon: Icons.currency_exchange,
              title: 'العملات والأسعار',
              subtitle: 'تخصيص العملة الأساسية والمحلية وأسعار الصرف',
              color: Colors.blue.shade700,
              onTap: () => Get.to(
                () => const CurrencySettingsScreen(),
                binding: BindingsBuilder.put(() => SettingsController()),
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionHeader('إدارة البيانات'),
            const SizedBox(height: 10),
            _buildSettingsCard(
              context,
              icon: Icons.backup_rounded,
              title: 'النسخ الاحتياطي والاستعادة',
              subtitle: 'حفظ نسخة من بياناتك واسترجاعها عند الحاجة',
              color: Colors.teal.shade700,
              onTap: () => Get.to(() => const DataManagementScreen()),
            ),
            // يمكن إضافة المزيد من الأقسام هنا مستقبلاً
            const SizedBox(height: 20),
            _buildSectionHeader('معلومات التطبيق'),
            const SizedBox(height: 10),
            _buildSettingsCard(
              context,
              icon: Icons.developer_mode_rounded,
              title: 'عن المطور',
              subtitle: 'معلومات الفريق المطور ووسائل التواصل',
              color: Colors.deepPurple.shade700,
              onTap: () => Get.to(() => const AboutDeveloperScreen()),
            ),
            const SizedBox(height: 10),

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: const ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange,
                  child: Icon(Icons.info_outline, color: Colors.white),
                ),
                title: Text('الإصدار v1.0.0'),
                subtitle: Text('شركة إيهاب للتجارة - جميع الحقوق محفوظة'),
              ),
            ),
            const SizedBox(height: 30),
            _buildLogoutButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
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
              Get.find<AuthService>().logout();
            },
          );
        },
        icon: const Icon(Icons.logout_rounded, color: Colors.red),
        label: const Text(
          'تسجيل الخروج',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15),
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shadowColor: color.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 30, color: color),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
