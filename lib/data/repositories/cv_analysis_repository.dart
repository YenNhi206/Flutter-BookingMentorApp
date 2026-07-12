import '../../models/cv_analysis.dart';
import '../db/app_database.dart';

class CvAnalysisRepository {
  Future<List<CvAnalysis>> getForStudent(String studentId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'cv_analyses',
      where: 'studentId = ?',
      whereArgs: [studentId],
      orderBy: 'createdAt DESC',
    );
    return rows.map(CvAnalysis.fromMap).toList();
  }

  Future<void> create(CvAnalysis analysis) async {
    final db = await AppDatabase.instance.database;
    await db.insert('cv_analyses', analysis.toMap());
  }

  Future<void> delete(String id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('cv_analyses', where: 'id = ?', whereArgs: [id]);
  }
}
