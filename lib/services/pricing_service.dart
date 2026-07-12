import '../models/booking.dart';

/// Pure business-logic helpers for booking pricing and slot conflicts.
/// Kept free of Flutter/DB imports so it can be unit tested in isolation.
class PricingService {
  /// Price is prorated from the mentor's hourly rate.
  static double calculateSessionPrice({
    required double hourlyRate,
    required int durationMinutes,
  }) {
    if (hourlyRate < 0) {
      throw ArgumentError('hourlyRate cannot be negative');
    }
    if (durationMinutes <= 0) {
      throw ArgumentError('durationMinutes must be positive');
    }
    final raw = hourlyRate * durationMinutes / 60;
    return double.parse(raw.toStringAsFixed(2));
  }

  /// Returns true if [mentorId] already has a non-cancelled booking on the
  /// same calendar day and time slot.
  static bool hasSlotConflict({
    required List<Booking> existingBookings,
    required String mentorId,
    required DateTime sessionDate,
    required String timeSlot,
  }) {
    return existingBookings.any((b) =>
        b.mentorId == mentorId &&
        b.status != BookingStatus.cancelled &&
        b.timeSlot == timeSlot &&
        b.sessionDate.year == sessionDate.year &&
        b.sessionDate.month == sessionDate.month &&
        b.sessionDate.day == sessionDate.day);
  }
}
