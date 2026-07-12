import 'package:flutter_test/flutter_test.dart';
import 'package:mentor_link/models/booking.dart';
import 'package:mentor_link/services/pricing_service.dart';

void main() {
  group('PricingService.calculateSessionPrice', () {
    test('prorates the hourly rate by session duration', () {
      final price = PricingService.calculateSessionPrice(
        hourlyRate: 300000,
        durationMinutes: 60,
      );
      expect(price, 300000);
    });

    test('prorates correctly for a 30 minute session', () {
      final price = PricingService.calculateSessionPrice(
        hourlyRate: 300000,
        durationMinutes: 30,
      );
      expect(price, 150000);
    });

    test('throws for a non-positive duration', () {
      expect(
        () => PricingService.calculateSessionPrice(hourlyRate: 300000, durationMinutes: 0),
        throwsArgumentError,
      );
    });

    test('throws for a negative hourly rate', () {
      expect(
        () => PricingService.calculateSessionPrice(hourlyRate: -10, durationMinutes: 60),
        throwsArgumentError,
      );
    });
  });

  group('PricingService.hasSlotConflict', () {
    final mentorId = 'mentor-1';
    final sessionDate = DateTime(2026, 8, 1);

    Booking makeBooking({
      String mentorId = 'mentor-1',
      String timeSlot = '10:30',
      DateTime? date,
      BookingStatus status = BookingStatus.confirmed,
    }) {
      return Booking(
        id: 'b1',
        studentId: 's1',
        mentorId: mentorId,
        mentorName: 'Mentor',
        sessionDate: date ?? DateTime(2026, 8, 1),
        timeSlot: timeSlot,
        durationMinutes: 60,
        price: 300000,
        status: status,
        notes: '',
        createdAt: DateTime(2026, 7, 1),
      );
    }

    test('detects a conflict for the same mentor, date, and slot', () {
      final result = PricingService.hasSlotConflict(
        existingBookings: [makeBooking()],
        mentorId: mentorId,
        sessionDate: sessionDate,
        timeSlot: '10:30',
      );
      expect(result, isTrue);
    });

    test('ignores cancelled bookings when checking for conflicts', () {
      final result = PricingService.hasSlotConflict(
        existingBookings: [makeBooking(status: BookingStatus.cancelled)],
        mentorId: mentorId,
        sessionDate: sessionDate,
        timeSlot: '10:30',
      );
      expect(result, isFalse);
    });

    test('no conflict for a different time slot', () {
      final result = PricingService.hasSlotConflict(
        existingBookings: [makeBooking(timeSlot: '09:00')],
        mentorId: mentorId,
        sessionDate: sessionDate,
        timeSlot: '10:30',
      );
      expect(result, isFalse);
    });

    test('no conflict for a different mentor on the same slot', () {
      final result = PricingService.hasSlotConflict(
        existingBookings: [makeBooking(mentorId: 'mentor-2')],
        mentorId: mentorId,
        sessionDate: sessionDate,
        timeSlot: '10:30',
      );
      expect(result, isFalse);
    });
  });
}
