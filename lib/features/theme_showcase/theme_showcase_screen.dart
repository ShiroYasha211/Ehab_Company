// File: lib/features/theme_showcase/theme_showcase_screen.dart

import 'package:ehab_company_admin/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class ThemeShowcaseScreen extends StatelessWidget {
  const ThemeShowcaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('استعراض هوية التطبيق'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_outlined)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- قسم الألوان ---
            _buildSectionTitle(context, 'لوحة الألوان (Color Palette)'),
            _buildColorPalette(),
            const SizedBox(height: 24),

            // --- قسم الخطوط ---
            _buildSectionTitle(context, 'الخطوط (Typography)'),
            const Text('هذا هو النص الأساسي Body. مرحباً بك في نظام شركة إيهاب.', style: TextStyle(fontSize: 16)),
            Text('نص ثانوي وصفي', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Text('عنوان فرعي H6', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),

            // --- قسم الأزرار ---
            _buildSectionTitle(context, 'الأزرار (Buttons)'),
            Row(
              children: [
                Expanded(child: ElevatedButton(onPressed: () {}, child: const Text('زر أساسي'))),
                const SizedBox(width: 16),
                Expanded(child: OutlinedButton(onPressed: () {}, child: const Text('زر ثانوي'))),
              ],
            ),
            const SizedBox(height: 24),

            // --- قسم حقول الإدخال ---
            _buildSectionTitle(context, 'حقول الإدخال (Input Fields)'),
            const TextField(
              decoration: InputDecoration(
                labelText: 'اسم المستخدم',
                hintText: 'ادخل اسم المستخدم هنا',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'كلمة المرور',
                prefixIcon: Icon(Icons.lock_outline),
                suffixIcon: Icon(Icons.visibility_off_outlined),
              ),
            ),
            const SizedBox(height: 24),

            // --- قسم البطاقات والقوائم ---
            _buildSectionTitle(context, 'البطاقات والقوائم (Cards & Lists)'),
            Card(
              child: Column(
                children: [
                  const ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.secondaryColor,
                      child: Icon(Icons.store_outlined, color: Colors.white),
                    ),
                    title: Text('إدارة المخزون', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('إضافة وتعديل المنتجات'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.successColor,
                      child: Icon(Icons.check_circle_outline, color: Colors.white),
                    ),
                    title: const Text('عملية ناجحة', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('تمت مزامنة البيانات بنجاح'),
                    trailing: Text('الآن', style: Theme.of(context).textTheme.bodySmall),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: 'إضافة جديدة',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildColorPalette() {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: const [
        _ColorChip(name: 'Primary', color: AppTheme.primaryColor),
        _ColorChip(name: 'Secondary', color: AppTheme.secondaryColor),
        _ColorChip(name: 'Success', color: AppTheme.successColor),
        _ColorChip(name: 'Error', color: AppTheme.errorColor),
        _ColorChip(name: 'Warning', color: AppTheme.warningColor),
        _ColorChip(name: 'Background', color: AppTheme.backgroundColor),
      ],
    );
  }
}

class _ColorChip extends StatelessWidget {
  final String name;
  final Color color;

  const _ColorChip({required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    bool isDark = color.computeLuminance() < 0.5;
    return Chip(
      label: Text(name, style: TextStyle(color: isDark ? Colors.white : AppTheme.textPrimaryColor)),
      backgroundColor: color,
      side: BorderSide(color: Colors.grey.shade300),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
    );
  }
}

