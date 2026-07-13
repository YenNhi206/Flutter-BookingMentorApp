enum UserRole { student, mentor, admin }

UserRole userRoleFromString(String value) {
  return UserRole.values.firstWhere(
    (r) => r.name == value,
    orElse: () => UserRole.student,
  );
}

/// Maps the backend's role strings (`customer`/`mentor`/`admin`) onto the
/// app's own [UserRole] enum - the backend never uses the word "student".
UserRole userRoleFromBackend(String? value) {
  if (value == 'customer') return UserRole.student;
  return userRoleFromString(value ?? '');
}

class UserProfile {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String phone;
  final String avatarUrl;
  final bool isActive;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone = '',
    this.avatarUrl = '',
    this.isActive = true,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: (json['id'] ?? json['_id']).toString(),
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        role: userRoleFromBackend(json['role'] as String?),
        phone: json['phone'] as String? ?? '',
        avatarUrl: json['avatar'] as String? ?? json['avatarUrl'] as String? ?? '',
        isActive: json['isActive'] as bool? ?? true,
      );

  UserProfile copyWith({
    String? name,
    String? phone,
    String? avatarUrl,
    bool? isActive,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email,
      role: role,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isActive: isActive ?? this.isActive,
    );
  }
}
