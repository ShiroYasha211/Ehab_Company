// File: lib/features/products/data/repositories/product_repository.dart

import 'package:ehab_company_admin/core/database/database_service.dart';
import 'package:ehab_company_admin/features/products/data/models/product_model.dart';
import 'package:sqflite/sqflite.dart';

class ProductRepository {
  final DatabaseService _dbService = DatabaseService();

  // جلب كل المنتجات من قاعدة البيانات
  Future<List<ProductModel>> getAllProducts() async {
    final db = await _dbService.database;
    // ترتيب المنتجات حسب تاريخ الإضافة (الأحدث أولاً)
    final List<Map<String, dynamic>> maps = await db.query(
        'products', orderBy: 'createdAt DESC');

    if (maps.isEmpty) {
      return [];
    }

    return List.generate(maps.length, (i) => ProductModel.fromMap(maps[i]));
  }

  // إضافة منتج جديد
  Future<int> addProduct(ProductModel product) async {
    final db = await _dbService.database;
    // استخدام conflictAlgorithm.replace لتجنب مشاكل إدخال كود فريد مكرر
    // إذا أردت أن يظهر خطأ بدلاً من الاستبدال، استخدم .fail
    return await db.insert(
      'products',
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // تعديل منتج موجود
  Future<int> updateProduct(ProductModel product) async {
    final db = await _dbService.database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  // حذف منتج
  Future<int> deleteProduct(int id) async {
    final db = await _dbService.database;
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> bulkUpdatePrices({
    String? category, // لتحديد القسم، أو null للكل
    required String targetPriceField, // 'salePrice' أو 'purchasePrice'
    required String operationType, // '+' للزيادة, '-' للنقصان
    required String calculationMethod, // 'amount', 'percentage', أو 'currency'
    required double value1, // القيمة الأولى (المبلغ، النسبة، أو سعر الصرف القديم)
    double? value2, // القيمة الثانية (سعر الصرف الجديد)
  }) async {
    final db = await _dbService.database;
    String sqlQuery;

    // بناء جملة التحديث بناءً على طريقة الحساب
    switch (calculationMethod) {
      case 'amount':
      // --- بداية التعديل: إضافة ROUND ---
        sqlQuery =
        'UPDATE products SET $targetPriceField = ROUND($targetPriceField $operationType $value1, 2)';
        // --- نهاية التعديل ---
        break;
      case 'percentage':
      // عملية حسابية للنسبة: السعر الجديد = السعر الحالي +/- (السعر الحالي * النسبة / 100)
      // --- بداية التعديل: إضافة ROUND ---
        sqlQuery =
        'UPDATE products SET $targetPriceField = ROUND($targetPriceField $operationType ($targetPriceField * $value1 / 100), 2)';
        // --- نهاية التعديل ---
        break;
      case 'currency':
      // عملية حسابية لفارق الصرف (تُطبق عادةً على سعر الشراء)
      // السعر الجديد = (السعر القديم / سعر الصرف القديم) * سعر الصرف الجديد
      // value1 = سعر الصرف القديم, value2 = سعر الصرف الجديد
        if (value2 == null) throw Exception('السعر الجديد للصرف مطلوب');
        // --- بداية التعديل: إضافة ROUND ---
        sqlQuery =
        'UPDATE products SET $targetPriceField = ROUND(($targetPriceField / $value1) * $value2, 2)';
        // --- نهاية التعديل ---
        break;
      default:
        throw Exception('طريقة حساب غير معروفة');
    }

    // إضافة شرط القسم إذا تم تحديده
    if (category != null && category.isNotEmpty) {
      sqlQuery += ' WHERE category = "$category"';
    }

    // تنفيذ الاستعلام الخام على قاعدة البيانات
    return await db.rawUpdate(sqlQuery);
  }

  Future<double> getTotalInventoryValue() async {
    final db = await _dbService.database;
    // حساب (كمية كل منتج * سعر شرائه) ثم جمع كل النتائج
    final result = await db.rawQuery('''
      SELECT SUM(quantity * purchasePrice) as totalValue 
      FROM products
    ''');

    if (result.first['totalValue'] != null) {
      return result.first['totalValue'] as double;
    }
    return 0.0;
  }
// --- نهاية الإضافة ---

  Future<int> getProductsCount() async {
    final db = await _dbService.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM products');
    if (result.first['count'] != null) {
      return result.first['count'] as int;
    }
    return 0;
  }

}
