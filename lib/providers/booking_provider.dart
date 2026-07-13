import 'package:flutter/foundation.dart';

import '../data/repositories/booking_repository.dart';
import '../models/booking.dart';
import '../models/mentor.dart';
import '../services/local_notification_service.dart';
import '../services/pricing_service.dart';

class BookingConflictException implements Exception {
  final String message;
  BookingConflictException(this.message);
  @override
  String toString() => message;
}

class BookingProvider extends ChangeNotifier {
  final BookingRepository _repository;

  BookingProvider({BookingRepository? repository}) : _repository = repository ?? BookingRepository();

  List<Booking> _myBookings = [];
  bool _isLoading = false;

  List<Booking> get myBookings => _myBookings;
  bool get isLoading => _isLoading;

  Future<void> loadForStudent(String studentId) async {
    _isLoading = true;
    notifyListeners();
    _myBookings = await _repository.getForStudent(studentId);
    _isLoading = false;
    notifyListeners();
  }

  /// Creates a booking after a best-effort client-side slot-conflict check
  /// (the server independently validates this too), then raises a local
  /// push notification. Price/status/id come back from the server - it
  /// computes price from the mentor's rate, this no longer does.
  Future<Booking> createBooking({
    required String studentId,
    required Mentor mentor,
    required DateTime sessionDate,
    required String timeSlot,
    required int durationMinutes,
    String notes = '',
  }) async {
    final existing = await _repository.getForMentor(mentor.id);
    if (PricingService.hasSlotConflict(
      existingBookings: existing,
      mentorId: mentor.id,
      sessionDate: sessionDate,
      timeSlot: timeSlot,
    )) {
      throw BookingConflictException('This time slot is already booked. Please pick another.');
    }

    final booking = await _repository.create(
      mentorId: mentor.id,
      sessionDate: sessionDate,
      timeSlot: timeSlot,
      durationMinutes: durationMinutes,
      notes: notes,
    );

    await LocalNotificationService.instance.show(
      title: 'Booking confirmed',
      body: 'Your session with ${mentor.name} on ${_formatDate(sessionDate)} at $timeSlot is confirmed.',
    );

    await loadForStudent(studentId);
    return booking;
  }

  Future<void> cancelBooking(String bookingId, String studentId) async {
    await _repository.updateStatus(bookingId, BookingStatus.cancelled);
    await loadForStudent(studentId);
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}
