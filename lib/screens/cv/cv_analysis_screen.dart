import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/cv_analysis_provider.dart';
import 'cv_analysis_history_screen.dart';
import 'cv_analysis_result_screen.dart';

class CvAnalysisScreen extends StatefulWidget {
  const CvAnalysisScreen({super.key});

  @override
  State<CvAnalysisScreen> createState() => _CvAnalysisScreenState();
}

class _CvAnalysisScreenState extends State<CvAnalysisScreen> {
  final _cvController = TextEditingController();
  final _jdController = TextEditingController();
  bool _isAnalyzing = false;

  @override
  void dispose() {
    _cvController.dispose();
    _jdController.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    if (_cvController.text.trim().isEmpty || _jdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Paste both your CV and the job description')));
      return;
    }
    setState(() => _isAnalyzing = true);
    final auth = context.read<AuthProvider>();
    final analysis = await context.read<CvAnalysisProvider>().analyze(
          studentId: auth.currentUser!.id,
          cvText: _cvController.text.trim(),
          jdText: _jdController.text.trim(),
        );
    if (!mounted) return;
    setState(() => _isAnalyzing = false);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CvAnalysisResultScreen(analysis: analysis)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CV / JD Analysis'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'History',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CvAnalysisHistoryScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Paste your CV text and a job description below. We match your CV against a curated '
            'skill taxonomy to estimate fit and flag gaps — all processed on-device.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 20),
          const Text('Your CV', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _cvController,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText: 'e.g. Experienced Flutter developer skilled in Dart, Firebase, REST API...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Job description', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _jdController,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText: 'Paste the job posting here...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isAnalyzing ? null : _analyze,
            child: _isAnalyzing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Analyze match'),
          ),
        ],
      ),
    );
  }
}
