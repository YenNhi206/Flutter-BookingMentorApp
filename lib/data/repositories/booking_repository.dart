import '../../models/booking.dart';
import '../db/app_database.dart';

class BookingRepository {
  Future<List<Booking>> getForStudent(String studentId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'bookings',
      where: 'studentId = ?',
      whereArgs: [studentId],
      orderBy: 'sessionDate DESC',
    );
    return rows.map(Booking.fromMap).toList();
  }

  Future<List<Booking>> getForMentor(String mentorId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'bookings',
      where: 'mentorId = ?',
      whereArgs: [mentorId],
      orderBy: 'sessionDate DESC',
    );
    return rows.map(Booking.fromMap).toList();
  }

  Future<List<Booking>> getAll() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('bookings', orderBy: 'sessionDate DESC');
    return rows.map(Booking.fromMap).toList();
  }

  Future<void> create(Booking booking) async {
    final db = await AppDatabase.instance.database;
    await db.insert('bookings', booking.toMap());
  }

  Future<void> updateStatus(String bookingId, BookingStatus status) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'bookings',
      {'status': status.name},
      where: 'id = ?',
      whereArgs: [bookingId],
    );
  }
}
