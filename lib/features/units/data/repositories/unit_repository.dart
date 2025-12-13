import 'package:ehab_company_admin/core/database/database_service.dart';
import 'package:ehab_company_admin/features/units/data/models/unit_model.dart';
import 'package:sqflite/sqflite.dart';

class UnitRepository {
  final DatabaseService _dbService = DatabaseService();

  Future<int> addUnit(UnitModel unit) async {
    final db = await _dbService.database;
    return await db.insert('units', unit.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<int> deleteUnit(int id) async {
    final db = await _dbService.database;
    return await db.delete('units', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<UnitModel>> getAllUnits() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query('units', orderBy: 'name ASC');
    if (maps.isEmpty) return [];
    return List.generate(maps.length, (i) => UnitModel.fromMap(maps[i]));
  }
}
