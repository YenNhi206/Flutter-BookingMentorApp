import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/course_provider.dart';
import '../../providers/mentor_dashboard_provider.dart';

class _LessonDraft {
  final titleController = TextEditingController();
  final contentController = TextEditingController();
  final durationController = TextEditingController(text: '10');
}

class CourseEditorScreen extends StatefulWidget {
  const CourseEditorScreen({super.key});

  @override
  State<CourseEditorScreen> createState() => _CourseEditorScreenState();
}

class _CourseEditorScreenState extends State<CourseEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController(text: '199000');
  final List<_LessonDraft> _lessons = [_LessonDraft()];
  bool _isSaving = false;

  void _addLesson() => setState(() => _lessons.add(_LessonDraft()));

  void _removeLesson(int index) => setState(() => _lessons.removeAt(index));

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lessons.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Add at least one lesson')));
      return;
    }

    setState(() => _isSaving = true);
    final dashboard = context.read<MentorDashboardProvider>();
    final mentor = dashboard.mentorProfile!;
    try {
      await context.read<CourseProvider>().createCourse(
            mentorId: mentor.id,
            mentorName: mentor.name,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            price: double.parse(_priceController.text.trim()),
            thumbnailUrl: 'https://picsum.photos/seed/${mentor.id}${DateTime.now().millisecondsSinceEpoch}/400/240',
            lessons: [
              for (final l in _lessons)
                (
                  title: l.titleController.text.trim(),
                  content: l.contentController.text.trim(),
                  durationMinutes: int.tryParse(l.durationController.text.trim()) ?? 10,
                ),
            ],
          );
      await dashboard.loadForUser(mentor.userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course submitted for admin review')),
      );
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New course')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Course title'),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Price (VND)'),
              validator: (v) => (double.tryParse(v ?? '') == null) ? 'Enter a valid number' : null,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Lessons', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                TextButton.icon(
                  onPressed: _addLesson,
                  icon: const Icon(Icons.add),
                  label: const Text('Add lesson'),
                ),
              ],
            ),
            for (var i = 0; i < _lessons.length; i++)
              Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Lesson ${i + 1}', style: const TextStyle(fontWeight: FontWeight.w600)),
                          if (_lessons.length > 1)
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () => _removeLesson(i),
                            ),
                        ],
                      ),
                      TextFormField(
                        controller: _lessons[i].titleController,
                        decoration: const InputDecoration(labelText: 'Lesson title'),
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _lessons[i].contentController,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'Lesson content / notes'),
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _lessons[i].durationController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Duration (minutes)'),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSaving ? null : _submit,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Submit for review'),
            ),
          ],
        ),
      ),
    );
  }
}
