import 'package:ehab_company_admin/features/products/data/models/product_model.dart';

/// كلاس مساعد لتخزين بيانات المنتج داخل فاتورة المشتريات
class PurchaseInvoiceItem {
  final ProductModel product;
  double quantity;
  double freeQuantity; // الكمية المجانية (البونص)
  
  // سعر الشراء الفعلي للوحدة المختارة (يستخدم في حساب إجمالي الفاتورة والـ PDF)
  double purchasePrice;
  
  // سعر الشراء والبيع للوحدة الكبرى (يستخدم لتحديث بيانات المنتج عالمياً)
  double rootPurchasePrice;
  double? newSalePrice; // سعر البيع المقترح للوحدة الكبرى
  
  int? selectedUnitId; // الوحدة التي تم الشراء بها حالياً

  PurchaseInvoiceItem({
    required this.product,
    this.quantity = 1.0,
    this.freeQuantity = 0.0,
    required this.purchasePrice,
    required this.rootPurchasePrice,
    this.newSalePrice,
    this.selectedUnitId,
  });

  // المجموع الفعلي لهذه السطر: الكمية المشتراة × سعر الوحدة المختارة
  double get subtotal => quantity * purchasePrice;
}
