// File: lib/features/categories/data/repositories/category_repository.dart

import 'package:ehab_company_admin/core/database/database_service.dart';
import 'package:ehab_company_admin/features/categories/data/models/category_model.dart';
import 'package:sqflite/sqflite.dart';

class CategoryRepository {
  final DatabaseService _dbService = DatabaseService();

  Future<int> addCategory(CategoryModel category) async {
    final db = await _dbService.database;
    return await db.insert('categories', category.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore); // تجاهل الإضافة إذا كان الاسم مكررًا
  }

  Future<int> deleteCategory(int id) async {
    final db = await _dbService.database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<CategoryModel>> getAllCategories() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query('categories', orderBy: 'name ASC');
    if (maps.isEmpty) return [];
    return List.generate(maps.length, (i) => CategoryModel.fromMap(maps[i]));
  }
}
