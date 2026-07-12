import '../../models/course.dart';
import '../../models/enrollment.dart';
import '../../models/lesson.dart';
import '../db/app_database.dart';

class CourseRepository {
  Future<List<Course>> getPublished() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'courses',
      where: 'status = ?',
      whereArgs: [CourseStatus.published.name],
      orderBy: 'createdAt DESC',
    );
    return rows.map(Course.fromMap).toList();
  }

  Future<List<Course>> getForMentor(String mentorId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'courses',
      where: 'mentorId = ?',
      whereArgs: [mentorId],
      orderBy: 'createdAt DESC',
    );
    return rows.map(Course.fromMap).toList();
  }

  Future<List<Course>> getPendingReview() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'courses',
      where: 'status = ?',
      whereArgs: [CourseStatus.pendingReview.name],
      orderBy: 'createdAt DESC',
    );
    return rows.map(Course.fromMap).toList();
  }

  Future<Course?> getById(String id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('courses', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Course.fromMap(rows.first);
  }

  Future<void> create(Course course, List<Lesson> lessons) async {
    final db = await AppDatabase.instance.database;
    final batch = db.batch();
    batch.insert('courses', course.toMap());
    for (final lesson in lessons) {
      batch.insert('lessons', lesson.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<void> updateStatus(String courseId, CourseStatus status) async {
    final db = await AppDatabase.instance.database;
    await db.update('courses', {'status': status.name}, where: 'id = ?', whereArgs: [courseId]);
  }

  Future<List<Lesson>> getLessons(String courseId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'lessons',
      where: 'courseId = ?',
      whereArgs: [courseId],
      orderBy: 'orderIndex ASC',
    );
    return rows.map(Lesson.fromMap).toList();
  }

  Future<void> insertSeedCourses(List<Course> courses, Map<String, List<Lesson>> lessonsByCourse) async {
    final db = await AppDatabase.instance.database;
    final batch = db.batch();
    for (final course in courses) {
      batch.insert('courses', course.toMap());
      for (final lesson in lessonsByCourse[course.id] ?? const <Lesson>[]) {
        batch.insert('lessons', lesson.toMap());
      }
    }
    await batch.commit(noResult: true);
  }

  // ── Enrollments ──────────────────────────────────────────────

  Future<List<Enrollment>> getEnrollmentsForStudent(String studentId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'enrollments',
      where: 'studentId = ?',
      whereArgs: [studentId],
      orderBy: 'enrolledAt DESC',
    );
    return rows.map(Enrollment.fromMap).toList();
  }

  Future<Enrollment?> getEnrollment(String studentId, String courseId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'enrollments',
      where: 'studentId = ? AND courseId = ?',
      whereArgs: [studentId, courseId],
    );
    if (rows.isEmpty) return null;
    return Enrollment.fromMap(rows.first);
  }

  Future<void> enroll(Enrollment enrollment) async {
    final db = await AppDatabase.instance.database;
    await db.insert('enrollments', enrollment.toMap());
  }

  Future<void> updateProgress(Enrollment enrollment) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'enrollments',
      enrollment.toMap(),
      where: 'id = ?',
      whereArgs: [enrollment.id],
    );
  }

  Future<int> countPaidEnrollments(String courseId) async {
    final db = await AppDatabase.instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM enrollments WHERE courseId = ?',
      [courseId],
    );
    return (result.first['count'] as int?) ?? 0;
  }
}
