enum BookingStatus { pending, confirmed, completed, cancelled }

BookingStatus bookingStatusFromString(String value) {
  return BookingStatus.values.firstWhere(
    (s) => s.name == value,
    orElse: () => BookingStatus.pending,
  );
}

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

  Map<String, Object?> toMap() => {
        'id': id,
        'studentId': studentId,
        'mentorId': mentorId,
        'mentorName': mentorName,
        'sessionDate': sessionDate.toIso8601String(),
        'timeSlot': timeSlot,
        'durationMinutes': durationMinutes,
        'price': price,
        'status': status.name,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Booking.fromMap(Map<String, Object?> map) => Booking(
        id: map['id'] as String,
        studentId: map['studentId'] as String,
        mentorId: map['mentorId'] as String,
        mentorName: map['mentorName'] as String,
        sessionDate: DateTime.parse(map['sessionDate'] as String),
        timeSlot: map['timeSlot'] as String,
        durationMinutes: map['durationMinutes'] as int,
        price: (map['price'] as num).toDouble(),
        status: bookingStatusFromString(map['status'] as String),
        notes: (map['notes'] as String?) ?? '',
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
