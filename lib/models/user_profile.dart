enum UserRole { student, mentor, admin }

UserRole userRoleFromString(String value) {
  return UserRole.values.firstWhere(
    (r) => r.name == value,
    orElse: () => UserRole.student,
  );
}

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String passwordHash;
  final UserRole role;
  final String phone;
  final String avatarUrl;
  final bool isActive;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.role,
    this.phone = '',
    this.avatarUrl = '',
    this.isActive = true,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'passwordHash': passwordHash,
        'role': role.name,
        'phone': phone,
        'avatarUrl': avatarUrl,
        'isActive': isActive ? 1 : 0,
      };

  factory UserProfile.fromMap(Map<String, Object?> map) => UserProfile(
        id: map['id'] as String,
        name: map['name'] as String,
        email: map['email'] as String,
        passwordHash: map['passwordHash'] as String,
        role: userRoleFromString(map['role'] as String),
        phone: (map['phone'] as String?) ?? '',
        avatarUrl: (map['avatarUrl'] as String?) ?? '',
        isActive: ((map['isActive'] as int?) ?? 1) == 1,
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
      passwordHash: passwordHash,
      role: role,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isActive: isActive ?? this.isActive,
    );
  }
}
