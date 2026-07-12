import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/course.dart';
import '../../models/enrollment.dart';
import '../../models/lesson.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import 'lesson_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;
  const CourseDetailScreen({super.key, required this.courseId});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  Course? _course;
  List<Lesson> _lessons = [];
  Enrollment? _enrollment;
  bool _loading = true;
  bool _enrolling = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final provider = context.read<CourseProvider>();
    final course = await provider.getById(widget.courseId);
    final lessons = await provider.getLessons(widget.courseId);
    final enrollment = await provider.getEnrollment(auth.currentUser!.id, widget.courseId);
    if (!mounted) return;
    setState(() {
      _course = course;
      _lessons = lessons;
      _enrollment = enrollment;
      _loading = false;
    });
  }

  Future<void> _enroll() async {
    setState(() => _enrolling = true);
    final auth = context.read<AuthProvider>();
    final enrollment = await context.read<CourseProvider>().enroll(auth.currentUser!.id, widget.courseId);
    if (!mounted) return;
    setState(() {
      _enrollment = enrollment;
      _enrolling = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enrolled! You can start learning now.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final course = _course;
    if (course == null) return const Scaffold(body: Center(child: Text('Course not found')));

    final isEnrolled = _enrollment != null;

    return Scaffold(
      appBar: AppBar(title: Text(course.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(course.thumbnailUrl, height: 160, width: double.infinity, fit: BoxFit.cover),
          ),
          const SizedBox(height: 16),
          Text(course.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('by ${course.mentorName}', style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 12),
          Text(course.description, style: const TextStyle(height: 1.4)),
          const SizedBox(height: 16),
          if (isEnrolled) ...[
            LinearProgressIndicator(value: _enrollment!.progressPercent / 100),
            const SizedBox(height: 4),
            Text('${_enrollment!.progressPercent.toStringAsFixed(0)}% complete'),
            const SizedBox(height: 16),
          ],
          const Text('Lessons', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ..._lessons.map((lesson) {
            final done = _enrollment?.completedLessonIds.contains(lesson.id) ?? false;
            return Card(
              child: ListTile(
                leading: Icon(
                  done ? Icons.check_circle : (isEnrolled ? Icons.play_circle_outline : Icons.lock_outline),
                  color: done ? Colors.green : (isEnrolled ? AppTheme.primary : Colors.black38),
                ),
                title: Text(lesson.title),
                subtitle: Text('${lesson.durationMinutes} min'),
                onTap: !isEnrolled
                    ? null
                    : () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => LessonScreen(
                              lesson: lesson,
                              totalLessons: _lessons.length,
                              enrollment: _enrollment!,
                            ),
                          ),
                        );
                        _load();
                      },
              ),
            );
          }),
          const SizedBox(height: 80),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: isEnrolled
              ? const SizedBox.shrink()
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentLime, foregroundColor: AppTheme.ink),
                  onPressed: _enrolling ? null : _enroll,
                  child: _enrolling
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text('Enroll — ${(course.price / 1000).toStringAsFixed(0)}k VND'),
                ),
        ),
      ),
    );
  }
}
