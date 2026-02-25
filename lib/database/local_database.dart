import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Provides access to the local SQLite database.
///
/// This class:
/// - Manages database initialization.
/// - Handles schema creation.
/// - Manages version upgrades.
/// - Exposes a singleton database instance.
class LocalDatabase {
  static Database? _db;

  /// Returns the singleton database instance.
  ///
  /// If the database has not been initialized yet,
  /// it will be created and configured.
  static Future<Database> get instance async {
    if (_db != null) return _db!;

    final path = join(await getDatabasesPath(), 'resono.db');

    _db = await openDatabase(
      path,
      version: 1,

      /// Called when the database is first created.
      onCreate: _onCreate,
    );

    return _db!;
  }

  /// Creates the initial database schema.
  ///
  /// Defines:
  /// - tracks table
  /// - playlists table
  /// - playlist_tracks join table
  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tracks (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        artist TEXT,
        audio_url TEXT NOT NULL,
        created_at TEXT NOT NULL,
        duration_seconds INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE playlists (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE playlist_tracks (
        playlist_id TEXT,
        track_id TEXT,
        position INTEGER,
        PRIMARY KEY (playlist_id, track_id)
      )
    ''');
  }
}