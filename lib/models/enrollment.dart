class Enrollment {
  final String id;
  final String studentId;
  final String courseId;
  final double progressPercent;
  final List<String> completedLessonIds;
  final DateTime enrolledAt;
  final bool certificateIssued;

  const Enrollment({
    required this.id,
    required this.studentId,
    required this.courseId,
    this.progressPercent = 0,
    this.completedLessonIds = const [],
    required this.enrolledAt,
    this.certificateIssued = false,
  });

  factory Enrollment.fromJson(Map<String, dynamic> json) {
    final courseIdField = json['courseId'];
    final courseId = courseIdField is Map
        ? (courseIdField['_id'] ?? courseIdField['id'] ?? '').toString()
        : (courseIdField ?? '').toString();
    final progressPercent = (json['progressPercent'] as num?)?.toDouble() ?? 0;
    return Enrollment(
      id: (json['id'] ?? json['_id']).toString(),
      studentId: (json['userId'] ?? '').toString(),
      courseId: courseId,
      progressPercent: progressPercent,
      completedLessonIds:
          (json['completedLessons'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      enrolledAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      certificateIssued: (json['isCompleted'] as bool? ?? false) || progressPercent >= 100,
    );
  }
}
