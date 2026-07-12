enum CourseStatus { draft, pendingReview, published, rejected }

CourseStatus courseStatusFromString(String value) {
  return CourseStatus.values.firstWhere(
    (s) => s.name == value,
    orElse: () => CourseStatus.draft,
  );
}

class Course {
  final String id;
  final String mentorId;
  final String mentorName;
  final String title;
  final String description;
  final String thumbnailUrl;
  final double price;
  final CourseStatus status;
  final DateTime createdAt;

  const Course({
    required this.id,
    required this.mentorId,
    required this.mentorName,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.price,
    this.status = CourseStatus.draft,
    required this.createdAt,
  });

  Course copyWith({CourseStatus? status}) => Course(
        id: id,
        mentorId: mentorId,
        mentorName: mentorName,
        title: title,
        description: description,
        thumbnailUrl: thumbnailUrl,
        price: price,
        status: status ?? this.status,
        createdAt: createdAt,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'mentorId': mentorId,
        'mentorName': mentorName,
        'title': title,
        'description': description,
        'thumbnailUrl': thumbnailUrl,
        'price': price,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Course.fromMap(Map<String, Object?> map) => Course(
        id: map['id'] as String,
        mentorId: map['mentorId'] as String,
        mentorName: map['mentorName'] as String,
        title: map['title'] as String,
        description: map['description'] as String,
        thumbnailUrl: map['thumbnailUrl'] as String,
        price: (map['price'] as num).toDouble(),
        status: courseStatusFromString(map['status'] as String),
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
