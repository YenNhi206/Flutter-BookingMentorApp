import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../models/user_profile.dart';
import '../db/app_database.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

class AuthRepository {
  final _uuid = const Uuid();

  String _hash(String password) => sha256.convert(utf8.encode(password)).toString();

  Future<UserProfile> register({
    required String name,
    required String email,
    required String password,
    UserRole role = UserRole.student,
  }) async {
    final db = await AppDatabase.instance.database;
    final existing = await db.query('users', where: 'email = ?', whereArgs: [email]);
    if (existing.isNotEmpty) {
      throw AuthException('An account with this email already exists.');
    }
    final user = UserProfile(
      id: _uuid.v4(),
      name: name,
      email: email,
      passwordHash: _hash(password),
      role: role,
    );
    await db.insert('users', user.toMap());
    return user;
  }

  Future<UserProfile> login({required String email, required String password}) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('users', where: 'email = ?', whereArgs: [email]);
    if (rows.isEmpty) {
      throw AuthException('No account found for this email.');
    }
    final user = UserProfile.fromMap(rows.first);
    if (user.passwordHash != _hash(password)) {
      throw AuthException('Incorrect password.');
    }
    if (!user.isActive) {
      throw AuthException('This account has been disabled by an administrator.');
    }
    return user;
  }

  Future<List<UserProfile>> getAll() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('users', orderBy: 'name ASC');
    return rows.map(UserProfile.fromMap).toList();
  }

  Future<void> updateActive(String userId, bool isActive) async {
    final db = await AppDatabase.instance.database;
    await db.update('users', {'isActive': isActive ? 1 : 0}, where: 'id = ?', whereArgs: [userId]);
  }

  Future<UserProfile> updateProfile(UserProfile updated) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'users',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [updated.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return updated;
  }

  Future<UserProfile?> findById(String id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return UserProfile.fromMap(rows.first);
  }
}
