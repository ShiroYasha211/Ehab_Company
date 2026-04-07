import 'package:flutter/material.dart';

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

extension ActivityTypeExt on ActivityType {
  String get label {
    switch (this) {
      case ActivityType.auth: return 'الأمان والدخول';
      case ActivityType.sale: return 'المبيعات';
      case ActivityType.purchase: return 'المشتريات';
      case ActivityType.inventory: return 'المخازن';
      case ActivityType.expense: return 'المصروفات';
      case ActivityType.fund: return 'الصناديق';
      case ActivityType.system: return 'النظام';
      case ActivityType.admin: return 'الإدارة';
    }
  }

  Color get color {
    switch (this) {
      case ActivityType.auth: return Colors.blue;
      case ActivityType.sale: return Colors.green;
      case ActivityType.purchase: return Colors.orange;
      case ActivityType.inventory: return Colors.brown;
      case ActivityType.expense: return Colors.red;
      case ActivityType.fund: return Colors.teal;
      case ActivityType.system: return Colors.grey;
      case ActivityType.admin: return Colors.purple;
    }
  }
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
