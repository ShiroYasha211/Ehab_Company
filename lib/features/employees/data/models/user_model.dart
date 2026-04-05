enum UserRole { admin, salesManager, stockManager, employee }

class UserModel {
  final int id;
  final String name;
  final String username;
  final String password; // In a real app, this should be hashed
  final UserRole role;
  final List<String> permissions;

  UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.password,
    required this.role,
    required this.permissions,
  });

  String get roleName {
    switch (role) {
      case UserRole.admin:
        return 'إدارة النظام';
      case UserRole.salesManager:
        return 'مسؤول مبيعات';
      case UserRole.stockManager:
        return 'مسؤول مخازن';
      case UserRole.employee:
        return 'موظف';
    }
  }

  bool hasPermission(String permission) {
    if (role == UserRole.admin) return true;
    return permissions.contains(permission);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'password': password,
      'role': role.index,
      'permissions': permissions,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'],
      username: map['username'],
      password: map['password'],
      role: UserRole.values[map['role']],
      permissions: List<String>.from(map['permissions']),
    );
  }
}
