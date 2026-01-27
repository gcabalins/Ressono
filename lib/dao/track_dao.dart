import 'package:sqflite/sqflite.dart';
import '../models/track.dart';

class TrackDao {
  final Database db;

  TrackDao(this.db);

  /// ➕ Insertar track
  Future<void> insert(Track track) async {
    await db.insert(
      'tracks',
      track.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 📥 Obtener todos los tracks
  Future<List<Track>> getAll() async {
    final result = await db.query(
      'tracks',
      orderBy: 'rowid DESC',
    );

    return result.map(Track.fromMap).toList();
  }

  /// 🗑 Eliminar track (y referencias)
  Future<void> delete(String trackId) async {
    await db.transaction((txn) async {
      await txn.delete(
        'playlist_tracks',
        where: 'track_id = ?',
        whereArgs: [trackId],
      );

      await txn.delete(
        'tracks',
        where: 'id = ?',
        whereArgs: [trackId],
      );
    });
  }
}
