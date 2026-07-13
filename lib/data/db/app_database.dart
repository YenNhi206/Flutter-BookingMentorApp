import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Singleton wrapper around the local SQLite database. Auth, Mentors,
/// Bookings, Courses+Enrollments, Reviews, Notifications and Admin now talk
/// to the ProInterview backend directly - only Chat and CV Analysis (which
/// have no backend equivalent) still persist here.
class AppDatabase {
  AppDatabase._internal();
  static final AppDatabase instance = AppDatabase._internal();

  static const int _version = 3;

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      return openDatabase(
        'mentor_link.db',
        version: _version,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    }
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'mentor_link.db');
    return openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createLocalOnlyTables(db);
  }

  Future<void> _createLocalOnlyTables(Database db) async {
    await db.execute('''
      CREATE TABLE chat_messages (
        id TEXT PRIMARY KEY,
        conversationId TEXT NOT NULL,
        senderId TEXT NOT NULL,
        senderName TEXT NOT NULL,
        text TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        isRead INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE cv_analyses (
        id TEXT PRIMARY KEY,
        studentId TEXT NOT NULL,
        cvText TEXT NOT NULL,
        jdText TEXT NOT NULL,
        matchScore REAL NOT NULL,
        matchedSkills TEXT NOT NULL,
        missingSkills TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        "ALTER TABLE users ADD COLUMN isActive INTEGER NOT NULL DEFAULT 1",
      );
      await db.execute(
        "ALTER TABLE mentors ADD COLUMN userId TEXT NOT NULL DEFAULT ''",
      );
      await db.execute(
        "ALTER TABLE mentors ADD COLUMN status TEXT NOT NULL DEFAULT 'approved'",
      );
      await db.execute(
        "ALTER TABLE mentors ADD COLUMN isActive INTEGER NOT NULL DEFAULT 1",
      );
    }
    if (oldVersion < 3) {
      // These domains moved to the remote backend and no longer read/write
      // a local table.
      for (final table in [
        'users',
        'mentors',
        'bookings',
        'notifications',
        'reviews',
        'courses',
        'lessons',
        'enrollments',
      ]) {
        await db.execute('DROP TABLE IF EXISTS $table');
      }
    }
  }

  /// Wipes all remaining local tables. Used only by tests that need a clean
  /// slate.
  Future<void> resetAll() async {
    final db = await database;
    await db.delete('chat_messages');
    await db.delete('cv_analyses');
  }
}
