enum BookingStatus { pending, confirmed, inProgress, completed, cancelled, rescheduled, noShow }

const _wireStatusOverrides = {
  'in_progress': BookingStatus.inProgress,
  'no_show': BookingStatus.noShow,
};

BookingStatus bookingStatusFromString(String value) {
  final override = _wireStatusOverrides[value];
  if (override != null) return override;
  return BookingStatus.values.firstWhere(
    (s) => s.name == value,
    orElse: () => BookingStatus.pending,
  );
}

/// Parses the backend's `DD/MM` or `DD/MM/YYYY` booking date string,
/// combined with a separate `HH:MM` time slot, into a [DateTime].
DateTime _parseBookingDateTime(String date, String timeSlot) {
  final dateParts = date.split('/');
  final day = dateParts.isNotEmpty ? int.tryParse(dateParts[0]) ?? 1 : 1;
  final month = dateParts.length > 1 ? int.tryParse(dateParts[1]) ?? 1 : 1;
  final year = dateParts.length > 2 ? int.tryParse(dateParts[2]) ?? DateTime.now().year : DateTime.now().year;
  final timeParts = timeSlot.split(':');
  final hour = timeParts.isNotEmpty ? int.tryParse(timeParts[0]) ?? 0 : 0;
  final minute = timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0;
  return DateTime(year, month, day, hour, minute);
}

/// Formats a [DateTime] as `DD/MM/YYYY`, the format the backend expects
/// when creating a booking.
String formatBookingDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

class Booking {
  final String id;
  final String studentId;
  final String mentorId;
  final String mentorName;
  final DateTime sessionDate;
  final String timeSlot;
  final int durationMinutes;
  final double price;
  final BookingStatus status;
  final String notes;
  final DateTime createdAt;

  const Booking({
    required this.id,
    required this.studentId,
    required this.mentorId,
    required this.mentorName,
    required this.sessionDate,
    required this.timeSlot,
    required this.durationMinutes,
    required this.price,
    required this.status,
    required this.notes,
    required this.createdAt,
  });

  Booking copyWith({BookingStatus? status}) => Booking(
        id: id,
        studentId: studentId,
        mentorId: mentorId,
        mentorName: mentorName,
        sessionDate: sessionDate,
        timeSlot: timeSlot,
        durationMinutes: durationMinutes,
        price: price,
        status: status ?? this.status,
        notes: notes,
        createdAt: createdAt,
      );

  factory Booking.fromJson(Map<String, dynamic> json) {
    final date = json['date'] as String? ?? '';
    final timeSlot = json['timeSlot'] as String? ?? '00:00';
    return Booking(
      id: (json['id'] ?? json['_id']).toString(),
      studentId: (json['userId'] ?? '').toString(),
      mentorId: (json['mentorId'] ?? '').toString(),
      mentorName: json['mentorName'] as String? ?? '',
      sessionDate: date.isEmpty ? DateTime.now() : _parseBookingDateTime(date, timeSlot),
      timeSlot: timeSlot,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 60,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      status: bookingStatusFromString(json['status'] as String? ?? 'pending'),
      notes: json['notes'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
