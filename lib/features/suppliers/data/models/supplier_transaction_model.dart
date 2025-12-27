// File: lib/features/suppliers/data/models/supplier_transaction_model.dart

enum SupplierTransactionType { PAYMENT, OPENING_BALANCE, PURCHASE, RETURN }

class SupplierTransactionModel {final int? id; // رقم السند
final int supplierId;
final SupplierTransactionType type;
final double amount;
final String? notes;
final DateTime transactionDate;
final bool affectsFund;
final String? supplierName;

// --- 1. بداية الإضافة: تعريف الخاصية الجديدة ---
final int? referenceId; // رقم الفاتورة أو المرتجع المرتبط
// --- نهاية الإضافة ---

SupplierTransactionModel({
  this.id,
  required this.supplierId,
  required this.type,
  required this.amount,
  this.notes,
  required this.transactionDate,
  required this.affectsFund,
  this.supplierName,
  // --- 2. بداية الإضافة: إضافة الخاصية إلى المُنشئ ---
  this.referenceId,
  // --- نهاية الإضافة ---
});

factory SupplierTransactionModel.fromMap(Map<String, dynamic> map) {
  return SupplierTransactionModel(
    id: map['id'],
    supplierId: map['supplierId'],
    type: SupplierTransactionType.values.firstWhere(
          (e) => e.toString().split('.').last == map['type'],
      orElse: () => SupplierTransactionType.PAYMENT, // قيمة افتراضية آمنة
    ),
    amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
    notes: map['notes'],
    transactionDate: DateTime.parse(map['transactionDate']),
    affectsFund: map['affectsFund'] == 1,
    supplierName: map['supplierName'],
    // --- 3. بداية الإضافة: قراءة الخاصية من قاعدة البيانات ---
    referenceId: map['referenceId'],
    // --- نهاية الإضافة ---
  );
}

Map<String, dynamic> toMap() {
  return {
    'id': id,
    'supplierId': supplierId,
    'type': type.toString().split('.').last,
    'amount': amount,
    'notes': notes,
    'transactionDate': transactionDate.toIso8601String(),
    'affectsFund': affectsFund ? 1 : 0,
    // --- 4. بداية الإضافة: إضافة الخاصية إلى دالة الحفظ ---
    'referenceId': referenceId,
    // --- نهاية الإضافة ---
  };
}
}
