import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/course.dart';
import '../../models/enrollment.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import 'certificate_screen.dart';
import 'course_detail_screen.dart';

class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> {
  List<(Enrollment, Course)> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final provider = context.read<CourseProvider>();
    await provider.loadMyEnrollments(auth.currentUser!.id);
    final items = <(Enrollment, Course)>[];
    for (final enrollment in provider.myEnrollments) {
      final course = await provider.getById(enrollment.courseId);
      if (course != null) items.add((enrollment, course));
    }
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('My courses'), automaticallyImplyLeading: false),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('You have not enrolled in any course yet', style: TextStyle(color: Colors.black54)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final (enrollment, course) = _items[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text(course.title),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              LinearProgressIndicator(value: enrollment.progressPercent / 100),
                              const SizedBox(height: 4),
                              Text('${enrollment.progressPercent.toStringAsFixed(0)}% complete'),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: enrollment.certificateIssued
                              ? IconButton(
                                  icon: const Icon(Icons.workspace_premium, color: Colors.amber),
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => CertificateScreen(
                                        course: course,
                                        studentName: auth.currentUser!.name,
                                        completedAt: DateTime.now(),
                                      ),
                                    ),
                                  ),
                                )
                              : null,
                          onTap: () => Navigator.of(context)
                              .push(MaterialPageRoute(builder: (_) => CourseDetailScreen(courseId: course.id)))
                              .then((_) => _load()),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
