enum ActivityType {
  auth,
  sale,
  purchase,
  inventory,
  expense,
  fund,
  system,
  admin,
}

class ActivityModel {
  final int? id;
  final int? userId;
  final String? userName;
  final String? userRole;
  final String action;
  final String? details;
  final ActivityType type;
  final DateTime time;
  final String? deviceInfo;
  final DateTime createdAt;

  ActivityModel({
    this.id,
    this.userId,
    this.userName,
    this.userRole,
    required this.action,
    this.details,
    required this.type,
    required this.time,
    this.deviceInfo,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userRole': userRole,
      'action': action,
      'details': details,
      'type': type.name,
      'time': time.toIso8601String(),
      'deviceInfo': deviceInfo,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ActivityModel.fromMap(Map<String, dynamic> map) {
    return ActivityModel(
      id: map['id'],
      userId: map['userId'],
      userName: map['userName'],
      userRole: map['userRole'],
      action: map['action'] ?? '',
      details: map['details'],
      type: ActivityType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ActivityType.system,
      ),
      time: DateTime.parse(map['time']),
      deviceInfo: map['deviceInfo'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
