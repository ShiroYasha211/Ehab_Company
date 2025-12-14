// File: lib/features/customers/data/models/customer_model.dart

class CustomerModel {
  final int? id;
  final String name;
  final String? phone;
  final String? address;
  final String? email;
  final String? company;
  final String? notes;
  final double balance;
  final DateTime createdAt;

  CustomerModel({
    this.id,
    required this.name,
    this.phone,
    this.address,
    this.email,
    this.company,
    this.notes,
    required this.balance,
    required this.createdAt,
  });

  // لتحويل البيانات من قاعدة البيانات إلى كائن
  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      address: map['address'],
      email: map['email'],
      company: map['company'],
      notes: map['notes'],
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  // لتحويل الكائن إلى Map لحفظه في قاعدة البيانات
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'email': email,
      'company': company,
      'notes': notes,
      'balance': balance,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // دالة لتسهيل عملية النسخ مع التعديل
  CustomerModel copyWith({
    int? id,
    String? name,
    String? phone,
    String? address,
    String? email,
    String? company,
    String? notes,
    double? balance,
    DateTime? createdAt,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      email: email ?? this.email,
      company: company ?? this.company,
      notes: notes ?? this.notes,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
