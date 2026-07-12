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

  Enrollment copyWith({
    double? progressPercent,
    List<String>? completedLessonIds,
    bool? certificateIssued,
  }) {
    return Enrollment(
      id: id,
      studentId: studentId,
      courseId: courseId,
      progressPercent: progressPercent ?? this.progressPercent,
      completedLessonIds: completedLessonIds ?? this.completedLessonIds,
      enrolledAt: enrolledAt,
      certificateIssued: certificateIssued ?? this.certificateIssued,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'studentId': studentId,
        'courseId': courseId,
        'progressPercent': progressPercent,
        'completedLessonIds': completedLessonIds.join('|'),
        'enrolledAt': enrolledAt.toIso8601String(),
        'certificateIssued': certificateIssued ? 1 : 0,
      };

  factory Enrollment.fromMap(Map<String, Object?> map) => Enrollment(
        id: map['id'] as String,
        studentId: map['studentId'] as String,
        courseId: map['courseId'] as String,
        progressPercent: (map['progressPercent'] as num).toDouble(),
        completedLessonIds:
            (map['completedLessonIds'] as String).split('|').where((e) => e.isNotEmpty).toList(),
        enrolledAt: DateTime.parse(map['enrolledAt'] as String),
        certificateIssued: (map['certificateIssued'] as int) == 1,
      );
}
