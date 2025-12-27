// File: lib/features/customers/data/models/customer_transaction_model.dart

enum CustomerTransactionType {
  RECEIPT, // سند قبض (دفعة من العميل)
  OPENING_BALANCE, // رصيد افتتاحي
  SALE, // فاتورة بيع آجلة
  RETURN, // مرتجع مبيعات
}

class CustomerTransactionModel {
  final int? id;
  final int customerId;
  final CustomerTransactionType type;
  final double amount;
  final String? notes;
  final DateTime transactionDate;
  final bool affectsFund; // هل هذه الحركة تؤثر على الصندوق؟
  final String? customerName;

  // --- 1. بداية الإضافة: تعريف الخاصية الجديدة ---
  final int? referenceId; // رقم الفاتورة أو المرتجع المرتبط
  // --- نهاية الإضافة ---

  CustomerTransactionModel({
    this.id,
    required this.customerId,
    required this.type,
    required this.amount,
    this.notes,
    required this.transactionDate,
    required this.affectsFund,
    this.customerName,
    // --- 2. بداية الإضافة: إضافة الخاصية إلى المُنشئ ---
    this.referenceId,
    // --- نهاية الإضافة ---
  });

  // لتحويل البيانات من قاعدة البيانات إلى كائن
  factory CustomerTransactionModel.fromMap(Map<String, dynamic> map) {
    return CustomerTransactionModel(
      id: map['id'],
      customerId: map['customerId'],
      type: CustomerTransactionType.values.firstWhere(
              (e) => e.toString().split('.').last == map['type'],
          orElse: () => CustomerTransactionType.RECEIPT),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'],
      transactionDate: DateTime.parse(map['transactionDate']),
      affectsFund: map['affectsFund'] == 1,
      customerName: map['customerName'],
      // --- 3. بداية الإضافة: قراءة الخاصية من قاعدة البيانات ---
      referenceId: map['referenceId'],
      // --- نهاية الإضافة ---
    );
  }

  // لتحويل الكائن إلى Map لحفظه في قاعدة البيانات
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
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
