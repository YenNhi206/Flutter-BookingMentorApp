class Review {
  final String id;
  final String mentorId;
  final String studentId;
  final String studentName;
  final int rating;
  final String comment;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.mentorId,
    required this.studentId,
    required this.studentName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'mentorId': mentorId,
        'studentId': studentId,
        'studentName': studentName,
        'rating': rating,
        'comment': comment,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Review.fromMap(Map<String, Object?> map) => Review(
        id: map['id'] as String,
        mentorId: map['mentorId'] as String,
        studentId: map['studentId'] as String,
        studentName: map['studentName'] as String,
        rating: map['rating'] as int,
        comment: map['comment'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
