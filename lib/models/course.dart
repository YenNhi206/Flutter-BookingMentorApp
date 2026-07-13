import 'lesson.dart';

enum CourseStatus { draft, pendingReview, published, rejected }

const _wireCourseStatusOverrides = {
  'pending_review': CourseStatus.pendingReview,
  'pending_update': CourseStatus.pendingReview,
};

CourseStatus courseStatusFromString(String value) {
  final override = _wireCourseStatusOverrides[value];
  if (override != null) return override;
  return CourseStatus.values.firstWhere(
    (s) => s.name == value,
    orElse: () => CourseStatus.draft,
  );
}

class Course {
  final String id;
  final String mentorId;
  final String mentorName;
  final String title;
  final String description;
  final String thumbnailUrl;
  final double price;
  final CourseStatus status;
  final DateTime createdAt;
  final List<Lesson> lessons;

  const Course({
    required this.id,
    required this.mentorId,
    required this.mentorName,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.price,
    this.status = CourseStatus.draft,
    required this.createdAt,
    this.lessons = const [],
  });

  Course copyWith({CourseStatus? status}) => Course(
        id: id,
        mentorId: mentorId,
        mentorName: mentorName,
        title: title,
        description: description,
        thumbnailUrl: thumbnailUrl,
        price: price,
        status: status ?? this.status,
        createdAt: createdAt,
        lessons: lessons,
      );

  /// Shared shape of `GET /courses`, `GET /courses/:id`, `GET /courses/me`,
  /// `POST /courses`, `PATCH /courses/:id/publish` - `mentorId` is either a
  /// populated object (list/detail) or a bare id string (mentor's own
  /// create/update/publish responses, where `mentorName` isn't available
  /// and defaults to empty since the caller already knows their own name).
  factory Course.fromJson(Map<String, dynamic> json) {
    final mentorIdField = json['mentorId'];
    String mentorId;
    String mentorName = '';
    if (mentorIdField is Map) {
      mentorId = (mentorIdField['_id'] ?? mentorIdField['id'] ?? '').toString();
      final userIdField = mentorIdField['userId'];
      if (userIdField is Map) mentorName = userIdField['name'] as String? ?? '';
    } else {
      mentorId = (mentorIdField ?? '').toString();
    }
    final id = (json['id'] ?? json['_id']).toString();
    return Course(
      id: id,
      mentorId: mentorId,
      mentorName: mentorName,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      thumbnailUrl: json['thumbnail'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      status: courseStatusFromString(json['status'] as String? ?? 'draft'),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      lessons: lessonsFromModulesJson(json['modules'], id),
    );
  }

  /// Admin's pending-review queue (`GET /admin/courses/pending`) returns a
  /// different DTO with course fields nested under `review` and mentor
  /// summary under `mentor` - always represents a pending course, so
  /// `status` is hardcoded rather than parsed.
  factory Course.fromAdminPendingJson(Map<String, dynamic> json) {
    final review = json['review'] as Map<String, dynamic>? ?? const {};
    final mentor = json['mentor'] as Map<String, dynamic>? ?? const {};
    final id = (json['_id'] ?? json['id']).toString();
    return Course(
      id: id,
      mentorId: '',
      mentorName: mentor['name'] as String? ?? '',
      title: review['title'] as String? ?? '',
      description: review['description'] as String? ?? '',
      thumbnailUrl: review['thumbnail'] as String? ?? '',
      price: (review['price'] as num?)?.toDouble() ?? 0,
      status: CourseStatus.pendingReview,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
