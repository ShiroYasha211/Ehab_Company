import 'package:ehab_company_admin/core/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/user_model.dart';

class EmployeeListScreen extends StatelessWidget {
  const EmployeeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // جلب خدمة المصادقة للوصول للمستخدمين (في الواقع هذه القائمة يجب أن تأتي من Controller أو Database)
    // حالياً سنعرض القائمة الوهمية الموجودة في AuthService
    final authService = Get.find<AuthService>();

    // للحصول على القائمة، سنقوم بمحاكاتها هنا مؤقتاً أو الوصول إليها إذا كانت عامة
    // بما أن _mockUsers هي private، سأستخدم قائمة محلية للمحاكاة في العرض
    final users = [
      UserModel(
        id: 1,
        name: 'الإدارة العامة (أدمن)',
        username: 'admin',
        password: '123',
        role: UserRole.admin,
        permissions: ['كل الصلاحيات'],
      ),
      UserModel(
        id: 2,
        name: 'مسؤول المبيعات',
        username: 'sales',
        password: '123',
        role: UserRole.salesManager,
        permissions: [
          AuthService.pViewDashboard,
          AuthService.pViewSales,
          AuthService.pAddSales,
          AuthService.pViewInventory,
        ],
      ),
      UserModel(
        id: 3,
        name: 'مسؤول المخازن',
        username: 'stock',
        password: '123',
        role: UserRole.stockManager,
        permissions: [
          AuthService.pViewDashboard,
          AuthService.pViewInventory,
          AuthService.pManageInventory,
          AuthService.pViewPurchases,
          AuthService.pAddPurchases,
        ],
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الموظفين والصلاحيات'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: Get.theme.primaryColor.withOpacity(0.1),
                child: Icon(Icons.person, color: Get.theme.primaryColor),
              ),
              title: Text(
                user.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'اسم المستخدم: ${user.username} | الدور: ${_getRoleText(user.role)}',
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'الصلاحيات الممنوحة:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: user.permissions
                            .map(
                              (p) => Chip(
                                label: Text(
                                  _getPermissionText(p),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor: Colors.teal.shade50,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getRoleText(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'مدير النظام';
      case UserRole.salesManager:
        return 'مدير مبيعات';
      case UserRole.stockManager:
        return 'مدير مخازن';
      case UserRole.employee:
        return 'موظف عام';
    }
  }

  String _getPermissionText(String p) {
    if (p == 'كل الصلاحيات') return p;
    switch (p) {
      case AuthService.pViewDashboard:
        return 'عرض لوحة التحكم';
      case AuthService.pManageUsers:
        return 'إدارة المستخدمين';
      case AuthService.pViewSales:
        return 'عرض المبيعات';
      case AuthService.pAddSales:
        return 'إضافة مبيعات';
      case AuthService.pViewPurchases:
        return 'عرض المشتريات';
      case AuthService.pAddPurchases:
        return 'إضافة مشتريات';
      case AuthService.pViewInventory:
        return 'عرض المخزون';
      case AuthService.pManageInventory:
        return 'إدارة المخزون';
      case AuthService.pViewReports:
        return 'عرض التقارير';
      case AuthService.pManageSettings:
        return 'إدارة الإعدادات';
      case AuthService.pManageMoney:
        return 'إدارة الأموال والعهدة';
      default:
        return p;
    }
  }
}
