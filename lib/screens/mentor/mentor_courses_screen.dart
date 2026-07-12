import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/course.dart';
import '../../providers/mentor_dashboard_provider.dart';
import 'course_editor_screen.dart';

class MentorCoursesScreen extends StatelessWidget {
  const MentorCoursesScreen({super.key});

  Color _statusColor(CourseStatus status) {
    switch (status) {
      case CourseStatus.draft:
        return Colors.grey;
      case CourseStatus.pendingReview:
        return Colors.orange;
      case CourseStatus.published:
        return Colors.green;
      case CourseStatus.rejected:
        return Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<MentorDashboardProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('My courses'), automaticallyImplyLeading: false),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CourseEditorScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New course'),
      ),
      body: dashboard.isLoading
          ? const Center(child: CircularProgressIndicator())
          : dashboard.courses.isEmpty
              ? const Center(child: Text('No courses yet — create your first one!', style: TextStyle(color: Colors.black54)))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: dashboard.courses.length,
                  itemBuilder: (context, index) {
                    final course = dashboard.courses[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(course.thumbnailUrl, width: 56, height: 56, fit: BoxFit.cover),
                        ),
                        title: Text(course.title),
                        subtitle: Text('${(course.price / 1000).toStringAsFixed(0)}k VND'),
                        trailing: Chip(
                          label: Text(course.status.name, style: const TextStyle(color: Colors.white, fontSize: 11)),
                          backgroundColor: _statusColor(course.status),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
