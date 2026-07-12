/// Local, offline CV/JD keyword matcher. This intentionally does not call
/// any AI/LLM service (unlike the reference platform's Python NLP pipeline)
/// so the feature works without network access or API keys — a reasonable
/// scope simplification for a course project.
class CvMatchResult {
  final double matchScore;
  final List<String> matchedSkills;
  final List<String> missingSkills;

  const CvMatchResult({
    required this.matchScore,
    required this.matchedSkills,
    required this.missingSkills,
  });
}

class CvMatchService {
  /// A small curated taxonomy of common tech/business skills to scan for.
  /// Only skills that actually appear in the JD text are considered
  /// "required" for that job, so unrelated skills never count against you.
  static const List<String> skillTaxonomy = [
    'flutter', 'dart', 'react', 'javascript', 'typescript', 'node.js', 'nodejs',
    'python', 'java', 'kotlin', 'swift', 'sql', 'nosql', 'mongodb', 'postgresql',
    'mysql', 'firebase', 'aws', 'azure', 'docker', 'kubernetes', 'git', 'rest api',
    'graphql', 'ci/cd', 'agile', 'scrum', 'figma', 'ui/ux', 'machine learning',
    'data analysis', 'data science', 'product management', 'project management',
    'communication', 'leadership', 'problem solving', 'testing', 'unit testing',
  ];

  static CvMatchResult analyze({required String cvText, required String jdText}) {
    final cvLower = cvText.toLowerCase();
    final jdLower = jdText.toLowerCase();

    final requiredSkills = skillTaxonomy.where((skill) => jdLower.contains(skill)).toSet();

    if (requiredSkills.isEmpty) {
      return const CvMatchResult(matchScore: 0, matchedSkills: [], missingSkills: []);
    }

    final matched = requiredSkills.where((skill) => cvLower.contains(skill)).toList()..sort();
    final missing = requiredSkills.difference(matched.toSet()).toList()..sort();

    final score = (matched.length / requiredSkills.length) * 100;

    return CvMatchResult(
      matchScore: double.parse(score.toStringAsFixed(1)),
      matchedSkills: matched,
      missingSkills: missing,
    );
  }
}
