import 'package:sqflite/sqflite.dart';
import '../models/playlist.dart';
import '../models/track.dart';

/// Data Access Object responsible for playlist-related
/// database operations.
///
/// Provides methods to:
/// - Retrieve playlists
/// - Manage playlist-track relationships
/// - Insert and delete playlists
class PlaylistDao {
  final Database db;

  /// Creates a PlaylistDao instance with a database reference.
  PlaylistDao(this.db);

  /// Retrieves all playlists ordered by most recently inserted.
  Future<List<Playlist>> getAll() async {
    final result = await db.query(
      'playlists',
      orderBy: 'rowid DESC',
    );

    return result.map(Playlist.fromMap).toList();
  }

  /// Retrieves all tracks associated with a given playlist.
  ///
  /// Uses an INNER JOIN between tracks and playlist_tracks.
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

  /// Inserts a relation between a track and a playlist.
  ///
  /// If the relation already exists, it will be ignored.
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

  /// Removes the relation between a track and a playlist.
  Future<void> removeTrack(String playlistId, String trackId) async {
    await db.delete(
      'playlist_tracks',
      where: 'playlist_id = ? AND track_id = ?',
      whereArgs: [playlistId, trackId],
    );
  }

  /// Inserts or replaces a playlist in the database.
  Future<void> insertPlaylist(Playlist playlist) async {
    await db.insert(
      'playlists',
      playlist.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Deletes a playlist and its associated relations.
  ///
  /// This operation is executed inside a transaction to ensure
  /// atomic consistency.
  Future<void> deletePlaylist(String playlistId) async {
    await db.transaction((txn) async {

      // Remove playlist-track relations.
      await txn.delete(
        'playlist_tracks',
        where: 'playlist_id = ?',
        whereArgs: [playlistId],
      );

      // Remove the playlist itself.
      await txn.delete(
        'playlists',
        where: 'id = ?',
        whereArgs: [playlistId],
      );
    });
  }
}