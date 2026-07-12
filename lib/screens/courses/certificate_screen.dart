import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/course.dart';

class CertificateScreen extends StatelessWidget {
  final Course course;
  final String studentName;
  final DateTime completedAt;

  const CertificateScreen({
    super.key,
    required this.course,
    required this.studentName,
    required this.completedAt,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Certificate')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primary, width: 3),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.workspace_premium, size: 64, color: AppTheme.accentLime),
                const SizedBox(height: 16),
                const Text('CERTIFICATE OF COMPLETION',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 20),
                const Text('This certifies that', style: TextStyle(color: Colors.black54)),
                const SizedBox(height: 8),
                Text(studentName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                const SizedBox(height: 8),
                const Text('has successfully completed', style: TextStyle(color: Colors.black54)),
                const SizedBox(height: 8),
                Text(course.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 20),
                Text('${completedAt.day}/${completedAt.month}/${completedAt.year}',
                    style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
