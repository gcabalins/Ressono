import '../models/track.dart';
import '../services/audio_service.dart';
import '../services/track_sync_service.dart';
import '../dao/track_dao.dart';

/// Repository responsible for track-related business logic.
///
/// Coordinates:
/// - Local persistence (SQLite)
/// - Remote synchronization
/// - Audio state management
class TrackRepository {
  final TrackDao _dao;
  final TrackSyncService _sync;
  final AudioService _audio;

  /// Creates a TrackRepository with required dependencies.
  TrackRepository(
    this._dao,
    this._sync,
    this._audio,
  );

  /// Returns all locally stored tracks.
  Future<List<Track>> getAllTracks() {
    return _dao.getAll();
  }

  /// Inserts a new track.
  ///
  /// Performs:
  /// - Local insertion
  /// - Remote synchronization
  Future<void> insertTrack(Track track) async {
    await _dao.insert(track);
    _sync.syncInsert(track);
  }

  /// Deletes a track.
  ///
  /// Performs:
  /// - Local deletion
  /// - Audio state update
  /// - Optional remote synchronization
  Future<void> deleteTrack(Track track) async {
    await _dao.delete(track.id);
    _audio.onTrackDeleted(track.id);

    // Remote deletion intentionally disabled.
    // _sync.syncDelete(track.id, _audioPathFromTrack(track));
  }

  // Optional helper for building remote audio path.
  // String _audioPathFromTrack(Track track) {
  //   return '${track.id}.mp3';
  // }
}