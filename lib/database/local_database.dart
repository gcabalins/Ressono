import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabase {
  static Database? _db;
  

  static Future<Database> get instance async {
    if (_db != null) return _db!;

    final path = join(await getDatabasesPath(), 'resono.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async { if (oldVersion < 2) { await db.execute('ALTER TABLE playlists ADD COLUMN created_at TEXT'); } },
    );

    return _db!;
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tracks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        artist TEXT,
        audio_url TEXT NOT NULL,
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
