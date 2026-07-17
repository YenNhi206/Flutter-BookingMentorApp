import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../models/user.dart';
import 'database_service.dart';

/// Lỗi nghiệp vụ xác thực (sai mật khẩu, email đã tồn tại...) - tách riêng
/// khỏi lỗi hệ thống để tầng UI hiển thị thông báo phù hợp cho người dùng.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

/// Xử lý nghiệp vụ đăng ký/đăng nhập: băm mật khẩu, kiểm tra trùng email,
/// đối chiếu thông tin đăng nhập. Thao tác trực tiếp với bảng `users` qua
/// [DatabaseService] vì logic này gắn chặt với bảo mật, không cần tách thêm
/// một tầng repository trung gian.
class AuthService {
  final DatabaseService _db;
  final _uuid = const Uuid();

  AuthService({DatabaseService? databaseService}) : _db = databaseService ?? DatabaseService.instance;

  /// Băm mật khẩu bằng SHA-256. Đủ an toàn cho phạm vi đồ án (không cần
  /// bcrypt/salt phức tạp vì đây là app local-only, không có API công khai).
  String _hash(String plain) => sha256.convert(utf8.encode(plain)).toString();

  Future<AppUser> register({
    required String fullName,
    required String email,
    required String password,
    String? storeName,
    String? storeAddress,
  }) async {
    final db = await _db.database;
    final normalizedEmail = email.trim().toLowerCase();

    final existing = await db.query('users', where: 'email = ?', whereArgs: [normalizedEmail]);
    if (existing.isNotEmpty) {
      throw const AuthException('Email này đã được đăng ký.');
    }

    final isOwner = storeName != null && storeName.trim().isNotEmpty;
    String? storeId;
    if (isOwner) {
      storeId = _uuid.v4();
      await db.insert('stores', {
        'id': storeId,
        'name': storeName.trim(),
        'address': storeAddress?.trim() ?? '',
        'lat': 0.0,
        'lng': 0.0,
        'rating': 5.0,
        'image': '',
      });
    }

    final user = AppUser(
      id: _uuid.v4(),
      fullName: fullName.trim(),
      email: normalizedEmail,
      passwordHash: _hash(password),
      role: isOwner ? UserRole.owner : UserRole.customer,
      storeId: storeId,
    );
    await db.insert('users', user.toMap());
    return user;
  }

  Future<AppUser> login({required String email, required String password}) async {
    final db = await _db.database;
    final normalizedEmail = email.trim().toLowerCase();

    final rows = await db.query('users', where: 'email = ?', whereArgs: [normalizedEmail]);
    if (rows.isEmpty) {
      throw const AuthException('Không tìm thấy tài khoản với email này.');
    }
    final user = AppUser.fromMap(rows.first);
    if (user.passwordHash != _hash(password)) {
      throw const AuthException('Mật khẩu không chính xác.');
    }
    return user;
  }

  Future<AppUser?> getById(String userId) async {
    final db = await _db.database;
    final rows = await db.query('users', where: 'id = ?', whereArgs: [userId]);
    if (rows.isEmpty) return null;
    return AppUser.fromMap(rows.first);
  }

  Future<AppUser> updateProfile(AppUser updated) async {
    final db = await _db.database;
    await db.update(
      'users',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [updated.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return updated;
  }
}
