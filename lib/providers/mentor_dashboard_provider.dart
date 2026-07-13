import 'package:flutter/foundation.dart';

import '../data/repositories/booking_repository.dart';
import '../data/repositories/course_repository.dart';
import '../data/repositories/mentor_repository.dart';
import '../models/booking.dart';
import '../models/course.dart';
import '../models/mentor.dart';

/// Drives the mentor-facing dashboard: resolves the logged-in mentor's
/// catalog profile, their bookings, their courses, and simple earnings
/// stats computed from completed/confirmed sessions.
class MentorDashboardProvider extends ChangeNotifier {
  final MentorRepository _mentorRepository;
  final BookingRepository _bookingRepository;
  final CourseRepository _courseRepository;

  MentorDashboardProvider({
    MentorRepository? mentorRepository,
    BookingRepository? bookingRepository,
    CourseRepository? courseRepository,
  })  : _mentorRepository = mentorRepository ?? MentorRepository(),
        _bookingRepository = bookingRepository ?? BookingRepository(),
        _courseRepository = courseRepository ?? CourseRepository();

  Mentor? _mentorProfile;
  List<Booking> _bookings = [];
  List<Course> _courses = [];
  bool _isLoading = false;

  Mentor? get mentorProfile => _mentorProfile;
  List<Booking> get bookings => _bookings;
  List<Course> get courses => _courses;
  bool get isLoading => _isLoading;

  int get upcomingCount =>
      _bookings.where((b) => b.status == BookingStatus.confirmed).length;

  double get totalEarnings => _bookings
      .where((b) => b.status == BookingStatus.confirmed || b.status == BookingStatus.completed)
      .fold(0.0, (sum, b) => sum + b.price);

  int get completedSessions =>
      _bookings.where((b) => b.status == BookingStatus.completed).length;

  Future<void> loadForUser(String userId) async {
    _isLoading = true;
    notifyListeners();
    _mentorProfile = await _mentorRepository.getByUserId(userId);
    if (_mentorProfile != null) {
      _bookings = await _bookingRepository.getForMentor(_mentorProfile!.id);
      _courses = await _courseRepository.getForMentor(_mentorProfile!.id);
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> confirmBooking(String bookingId) async {
    await _bookingRepository.updateStatus(bookingId, BookingStatus.confirmed, asMentor: true);
    if (_mentorProfile != null) {
      _bookings = await _bookingRepository.getForMentor(_mentorProfile!.id);
      notifyListeners();
    }
  }

  Future<void> markCompleted(String bookingId) async {
    await _bookingRepository.updateStatus(bookingId, BookingStatus.completed, asMentor: true);
    if (_mentorProfile != null) {
      _bookings = await _bookingRepository.getForMentor(_mentorProfile!.id);
      notifyListeners();
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    await _bookingRepository.updateStatus(bookingId, BookingStatus.cancelled, asMentor: true);
    if (_mentorProfile != null) {
      _bookings = await _bookingRepository.getForMentor(_mentorProfile!.id);
      notifyListeners();
    }
  }
}
