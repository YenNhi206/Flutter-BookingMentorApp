import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/course_provider.dart';
import 'course_detail_screen.dart';
import 'my_courses_screen.dart';

class CourseListScreen extends StatefulWidget {
  const CourseListScreen({super.key});

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().loadPublished();
    });
  }

  @override
  Widget build(BuildContext context) {
    final courses = context.watch<CourseProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Courses'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.school_outlined),
            tooltip: 'My learning',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MyCoursesScreen()),
            ),
          ),
        ],
      ),
      body: courses.isLoading
          ? const Center(child: CircularProgressIndicator())
          : courses.published.isEmpty
              ? const Center(child: Text('No courses published yet', style: TextStyle(color: Colors.black54)))
              : RefreshIndicator(
                  onRefresh: courses.loadPublished,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: courses.published.length,
                    itemBuilder: (context, index) {
                      final course = courses.published[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => CourseDetailScreen(courseId: course.id)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                child: Image.network(course.thumbnailUrl, height: 140, width: double.infinity, fit: BoxFit.cover),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(course.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Text('by ${course.mentorName}', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                                    const SizedBox(height: 8),
                                    Text('${(course.price / 1000).toStringAsFixed(0)}k VND',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
