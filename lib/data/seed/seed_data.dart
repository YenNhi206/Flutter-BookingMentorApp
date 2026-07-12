import 'package:uuid/uuid.dart';

import '../../models/course.dart';
import '../../models/lesson.dart';
import '../../models/mentor.dart';
import '../../models/user_profile.dart';
import '../repositories/auth_repository.dart';
import '../repositories/course_repository.dart';
import '../repositories/mentor_repository.dart';
import '../db/app_database.dart';

const _uuid = Uuid();

/// Demo accounts used for grading/demoing (password for all: Demo1234)
const demoStudentEmail = 'student@demo.com';
const demoStudentPassword = 'Demo1234';
const demoMentorEmail = 'mentor@demo.com';
const demoAdminEmail = 'admin@demo.com';

/// Populates the local SQLite database with demo mentors, courses, and
/// student/mentor/admin accounts the first time the app launches on a
/// device.
class SeedData {
  /// Each concern below is seeded independently and is idempotent, so a
  /// device that already has partial data (e.g. from an earlier app
  /// version, before mentor/admin accounts existed) still ends up with a
  /// complete demo dataset after an app upgrade — not just on a fully
  /// fresh install.
  static Future<void> seedIfEmpty() async {
    final db = await AppDatabase.instance.database;
    final authRepo = AuthRepository();
    final mentorRepo = MentorRepository();

    final mentorRows = await db.query('mentors', limit: 1);
    if (mentorRows.isEmpty) {
      await mentorRepo.insertAll(_buildMentors(''));
    }

    final studentRows = await db.query('users', where: 'email = ?', whereArgs: [demoStudentEmail]);
    if (studentRows.isEmpty) {
      await authRepo.register(
        name: 'Demo Student',
        email: demoStudentEmail,
        password: demoStudentPassword,
        role: UserRole.student,
      );
    }

    final adminRows = await db.query('users', where: 'email = ?', whereArgs: [demoAdminEmail]);
    if (adminRows.isEmpty) {
      await authRepo.register(
        name: 'Platform Admin',
        email: demoAdminEmail,
        password: demoStudentPassword,
        role: UserRole.admin,
      );
    }

    // Link (or create) the demo mentor login to the "Nguyen Minh Anh"
    // catalog profile, whether that profile was just inserted above or
    // already existed from a previous app version.
    final mentorRows2 = await db.query('users', where: 'email = ?', whereArgs: [demoMentorEmail]);
    UserProfile mentorUser;
    if (mentorRows2.isEmpty) {
      mentorUser = await authRepo.register(
        name: 'Nguyen Minh Anh',
        email: demoMentorEmail,
        password: demoStudentPassword,
        role: UserRole.mentor,
      );
    } else {
      mentorUser = UserProfile.fromMap(mentorRows2.first);
    }
    final linkedMentor = await mentorRepo.getByUserId(mentorUser.id);
    if (linkedMentor == null) {
      final unlinked = await db.query('mentors', where: 'name = ? AND userId = ?', whereArgs: ['Nguyen Minh Anh', '']);
      if (unlinked.isNotEmpty) {
        await db.update('mentors', {'userId': mentorUser.id}, where: 'id = ?', whereArgs: [unlinked.first['id']]);
      }
    }

    final coursesRows = await db.query('courses', limit: 1);
    if (coursesRows.isEmpty) {
      final mentor = await mentorRepo.getByUserId(mentorUser.id);
      if (mentor != null) {
        await _seedCourses(mentor.id, mentor.name);
      }
    }
  }

  static Future<void> _seedCourses(String mentorId, String mentorName) async {
    final courseRepo = CourseRepository();

    final publishedCourse = Course(
      id: _uuid.v4(),
      mentorId: mentorId,
      mentorName: mentorName,
      title: 'Flutter Interview Bootcamp',
      description:
          'A practical crash course covering Flutter widgets, state management with Provider, '
          'and the questions interviewers actually ask.',
      thumbnailUrl: 'https://picsum.photos/seed/flutter-course/400/240',
      price: 199000,
      status: CourseStatus.published,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    );
    final publishedLessons = [
      Lesson(
        id: _uuid.v4(),
        courseId: publishedCourse.id,
        title: 'Widgets 101: Stateless vs Stateful',
        content:
            'Understand the widget tree, how Flutter rebuilds widgets, and when to reach for '
            'StatefulWidget vs StatelessWidget.',
        durationMinutes: 12,
        orderIndex: 0,
      ),
      Lesson(
        id: _uuid.v4(),
        courseId: publishedCourse.id,
        title: 'State Management with Provider',
        content:
            'Walk through ChangeNotifier, Consumer, and context.watch/read — the pattern used '
            'throughout this very app.',
        durationMinutes: 18,
        orderIndex: 1,
      ),
      Lesson(
        id: _uuid.v4(),
        courseId: publishedCourse.id,
        title: 'Common Interview Questions',
        content:
            'Review the top 10 Flutter interview questions with model answers, from widget '
            'lifecycle to performance optimization.',
        durationMinutes: 15,
        orderIndex: 2,
      ),
    ];

    final pendingCourse = Course(
      id: _uuid.v4(),
      mentorId: mentorId,
      mentorName: mentorName,
      title: 'Advanced Dart: Isolates & Streams',
      description: 'Deep dive into concurrency in Dart for candidates targeting senior roles.',
      thumbnailUrl: 'https://picsum.photos/seed/dart-course/400/240',
      price: 249000,
      status: CourseStatus.pendingReview,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    );
    final pendingLessons = [
      Lesson(
        id: _uuid.v4(),
        courseId: pendingCourse.id,
        title: 'Isolates Explained',
        content: 'How Dart achieves parallelism without shared memory.',
        durationMinutes: 14,
        orderIndex: 0,
      ),
    ];

    await courseRepo.insertSeedCourses(
      [publishedCourse, pendingCourse],
      {
        publishedCourse.id: publishedLessons,
        pendingCourse.id: pendingLessons,
      },
    );
  }

  static List<Mentor> _buildMentors(String firstMentorUserId) => [
        Mentor(
          id: _uuid.v4(),
          userId: firstMentorUserId,
          name: 'Nguyen Minh Anh',
          title: 'Senior Flutter Engineer @ Grab',
          bio: 'Ex-Grab mobile lead with 8 years of experience building large-scale Flutter apps. '
              'Focuses on state management, app architecture, and technical interview prep.',
          expertise: const ['Flutter', 'Dart', 'Mobile Architecture'],
          hourlyRate: 350000,
          rating: 4.8,
          reviewCount: 32,
          avatarUrl: 'https://i.pravatar.cc/150?img=12',
          latitude: 10.7769,
          longitude: 106.7009,
          sessionAddress: 'District 1, Ho Chi Minh City',
          status: MentorStatus.approved,
        ),
        Mentor(
          id: _uuid.v4(),
          name: 'Tran Le Bao Chau',
          title: 'Backend Engineer @ Tiki',
          bio: 'Specializes in REST API design, database modeling, and system design interviews '
              'for backend and full-stack roles.',
          expertise: const ['System Design', 'Node.js', 'Databases'],
          hourlyRate: 300000,
          rating: 4.6,
          reviewCount: 21,
          avatarUrl: 'https://i.pravatar.cc/150?img=32',
          latitude: 10.8231,
          longitude: 106.6297,
          sessionAddress: 'Tan Binh District, Ho Chi Minh City',
          status: MentorStatus.approved,
        ),
        Mentor(
          id: _uuid.v4(),
          name: 'Le Quoc Huy',
          title: 'Product Manager @ Momo',
          bio: 'Helps candidates prepare for product management case interviews and portfolio reviews.',
          expertise: const ['Product Management', 'Case Interview'],
          hourlyRate: 400000,
          rating: 4.9,
          reviewCount: 40,
          avatarUrl: 'https://i.pravatar.cc/150?img=51',
          latitude: 10.7757,
          longitude: 106.6982,
          sessionAddress: 'Binh Thanh District, Ho Chi Minh City',
          status: MentorStatus.approved,
        ),
        Mentor(
          id: _uuid.v4(),
          name: 'Pham Thi Hong Ngoc',
          title: 'Data Scientist @ Shopee',
          bio: 'Covers machine learning fundamentals, SQL interviews, and take-home project reviews.',
          expertise: const ['Data Science', 'SQL', 'Machine Learning'],
          hourlyRate: 320000,
          rating: 4.7,
          reviewCount: 18,
          avatarUrl: 'https://i.pravatar.cc/150?img=45',
          latitude: 10.8411,
          longitude: 106.8099,
          sessionAddress: 'Thu Duc City, Ho Chi Minh City',
          status: MentorStatus.approved,
        ),
        Mentor(
          id: _uuid.v4(),
          name: 'Vo Thanh Dat',
          title: 'iOS Engineer @ VNG',
          bio: 'Native iOS engineer who also mentors cross-platform Flutter developers preparing '
              'for mobile technical interviews.',
          expertise: const ['iOS', 'Flutter', 'Mobile Interview'],
          hourlyRate: 280000,
          rating: 4.5,
          reviewCount: 14,
          avatarUrl: 'https://i.pravatar.cc/150?img=15',
          latitude: 10.7626,
          longitude: 106.6822,
          sessionAddress: 'District 4, Ho Chi Minh City',
          status: MentorStatus.approved,
        ),
        Mentor(
          id: _uuid.v4(),
          name: 'Hoang Gia Linh',
          title: 'HR Business Partner @ FPT Software',
          bio: 'Runs mock behavioral interviews, resume reviews, and salary negotiation coaching.',
          expertise: const ['Behavioral Interview', 'Resume Review', 'HR'],
          hourlyRate: 250000,
          rating: 4.9,
          reviewCount: 27,
          avatarUrl: 'https://i.pravatar.cc/150?img=48',
          latitude: 10.8106,
          longitude: 106.7091,
          sessionAddress: 'Phu Nhuan District, Ho Chi Minh City',
          status: MentorStatus.approved,
        ),
        // Awaiting admin approval — demonstrates the admin "approve mentor" flow.
        Mentor(
          id: _uuid.v4(),
          name: 'Do Anh Khoa',
          title: 'DevOps Engineer @ VNPay',
          bio: 'Wants to mentor on CI/CD pipelines, Docker, and cloud infrastructure basics.',
          expertise: const ['DevOps', 'Docker', 'CI/CD'],
          hourlyRate: 270000,
          rating: 0,
          reviewCount: 0,
          avatarUrl: 'https://i.pravatar.cc/150?img=22',
          latitude: 10.7797,
          longitude: 106.6990,
          sessionAddress: 'District 3, Ho Chi Minh City',
          status: MentorStatus.pending,
        ),
      ];
}
