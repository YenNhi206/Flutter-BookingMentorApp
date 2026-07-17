/// Vai trò người dùng - [customer] đặt món như bình thường, [owner] quản lý
/// menu của 1 cửa hàng (xem [AppUser.storeId]).
enum UserRole { customer, owner }

extension UserRoleX on UserRole {
  String get dbValue => name;

  static UserRole fromDb(String? value) => value == 'owner' ? UserRole.owner : UserRole.customer;
}

/// Model người dùng - tương ứng bảng `users` trong SQLite.
class AppUser {
  final String id;
  final String fullName;
  final String email;

  /// Mật khẩu chỉ lưu dạng băm SHA-256 (xem [core/... AuthService]),
  /// không bao giờ lưu plaintext.
  final String passwordHash;
  final String phone;
  final String address;
  final String avatar;
  final UserRole role;

  /// Cửa hàng mà user này sở hữu/quản lý - chỉ có giá trị khi [role] là
  /// [UserRole.owner].
  final String? storeId;

  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.passwordHash,
    this.phone = '',
    this.address = '',
    this.avatar = '',
    this.role = UserRole.customer,
    this.storeId,
  });

  bool get isOwner => role == UserRole.owner;

  AppUser copyWith({
    String? fullName,
    String? phone,
    String? address,
    String? avatar,
  }) {
    return AppUser(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email,
      passwordHash: passwordHash,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      avatar: avatar ?? this.avatar,
      role: role,
      storeId: storeId,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'full_name': fullName,
        'email': email,
        'password_hash': passwordHash,
        'phone': phone,
        'address': address,
        'avatar': avatar,
        'role': role.dbValue,
        'store_id': storeId,
      };

  factory AppUser.fromMap(Map<String, Object?> map) => AppUser(
        id: map['id'] as String,
        fullName: map['full_name'] as String? ?? '',
        email: map['email'] as String,
        passwordHash: map['password_hash'] as String,
        phone: map['phone'] as String? ?? '',
        address: map['address'] as String? ?? '',
        avatar: map['avatar'] as String? ?? '',
        role: UserRoleX.fromDb(map['role'] as String?),
        storeId: map['store_id'] as String?,
      );
}
