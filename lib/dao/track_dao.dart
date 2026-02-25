import 'package:sqflite/sqflite.dart';
import '../models/track.dart';

/// Data Access Object responsible for track-related
/// database operations.
///
/// Provides methods to:
/// - Insert tracks
/// - Retrieve tracks
/// - Delete tracks and clean related references
class TrackDao {
  final Database db;

  /// Creates a TrackDao instance with a database reference.
  TrackDao(this.db);

  /// Inserts or replaces a track in the database.
  Future<void> insert(Track track) async {
    await db.insert(
      'tracks',
      track.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieves all tracks ordered by most recently inserted.
  Future<List<Track>> getAll() async {
    final result = await db.query(
      'tracks',
      orderBy: 'rowid DESC',
    );

    return result.map(Track.fromMap).toList();
  }

  /// Deletes a track and removes its references
  /// from playlist-track relations.
  ///
  /// Executed inside a transaction to ensure consistency.
  Future<void> delete(String trackId) async {
    await db.transaction((txn) async {

      // Remove references from playlist_tracks.
      await txn.delete(
        'playlist_tracks',
        where: 'track_id = ?',
        whereArgs: [trackId],
      );

      // Remove the track itself.
      await txn.delete(
        'tracks',
        where: 'id = ?',
        whereArgs: [trackId],
      );
    });
  }
}