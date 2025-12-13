// File: lib/features/suppliers/data/models/supplier_model.dart

import 'package:equatable/equatable.dart'; // <-- 1. إضافة هذا السطر

// --- 2. تغيير`class SupplierModel` إلى `class SupplierModel extends Equatable` ---
class SupplierModel extends Equatable {
  final int? id;
  final String name;
  final String? phone;
  final String? address;
  final String? email;
  final DateTime createdAt;
  final String? company;
  final String? commercialRecord;
  final String? notes;
  final double balance;

  const SupplierModel({ // <-- 3. يجب أن يكون الكونستركتور const
    this.id,
    required this.name,
    this.phone,
    this.address,
    this.email,
    required this.createdAt,
    this.company,
    this.commercialRecord,
    this.notes,
    this.balance = 0.0,
  });

  factory SupplierModel.fromMap(Map<String, dynamic> map) {
    return SupplierModel(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      address: map['address'],
      email: map['email'],
      createdAt: DateTime.parse(map['createdAt']),
      company: map['company'],
      commercialRecord: map['commercialRecord'],
      notes: map['notes'],
      balance: map['balance'] ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
      'company': company,
      'commercialRecord': commercialRecord,
      'notes': notes,
      'balance': balance,
    };
  }

  // --- 4. إضافة هذا الجزء (الأهم) ---
  @override
  List<Object?> get props => [id, name, phone, address, email, createdAt, company, commercialRecord, notes, balance];
}
