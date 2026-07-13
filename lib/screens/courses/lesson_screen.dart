import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/enrollment.dart';
import '../../models/lesson.dart';
import '../../providers/course_provider.dart';

class LessonScreen extends StatefulWidget {
  final Lesson lesson;
  final int totalLessons;
  final Enrollment enrollment;

  const LessonScreen({
    super.key,
    required this.lesson,
    required this.totalLessons,
    required this.enrollment,
  });

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  late bool _done;

  @override
  void initState() {
    super.initState();
    _done = widget.enrollment.completedLessonIds.contains(widget.lesson.id);
  }

  Future<void> _toggle() async {
    final updated = await context.read<CourseProvider>().toggleLessonComplete(
          enrollment: widget.enrollment,
          lessonId: widget.lesson.id,
        );
    if (!mounted) return;
    setState(() => _done = updated.completedLessonIds.contains(widget.lesson.id));
    if (updated.certificateIssued) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course completed! Your certificate is ready.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.lesson.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Icon(Icons.play_circle_fill, color: AppTheme.primary, size: 48),
              const SizedBox(width: 12),
              Text('${widget.lesson.durationMinutes} min video lesson',
                  style: const TextStyle(color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 20),
          Text(widget.lesson.content, style: const TextStyle(height: 1.5, fontSize: 15)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: OutlinedButton.icon(
            icon: Icon(_done ? Icons.check_circle : Icons.check_circle_outline),
            label: Text(_done ? 'Marked complete' : 'Mark as complete'),
            onPressed: _toggle,
          ),
        ),
      ),
    );
  }
}
