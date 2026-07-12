import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Singleton wrapper around the local SQLite database used as the
/// app's persistence layer (business scenario: mentor booking platform).
class AppDatabase {
  AppDatabase._internal();
  static final AppDatabase instance = AppDatabase._internal();

  static const int _version = 2;

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
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
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        passwordHash TEXT NOT NULL,
        role TEXT NOT NULL,
        phone TEXT,
        avatarUrl TEXT,
        isActive INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE mentors (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL DEFAULT '',
        name TEXT NOT NULL,
        title TEXT NOT NULL,
        bio TEXT NOT NULL,
        expertise TEXT NOT NULL,
        hourlyRate REAL NOT NULL,
        rating REAL NOT NULL,
        reviewCount INTEGER NOT NULL,
        avatarUrl TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        sessionAddress TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'approved',
        isActive INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE bookings (
        id TEXT PRIMARY KEY,
        studentId TEXT NOT NULL,
        mentorId TEXT NOT NULL,
        mentorName TEXT NOT NULL,
        sessionDate TEXT NOT NULL,
        timeSlot TEXT NOT NULL,
        durationMinutes INTEGER NOT NULL,
        price REAL NOT NULL,
        status TEXT NOT NULL,
        notes TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

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
      CREATE TABLE notifications (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        type TEXT NOT NULL,
        relatedId TEXT,
        createdAt TEXT NOT NULL,
        isRead INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE reviews (
        id TEXT PRIMARY KEY,
        mentorId TEXT NOT NULL,
        studentId TEXT NOT NULL,
        studentName TEXT NOT NULL,
        rating INTEGER NOT NULL,
        comment TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    await _createCourseTables(db);
  }

  Future<void> _createCourseTables(Database db) async {
    await db.execute('''
      CREATE TABLE courses (
        id TEXT PRIMARY KEY,
        mentorId TEXT NOT NULL,
        mentorName TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        thumbnailUrl TEXT NOT NULL,
        price REAL NOT NULL,
        status TEXT NOT NULL DEFAULT 'draft',
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE lessons (
        id TEXT PRIMARY KEY,
        courseId TEXT NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        durationMinutes INTEGER NOT NULL,
        orderIndex INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE enrollments (
        id TEXT PRIMARY KEY,
        studentId TEXT NOT NULL,
        courseId TEXT NOT NULL,
        progressPercent REAL NOT NULL DEFAULT 0,
        completedLessonIds TEXT NOT NULL DEFAULT '',
        enrolledAt TEXT NOT NULL,
        certificateIssued INTEGER NOT NULL DEFAULT 0
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
      await db.execute("ALTER TABLE users ADD COLUMN isActive INTEGER NOT NULL DEFAULT 1");
      await db.execute("ALTER TABLE mentors ADD COLUMN userId TEXT NOT NULL DEFAULT ''");
      await db.execute("ALTER TABLE mentors ADD COLUMN status TEXT NOT NULL DEFAULT 'approved'");
      await db.execute("ALTER TABLE mentors ADD COLUMN isActive INTEGER NOT NULL DEFAULT 1");
      await _createCourseTables(db);
    }
  }

  /// Wipes all tables. Used only by the seed routine on first launch
  /// and by tests that need a clean slate.
  Future<void> resetAll() async {
    final db = await database;
    await db.delete('users');
    await db.delete('mentors');
    await db.delete('bookings');
    await db.delete('chat_messages');
    await db.delete('notifications');
    await db.delete('reviews');
    await db.delete('courses');
    await db.delete('lessons');
    await db.delete('enrollments');
    await db.delete('cv_analyses');
  }
}
