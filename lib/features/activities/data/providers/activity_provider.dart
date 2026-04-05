import 'package:ehab_company_admin/core/database/database_service.dart';
import '../models/activity_model.dart';

class ActivityProvider {
  final DatabaseService _dbService = DatabaseService();

  Future<int> recordActivity(ActivityModel activity) async {
    final db = await _dbService.database;
    return await db.insert('activities', activity.toMap());
  }

  Future<List<ActivityModel>> getAllActivities() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'activities',
      orderBy: 'time DESC',
    );
    return List.generate(maps.length, (i) => ActivityModel.fromMap(maps[i]));
  }

  Future<List<ActivityModel>> getActivitiesByUser(int userId) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'activities',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'time DESC',
    );
    return List.generate(maps.length, (i) => ActivityModel.fromMap(maps[i]));
  }

  Future<void> clearOldActivities(DateTime before) async {
    final db = await _dbService.database;
    await db.delete(
      'activities',
      where: 'time < ?',
      whereArgs: [before.toIso8601String()],
    );
  }
}
