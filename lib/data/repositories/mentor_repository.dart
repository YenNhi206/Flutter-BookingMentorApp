import '../../models/mentor.dart';
import '../db/app_database.dart';

class MentorRepository {
  /// Public catalog: only mentors that have been approved by an admin and
  /// are still active show up to students.
  Future<List<Mentor>> getAll() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'mentors',
      where: 'status = ? AND isActive = 1',
      whereArgs: [MentorStatus.approved.name],
      orderBy: 'rating DESC',
    );
    return rows.map(Mentor.fromMap).toList();
  }

  Future<Mentor?> getById(String id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('mentors', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Mentor.fromMap(rows.first);
  }

  Future<Mentor?> getByUserId(String userId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('mentors', where: 'userId = ?', whereArgs: [userId]);
    if (rows.isEmpty) return null;
    return Mentor.fromMap(rows.first);
  }

  Future<List<Mentor>> search(String query) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'mentors',
      where: '(name LIKE ? OR title LIKE ? OR expertise LIKE ?) AND status = ? AND isActive = 1',
      whereArgs: ['%$query%', '%$query%', '%$query%', MentorStatus.approved.name],
      orderBy: 'rating DESC',
    );
    return rows.map(Mentor.fromMap).toList();
  }

  /// Admin-only: every mentor regardless of approval/active state.
  Future<List<Mentor>> getAllForAdmin() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('mentors', orderBy: 'name ASC');
    return rows.map(Mentor.fromMap).toList();
  }

  Future<void> insertAll(List<Mentor> mentors) async {
    final db = await AppDatabase.instance.database;
    final batch = db.batch();
    for (final mentor in mentors) {
      batch.insert('mentors', mentor.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<void> create(Mentor mentor) async {
    final db = await AppDatabase.instance.database;
    await db.insert('mentors', mentor.toMap());
  }

  Future<void> updateStatus(String mentorId, MentorStatus status) async {
    final db = await AppDatabase.instance.database;
    await db.update('mentors', {'status': status.name}, where: 'id = ?', whereArgs: [mentorId]);
  }

  Future<void> updateActive(String mentorId, bool isActive) async {
    final db = await AppDatabase.instance.database;
    await db.update('mentors', {'isActive': isActive ? 1 : 0}, where: 'id = ?', whereArgs: [mentorId]);
  }
}
