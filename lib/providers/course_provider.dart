import 'package:flutter/foundation.dart';

import '../data/repositories/course_repository.dart';
import '../models/course.dart';
import '../models/enrollment.dart';
import '../models/lesson.dart';

class CourseProvider extends ChangeNotifier {
  final CourseRepository _repository;

  CourseProvider({CourseRepository? repository}) : _repository = repository ?? CourseRepository();

  List<Course> _published = [];
  List<Enrollment> _myEnrollments = [];
  bool _isLoading = false;

  List<Course> get published => _published;
  List<Enrollment> get myEnrollments => _myEnrollments;
  bool get isLoading => _isLoading;

  Future<void> loadPublished() async {
    _isLoading = true;
    notifyListeners();
    _published = await _repository.getPublished();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMyEnrollments(String studentId) async {
    _myEnrollments = await _repository.getEnrollmentsForStudent(studentId);
    notifyListeners();
  }

  Future<Course?> getById(String id) => _repository.getById(id);
  Future<List<Lesson>> getLessons(String courseId) => _repository.getLessons(courseId);
  Future<Enrollment?> getEnrollment(String studentId, String courseId) =>
      _repository.getEnrollment(studentId, courseId);

  Future<Enrollment> enroll(String studentId, String courseId) async {
    final enrollment = await _repository.enroll(courseId);
    await loadMyEnrollments(studentId);
    return enrollment;
  }

  Future<Enrollment> toggleLessonComplete({
    required Enrollment enrollment,
    required String lessonId,
  }) async {
    final isCompleted = !enrollment.completedLessonIds.contains(lessonId);
    final updated = await _repository.updateProgress(enrollment.id, lessonId: lessonId, isCompleted: isCompleted);
    await loadMyEnrollments(enrollment.studentId);
    return updated;
  }

  // ── Mentor: course authoring ─────────────────────────────────

  Future<List<Course>> getForMentor(String mentorId) => _repository.getForMentor(mentorId);

  Future<void> createCourse({
    required String mentorId,
    required String mentorName,
    required String title,
    required String description,
    required double price,
    required String thumbnailUrl,
    required List<({String title, String content, int durationMinutes})> lessons,
  }) async {
    final course = Course(
      id: '',
      mentorId: mentorId,
      mentorName: mentorName,
      title: title,
      description: description,
      thumbnailUrl: thumbnailUrl,
      price: price,
      status: CourseStatus.pendingReview,
      createdAt: DateTime.now(),
    );
    final lessonModels = <Lesson>[
      for (var i = 0; i < lessons.length; i++)
        Lesson(
          id: '',
          courseId: course.id,
          title: lessons[i].title,
          content: lessons[i].content,
          durationMinutes: lessons[i].durationMinutes,
          orderIndex: i,
        ),
    ];
    await _repository.create(course, lessonModels);
  }

  // ── Admin: approval workflow ──────────────────────────────────

  Future<List<Course>> getPendingReview() => _repository.getPendingReview();

  Future<void> approve(String courseId) => _repository.updateStatus(courseId, CourseStatus.published);

  Future<void> reject(String courseId) => _repository.updateStatus(courseId, CourseStatus.rejected);
}
