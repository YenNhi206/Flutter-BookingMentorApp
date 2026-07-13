/// The backend nests lessons two levels deep (`course.modules[].lessons[]`);
/// this app's UI has no concept of modules/chapters, so lessons are
/// flattened into a single ordered list per course - module grouping isn't
/// preserved in the UI, only lesson order.
class Lesson {
  final String id;
  final String courseId;
  final String title;
  final String content;
  final int durationMinutes;
  final int orderIndex;

  const Lesson({
    required this.id,
    required this.courseId,
    required this.title,
    required this.content,
    required this.durationMinutes,
    required this.orderIndex,
  });

  factory Lesson.fromJson(
    Map<String, dynamic> json, {
    required String courseId,
    required int orderIndex,
  }) =>
      Lesson(
        id: (json['id'] ?? json['_id'] ?? '').toString(),
        courseId: courseId,
        title: json['title'] as String? ?? '',
        content: json['description'] as String? ?? '',
        durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
        orderIndex: orderIndex,
      );
}

/// Flattens `course.modules[].lessons[]` (sorted by module then lesson order)
/// into a single ordered [Lesson] list.
List<Lesson> lessonsFromModulesJson(dynamic modulesJson, String courseId) {
  final modules = (modulesJson as List?) ?? const [];
  final lessons = <Lesson>[];
  for (final module in modules) {
    final moduleLessons = (module as Map<String, dynamic>)['lessons'] as List? ?? const [];
    for (final lesson in moduleLessons) {
      lessons.add(Lesson.fromJson(
        lesson as Map<String, dynamic>,
        courseId: courseId,
        orderIndex: lessons.length,
      ));
    }
  }
  return lessons;
}
