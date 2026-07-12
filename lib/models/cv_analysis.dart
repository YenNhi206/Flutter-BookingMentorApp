class CvAnalysis {
  final String id;
  final String studentId;
  final String cvText;
  final String jdText;
  final double matchScore;
  final List<String> matchedSkills;
  final List<String> missingSkills;
  final DateTime createdAt;

  const CvAnalysis({
    required this.id,
    required this.studentId,
    required this.cvText,
    required this.jdText,
    required this.matchScore,
    required this.matchedSkills,
    required this.missingSkills,
    required this.createdAt,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'studentId': studentId,
        'cvText': cvText,
        'jdText': jdText,
        'matchScore': matchScore,
        'matchedSkills': matchedSkills.join('|'),
        'missingSkills': missingSkills.join('|'),
        'createdAt': createdAt.toIso8601String(),
      };

  factory CvAnalysis.fromMap(Map<String, Object?> map) => CvAnalysis(
        id: map['id'] as String,
        studentId: map['studentId'] as String,
        cvText: map['cvText'] as String,
        jdText: map['jdText'] as String,
        matchScore: (map['matchScore'] as num).toDouble(),
        matchedSkills: (map['matchedSkills'] as String).split('|').where((e) => e.isNotEmpty).toList(),
        missingSkills: (map['missingSkills'] as String).split('|').where((e) => e.isNotEmpty).toList(),
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
