import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/cv_analysis_provider.dart';
import 'cv_analysis_result_screen.dart';

class CvAnalysisHistoryScreen extends StatefulWidget {
  const CvAnalysisHistoryScreen({super.key});

  @override
  State<CvAnalysisHistoryScreen> createState() => _CvAnalysisHistoryScreenState();
}

class _CvAnalysisHistoryScreenState extends State<CvAnalysisHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      context.read<CvAnalysisProvider>().loadHistory(auth.currentUser!.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CvAnalysisProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Analysis history')),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.history.isEmpty
              ? const Center(child: Text('No analyses yet', style: TextStyle(color: Colors.black54)))
              : ListView.separated(
                  itemCount: provider.history.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final analysis = provider.history[index];
                    return ListTile(
                      title: Text('${analysis.matchScore.toStringAsFixed(0)}% match'),
                      subtitle: Text(
                        '${analysis.createdAt.day}/${analysis.createdAt.month}/${analysis.createdAt.year} · '
                        '${analysis.matchedSkills.length} matched, ${analysis.missingSkills.length} missing',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => provider.delete(analysis.id, auth.currentUser!.id),
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => CvAnalysisResultScreen(analysis: analysis)),
                      ),
                    );
                  },
                ),
    );
  }
}
