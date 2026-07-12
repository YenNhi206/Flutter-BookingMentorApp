import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/repositories/booking_repository.dart';
import '../data/repositories/notification_repository.dart';
import '../models/booking.dart';
import '../models/mentor.dart';
import '../models/notification_item.dart';
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
  final NotificationRepository _notificationRepository;
  final _uuid = const Uuid();

  BookingProvider({
    BookingRepository? repository,
    NotificationRepository? notificationRepository,
  })  : _repository = repository ?? BookingRepository(),
        _notificationRepository = notificationRepository ?? NotificationRepository();

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

  /// Creates a booking after validating there's no existing slot conflict
  /// for the mentor, then raises an in-app + local push notification.
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

    final price = PricingService.calculateSessionPrice(
      hourlyRate: mentor.hourlyRate,
      durationMinutes: durationMinutes,
    );

    final booking = Booking(
      id: _uuid.v4(),
      studentId: studentId,
      mentorId: mentor.id,
      mentorName: mentor.name,
      sessionDate: sessionDate,
      timeSlot: timeSlot,
      durationMinutes: durationMinutes,
      price: price,
      status: BookingStatus.confirmed,
      notes: notes,
      createdAt: DateTime.now(),
    );

    await _repository.create(booking);

    final notification = NotificationItem(
      id: _uuid.v4(),
      userId: studentId,
      title: 'Booking confirmed',
      body: 'Your session with ${mentor.name} on ${_formatDate(sessionDate)} at $timeSlot is confirmed.',
      type: NotificationType.booking,
      relatedId: booking.id,
      createdAt: DateTime.now(),
    );
    await _notificationRepository.create(notification);
    await LocalNotificationService.instance.show(
      title: notification.title,
      body: notification.body,
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
