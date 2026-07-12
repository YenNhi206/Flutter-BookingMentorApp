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

  Map<String, Object?> toMap() => {
        'id': id,
        'courseId': courseId,
        'title': title,
        'content': content,
        'durationMinutes': durationMinutes,
        'orderIndex': orderIndex,
      };

  factory Lesson.fromMap(Map<String, Object?> map) => Lesson(
        id: map['id'] as String,
        courseId: map['courseId'] as String,
        title: map['title'] as String,
        content: map['content'] as String,
        durationMinutes: map['durationMinutes'] as int,
        orderIndex: map['orderIndex'] as int,
      );
}
