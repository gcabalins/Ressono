import 'package:sqflite/sqflite.dart';
import '../models/playlist.dart';
import '../models/track.dart';

class PlaylistDao {
  final Database db;

  PlaylistDao(this.db);

  /// 📥 Obtener playlists
  Future<List<Playlist>> getAll() async {
    final result = await db.query(
      'playlists',
      orderBy: 'rowid DESC',
    );

    return result.map(Playlist.fromMap).toList();
  }

  /// 📥 Tracks de una playlist
  Future<List<Track>> getTracks(String playlistId) async {
    final result = await db.rawQuery('''
      SELECT t.*
      FROM tracks t
      INNER JOIN playlist_tracks pt
        ON pt.track_id = t.id
      WHERE pt.playlist_id = ?
      ORDER BY pt.rowid ASC
    ''', [playlistId]);

    return result.map(Track.fromMap).toList();
  }

  /// ➕ Añadir track a playlist
  Future<void> addTrack(String playlistId, String trackId) async {
    await db.insert(
      'playlist_tracks',
      {
        'playlist_id': playlistId,
        'track_id': trackId,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// 🗑 Eliminar track de playlist
  Future<void> removeTrack(String playlistId, String trackId) async {
    await db.delete(
      'playlist_tracks',
      where: 'playlist_id = ? AND track_id = ?',
      whereArgs: [playlistId, trackId],
    );
  }
  Future<void> insertPlaylist(Playlist playlist) async {
    await db.insert(
      'playlists',
      playlist.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

}
