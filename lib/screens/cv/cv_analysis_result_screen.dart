import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/cv_analysis.dart';

class CvAnalysisResultScreen extends StatelessWidget {
  final CvAnalysis analysis;
  const CvAnalysisResultScreen({super.key, required this.analysis});

  Color get _scoreColor {
    if (analysis.matchScore >= 70) return Colors.green;
    if (analysis.matchScore >= 40) return Colors.orange;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Match result')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _scoreColor, width: 8),
              ),
              child: Center(
                child: Text(
                  '${analysis.matchScore.toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _scoreColor),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text('Match score against the job description', style: TextStyle(color: Colors.black54)),
          ),
          const SizedBox(height: 28),
          const Text('Matched skills', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          if (analysis.matchedSkills.isEmpty)
            const Text('None found', style: TextStyle(color: Colors.black54))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: analysis.matchedSkills
                  .map((s) => Chip(
                        avatar: const Icon(Icons.check, size: 16, color: Colors.white),
                        label: Text(s),
                        backgroundColor: Colors.green,
                        labelStyle: const TextStyle(color: Colors.white),
                      ))
                  .toList(),
            ),
          const SizedBox(height: 24),
          const Text('Missing skills to highlight', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          if (analysis.missingSkills.isEmpty)
            const Text('Great — no gaps detected!', style: TextStyle(color: Colors.black54))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: analysis.missingSkills
                  .map((s) => Chip(
                        avatar: const Icon(Icons.priority_high, size: 16, color: AppTheme.primary),
                        label: Text(s),
                        backgroundColor: AppTheme.primarySoft,
                      ))
                  .toList(),
            ),
          const SizedBox(height: 24),
          if (analysis.missingSkills.isNotEmpty)
            Card(
              color: AppTheme.accentLimeSoft,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Suggestion: add concrete examples of ${analysis.missingSkills.take(3).join(', ')} '
                  'to your CV, or book a mentor session to fill these gaps before applying.',
                  style: const TextStyle(height: 1.4),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
