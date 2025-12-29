// File: lib/features/settings/presentation/screens/settings_screen.dart

import 'package:ehab_company_admin/features/settings/presentation/screens/currency_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsScreen extends StatelessWidget {const SettingsScreen
(
{super.key});

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text('الإعدادات'),
),
body:
ListView
(
padding
:
const
EdgeInsets.all(16.0),
    children: [
    _buildSettingItem(
    icon: Icons.currency_exchange,
    title: 'إعدادات العملة',
    subtitle: 'تحديد العملة الأساسية، المحلية، وسعر الصرف.',
    onTap: () {
      Get.to(() => const CurrencySettingsScreen());
    },
),
    const Divider(),
    _buildSettingItem(
        icon: Icons.storage_rounded,
        title: 'إدارة البيانات',
        subtitle: 'إنشاء نسخ احتياطية واستعادة البيانات.',
        onTap: () {
          Get.snackbar('قيد الإنشاء', 'سيتم بناء هذه الميزة لاحقًا.');
        },
    ),
    ],
),);
}

Widget _buildSettingItem({
  required IconData icon,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
}) {
  return ListTile(
      leading: Icon(icon, size: 30, color: Get.theme.primaryColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
  );
}
}