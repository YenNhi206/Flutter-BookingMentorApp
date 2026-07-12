import '../../models/review.dart';
import '../db/app_database.dart';

class ReviewRepository {
  Future<List<Review>> getForMentor(String mentorId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'reviews',
      where: 'mentorId = ?',
      whereArgs: [mentorId],
      orderBy: 'createdAt DESC',
    );
    return rows.map(Review.fromMap).toList();
  }

  Future<void> create(Review review) async {
    final db = await AppDatabase.instance.database;
    await db.insert('reviews', review.toMap());

    // Keep the mentor's aggregate rating in sync.
    final all = await getForMentor(review.mentorId);
    final avg = all.map((r) => r.rating).reduce((a, b) => a + b) / all.length;
    await db.update(
      'mentors',
      {'rating': double.parse(avg.toStringAsFixed(2)), 'reviewCount': all.length},
      where: 'id = ?',
      whereArgs: [review.mentorId],
    );
  }
}
