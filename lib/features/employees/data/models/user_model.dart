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

  bool hasPermission(String permission) {
    if (role == UserRole.admin) return true;
    return permissions.contains(permission);
  }
}
