enum MentorStatus { pending, approved, rejected }

MentorStatus mentorStatusFromString(String value) {
  return MentorStatus.values.firstWhere(
    (s) => s.name == value,
    orElse: () => MentorStatus.approved,
  );
}

List<String> _stringList(dynamic value) =>
    (value as List?)?.map((e) => e.toString()).toList() ?? const [];

/// Backend splits what this app treats as a single flat `expertise` list
/// into three separate concepts (specialties/fields/tags). Prefer
/// `specialties` (closest semantic match: skills/topics), falling back to
/// `fields`, then `tags`, so `expertise` is always populated from whichever
/// the mentor doc actually has.
List<String> _expertiseFrom(Map<String, dynamic> json) {
  final specialties = _stringList(json['specialties']);
  if (specialties.isNotEmpty) return specialties;
  final fields = _stringList(json['fields']);
  if (fields.isNotEmpty) return fields;
  return _stringList(json['tags']);
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

  /// Public catalog / detail shape (`GET /mentors`, `GET /mentors/:id`) -
  /// this is a flattened, already-approved-only view, so `status` is always
  /// `approved` here (nothing else could show up in this response).
  ///
  /// The backend has no mentor location fields (no lat/long/address), so
  /// this always defaults to `(0,0)`/empty - the map-based mentor discovery
  /// screen will need revisiting once/if the backend adds location data.
  factory Mentor.fromJson(Map<String, dynamic> json) => Mentor(
        id: json['id'].toString(),
        name: json['name'] as String? ?? '',
        title: json['title'] as String? ?? '',
        bio: json['bio'] as String? ?? '',
        expertise: _expertiseFrom(json),
        hourlyRate: (json['price'] as num?)?.toDouble() ?? 0,
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        reviewCount: (json['reviews'] as num?)?.toInt() ?? 0,
        avatarUrl: json['avatar'] as String? ?? '',
        latitude: 0,
        longitude: 0,
        sessionAddress: '',
        status: MentorStatus.approved,
        isActive: json['available'] as bool? ?? true,
      );

  /// Richer shape shared by `GET /mentors/me` and admin's `GET
  /// /admin/mentors` (raw mentor doc: `stats.rating`/`stats.reviewCount`,
  /// `adminReview.status`, `isActive`, and either `id` (publicId, from
  /// `/mentors/me`) or `_id` (Mongo id, from the admin list - admin
  /// approve/reject actions target this id).
  factory Mentor.fromDetailJson(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>? ?? const {};
    final adminReview = json['adminReview'] as Map<String, dynamic>? ?? const {};
    final rawUserId = json['userId'];
    final userId = rawUserId is Map
        ? (rawUserId['_id'] ?? rawUserId['id'] ?? '').toString()
        : (rawUserId ?? '').toString();
    return Mentor(
      id: (json['id'] ?? json['_id']).toString(),
      userId: userId,
      name: json['name'] as String? ?? '',
      title: json['title'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      expertise: _expertiseFrom(json),
      hourlyRate: (json['pricePerHour'] as num?)?.toDouble() ?? 0,
      rating: (stats['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (stats['reviewCount'] as num?)?.toInt() ?? 0,
      avatarUrl: json['avatar'] as String? ?? '',
      latitude: 0,
      longitude: 0,
      sessionAddress: '',
      status: mentorStatusFromString(adminReview['status'] as String? ?? 'pending'),
      isActive: json['isActive'] as bool? ?? false,
    );
  }
}
