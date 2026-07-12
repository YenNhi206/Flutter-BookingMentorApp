import 'package:flutter/foundation.dart';

import '../data/repositories/auth_repository.dart';
import '../data/repositories/booking_repository.dart';
import '../data/repositories/mentor_repository.dart';
import '../models/booking.dart';
import '../models/mentor.dart';
import '../models/user_profile.dart';

/// Drives the admin dashboard: platform-wide stats, user/mentor management,
/// and mentor approval workflow.
class AdminProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  final MentorRepository _mentorRepository;
  final BookingRepository _bookingRepository;

  AdminProvider({
    AuthRepository? authRepository,
    MentorRepository? mentorRepository,
    BookingRepository? bookingRepository,
  })  : _authRepository = authRepository ?? AuthRepository(),
        _mentorRepository = mentorRepository ?? MentorRepository(),
        _bookingRepository = bookingRepository ?? BookingRepository();

  List<UserProfile> _users = [];
  List<Mentor> _mentors = [];
  List<Booking> _bookings = [];
  bool _isLoading = false;

  List<UserProfile> get users => _users;
  List<Mentor> get mentors => _mentors;
  List<Booking> get bookings => _bookings;
  bool get isLoading => _isLoading;

  List<Mentor> get pendingMentors =>
      _mentors.where((m) => m.status == MentorStatus.pending).toList();

  int get totalRevenue => _bookings
      .where((b) => b.status == BookingStatus.confirmed || b.status == BookingStatus.completed)
      .fold(0, (sum, b) => sum + b.price.round());

  Map<BookingStatus, int> get bookingsByStatus {
    final map = <BookingStatus, int>{for (final s in BookingStatus.values) s: 0};
    for (final b in _bookings) {
      map[b.status] = (map[b.status] ?? 0) + 1;
    }
    return map;
  }

  Future<void> loadAll() async {
    _isLoading = true;
    notifyListeners();
    _users = await _authRepository.getAll();
    _mentors = await _mentorRepository.getAllForAdmin();
    _bookings = await _bookingRepository.getAll();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setUserActive(String userId, bool isActive) async {
    await _authRepository.updateActive(userId, isActive);
    _users = await _authRepository.getAll();
    notifyListeners();
  }

  Future<void> setMentorActive(String mentorId, bool isActive) async {
    await _mentorRepository.updateActive(mentorId, isActive);
    _mentors = await _mentorRepository.getAllForAdmin();
    notifyListeners();
  }

  Future<void> approveMentor(String mentorId) async {
    await _mentorRepository.updateStatus(mentorId, MentorStatus.approved);
    _mentors = await _mentorRepository.getAllForAdmin();
    notifyListeners();
  }

  Future<void> rejectMentor(String mentorId) async {
    await _mentorRepository.updateStatus(mentorId, MentorStatus.rejected);
    _mentors = await _mentorRepository.getAllForAdmin();
    notifyListeners();
  }
}
