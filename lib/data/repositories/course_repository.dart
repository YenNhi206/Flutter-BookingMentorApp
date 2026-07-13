import '../../core/api_client.dart';
import '../../models/course.dart';
import '../../models/enrollment.dart';
import '../../models/lesson.dart';

class CourseRepository {
  final ApiClient _apiClient;

  CourseRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<List<Course>> getPublished() async {
    final result = await _apiClient.get('/courses', auth: false) as Map<String, dynamic>;
    final courses = result['courses'] as List<dynamic>;
    return courses.map((c) => Course.fromJson(c as Map<String, dynamic>)).toList();
  }

  /// Backed by `/courses/me` (JWT-scoped to the calling mentor) - [mentorId]
  /// is vestigial, kept only for call-site signature compatibility.
  Future<List<Course>> getForMentor(String mentorId) async {
    final result = await _apiClient.get('/courses/me') as Map<String, dynamic>;
    final courses = result['courses'] as List<dynamic>;
    return courses.map((c) => Course.fromJson(c as Map<String, dynamic>)).toList();
  }

  Future<List<Course>> getPendingReview() async {
    final result = await _apiClient.get('/admin/courses/pending') as Map<String, dynamic>;
    final courses = result['courses'] as List<dynamic>;
    return courses.map((c) => Course.fromAdminPendingJson(c as Map<String, dynamic>)).toList();
  }

  Future<Course?> getById(String id) async {
    try {
      final result = await _apiClient.get('/courses/$id', auth: false) as Map<String, dynamic>;
      return Course.fromJson(result['course'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Wraps all lessons into a single chapter (the backend nests
  /// modules/lessons two levels deep; this app's editor UI has no module
  /// concept - see [Lesson]), then immediately publishes the freshly-created
  /// draft so it lands in "pending review", matching the app's existing
  /// course-authoring flow of submitting straight for admin approval.
  ///
  /// Known gap: the backend's create/update payload has no field for a
  /// lesson's free-text body (`normalizeCoursePayload` only accepts
  /// `title`/`duration` per lesson) - only title and duration are persisted.
  Future<void> create(Course course, List<Lesson> lessons) async {
    final body = {
      'title': course.title,
      'description': course.description,
      'price': course.price,
      'chapters': [
        {
          'title': 'Chapter 1',
          'lessons': [
            for (final l in lessons) {'title': l.title, 'duration': l.durationMinutes},
          ],
        },
      ],
    };
    final result = await _apiClient.post('/courses', body: body) as Map<String, dynamic>;
    final courseJson = result['course'] as Map<String, dynamic>;
    final id = (courseJson['id'] ?? courseJson['_id']).toString();
    await _apiClient.patch('/courses/$id/publish', body: const {});
  }

  /// Admin approve/reject map to distinct endpoints; reject requires a
  /// reason string the current admin UI doesn't collect yet, so a
  /// placeholder is sent.
  Future<void> updateStatus(String courseId, CourseStatus status) async {
    if (status == CourseStatus.published) {
      await _apiClient.patch('/admin/courses/$courseId/approve');
    } else {
      await _apiClient.patch(
        '/admin/courses/$courseId/reject',
        body: {'reason': 'Rejected by admin'},
      );
    }
  }

  Future<List<Lesson>> getLessons(String courseId) async {
    final course = await getById(courseId);
    return course?.lessons ?? const [];
  }

  // ── Enrollments ──────────────────────────────────────────────

  /// Backed by `/enrollments/my` (JWT-scoped) - [studentId] is vestigial,
  /// kept only for call-site signature compatibility.
  Future<List<Enrollment>> getEnrollmentsForStudent(String studentId) async {
    final result = await _apiClient.get('/enrollments/my') as Map<String, dynamic>;
    final enrollments = result['enrollments'] as List<dynamic>;
    return enrollments.map((e) => Enrollment.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// No single-enrollment-by-course endpoint exists, so this filters the
  /// student's full enrollment list client-side - fine for a small dataset.
  Future<Enrollment?> getEnrollment(String studentId, String courseId) async {
    final all = await getEnrollmentsForStudent(studentId);
    for (final e in all) {
      if (e.courseId == courseId) return e;
    }
    return null;
  }

  /// Free courses enroll immediately; paid courses would need a follow-up
  /// transfer-payment step (`PATCH /enrollments/:id/submit-transfer`), not
  /// implemented here since this app's course catalog only exercises free
  /// enrollment today.
  Future<Enrollment> enroll(String courseId) async {
    final result = await _apiClient.post('/courses/$courseId/enroll', body: const {}) as Map<String, dynamic>;
    return Enrollment.fromJson(result['enrollment'] as Map<String, dynamic>);
  }

  /// Server recalculates `progressPercent` from the given lesson toggle.
  Future<Enrollment> updateProgress(String enrollmentId, {required String lessonId, required bool isCompleted}) async {
    final result = await _apiClient.patch('/enrollments/$enrollmentId/progress', body: {
      'lessonId': lessonId,
      'isCompleted': isCompleted,
    }) as Map<String, dynamic>;
    return Enrollment.fromJson(result['enrollment'] as Map<String, dynamic>);
  }
}
