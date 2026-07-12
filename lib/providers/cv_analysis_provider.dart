import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/repositories/cv_analysis_repository.dart';
import '../models/cv_analysis.dart';
import '../services/cv_match_service.dart';

class CvAnalysisProvider extends ChangeNotifier {
  final CvAnalysisRepository _repository;
  final _uuid = const Uuid();

  CvAnalysisProvider({CvAnalysisRepository? repository})
      : _repository = repository ?? CvAnalysisRepository();

  List<CvAnalysis> _history = [];
  bool _isLoading = false;

  List<CvAnalysis> get history => _history;
  bool get isLoading => _isLoading;

  Future<void> loadHistory(String studentId) async {
    _isLoading = true;
    notifyListeners();
    _history = await _repository.getForStudent(studentId);
    _isLoading = false;
    notifyListeners();
  }

  Future<CvAnalysis> analyze({
    required String studentId,
    required String cvText,
    required String jdText,
  }) async {
    final result = CvMatchService.analyze(cvText: cvText, jdText: jdText);
    final analysis = CvAnalysis(
      id: _uuid.v4(),
      studentId: studentId,
      cvText: cvText,
      jdText: jdText,
      matchScore: result.matchScore,
      matchedSkills: result.matchedSkills,
      missingSkills: result.missingSkills,
      createdAt: DateTime.now(),
    );
    await _repository.create(analysis);
    await loadHistory(studentId);
    return analysis;
  }

  Future<void> delete(String id, String studentId) async {
    await _repository.delete(id);
    await loadHistory(studentId);
  }
}
