enum MentorStatus { pending, approved, rejected }

MentorStatus mentorStatusFromString(String value) {
  return MentorStatus.values.firstWhere(
    (s) => s.name == value,
    orElse: () => MentorStatus.approved,
  );
}

class Mentor {
  final String id;
  final String userId;
  final String name;
  final String title;
  final String bio;
  final List<String> expertise;
  final double hourlyRate;
  final double rating;
  final int reviewCount;
  final String avatarUrl;
  final double latitude;
  final double longitude;
  final String sessionAddress;
  final MentorStatus status;
  final bool isActive;

  const Mentor({
    required this.id,
    this.userId = '',
    required this.name,
    required this.title,
    required this.bio,
    required this.expertise,
    required this.hourlyRate,
    required this.rating,
    required this.reviewCount,
    required this.avatarUrl,
    required this.latitude,
    required this.longitude,
    required this.sessionAddress,
    this.status = MentorStatus.approved,
    this.isActive = true,
  });

  Mentor copyWith({
    double? rating,
    int? reviewCount,
    MentorStatus? status,
    bool? isActive,
  }) {
    return Mentor(
      id: id,
      userId: userId,
      name: name,
      title: title,
      bio: bio,
      expertise: expertise,
      hourlyRate: hourlyRate,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      avatarUrl: avatarUrl,
      latitude: latitude,
      longitude: longitude,
      sessionAddress: sessionAddress,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'userId': userId,
        'name': name,
        'title': title,
        'bio': bio,
        'expertise': expertise.join('|'),
        'hourlyRate': hourlyRate,
        'rating': rating,
        'reviewCount': reviewCount,
        'avatarUrl': avatarUrl,
        'latitude': latitude,
        'longitude': longitude,
        'sessionAddress': sessionAddress,
        'status': status.name,
        'isActive': isActive ? 1 : 0,
      };

  factory Mentor.fromMap(Map<String, Object?> map) => Mentor(
        id: map['id'] as String,
        userId: (map['userId'] as String?) ?? '',
        name: map['name'] as String,
        title: map['title'] as String,
        bio: map['bio'] as String,
        expertise: (map['expertise'] as String).split('|').where((e) => e.isNotEmpty).toList(),
        hourlyRate: (map['hourlyRate'] as num).toDouble(),
        rating: (map['rating'] as num).toDouble(),
        reviewCount: map['reviewCount'] as int,
        avatarUrl: map['avatarUrl'] as String,
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
        sessionAddress: map['sessionAddress'] as String,
        status: mentorStatusFromString((map['status'] as String?) ?? 'approved'),
        isActive: ((map['isActive'] as int?) ?? 1) == 1,
      );
}
