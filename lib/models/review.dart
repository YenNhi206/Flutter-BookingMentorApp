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

  /// Backend reviews are generic (`targetType`/`targetId`, not
  /// mentor-specific) - `targetId` only means "mentorId" when
  /// `targetType == 'mentor'`, which is the only kind this app creates/reads.
  factory Review.fromJson(Map<String, dynamic> json) {
    final reviewer = json['userId'];
    final studentId = reviewer is Map ? (reviewer['_id'] ?? '').toString() : (reviewer ?? '').toString();
    final studentName = reviewer is Map ? (reviewer['name'] as String? ?? '') : '';
    return Review(
      id: (json['id'] ?? json['_id']).toString(),
      mentorId: (json['targetId'] ?? '').toString(),
      studentId: studentId,
      studentName: studentName,
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
