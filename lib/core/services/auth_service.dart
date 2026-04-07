import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/employees/data/models/user_model.dart';

class AuthService extends GetxService {
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  static const String _userKey = 'current_user_data';

  // قائمة الصلاحيات المتاحة في النظام
  static const String pViewDashboard = 'view_dashboard';
  static const String pManageUsers = 'manage_users';
  static const String pViewSales = 'view_sales';
  static const String pAddSales = 'add_sales';
  static const String pViewPurchases = 'view_purchases';
  static const String pAddPurchases = 'add_purchases';
  static const String pViewInventory = 'view_inventory';
  static const String pManageInventory = 'manage_inventory';
  static const String pViewReports = 'view_reports';
  static const String pManageSettings = 'manage_settings';
  static const String pManageMoney = 'manage_money'; // الصناديق والمصروفات

  // بيانات وهمية للمستخدمين للتجربة
  final List<UserModel> _mockUsers = [
    UserModel(
      id: 1,
      name: 'الإدارة العامة',
      username: 'admin',
      password: '123',
      role: UserRole.admin,
      permissions: [], // الأدمن لديه كل الصلاحيات
    ),
    UserModel(
      id: 2,
      name: 'مسؤول المبيعات',
      username: 'sales',
      password: '123',
      role: UserRole.salesManager,
      permissions: [
        pViewDashboard,
        pViewSales,
        pAddSales,
        pViewInventory, // يحتاج لرؤية المخزون للبيع
      ],
    ),
    UserModel(
      id: 3,
      name: 'مسؤول المخازن والمشتريات',
      username: 'stock',
      password: '123',
      role: UserRole.stockManager,
      permissions: [
        pViewDashboard,
        pViewInventory,
        pManageInventory,
        pViewPurchases,
        pAddPurchases,
      ],
    ),
  ];

  List<UserModel> get mockUsers => _mockUsers;

  @override
  void onInit() {
    super.onInit();
    _loadUserFromStorage();
  }

  Future<void> _loadUserFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);
    if (userData != null) {
      try {
        currentUser.value = UserModel.fromMap(jsonDecode(userData));
      } catch (e) {
        print('Error loading user: $e');
        await prefs.remove(_userKey);
      }
    }
  }

  bool get isLoggedIn => currentUser.value != null;

  Future<bool> login(String username, String password) async {
    // محاكاة تأخير الشبكة
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final user = _mockUsers.firstWhere(
        (u) => u.username == username && u.password == password,
      );
      currentUser.value = user;

      // حفظ بيانات المستخدم في التخزين المحلي
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(user.toMap()));

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    currentUser.value = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    Get.offAllNamed('/login');
  }

  bool hasPermission(String permission) {
    if (currentUser.value == null) return false;
    return currentUser.value!.hasPermission(permission);
  }
}
