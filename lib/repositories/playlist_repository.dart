import '../dao/playlist_dao.dart';
import '../services/playlist_sync_service.dart';
import '../services/audio_service.dart';
import '../models/playlist.dart';
import '../models/track.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository responsible for playlist-related business logic.
///
/// This layer coordinates:
/// - Local persistence (SQLite via DAO)
/// - Remote synchronization (Supabase)
/// - Audio state management
///
/// It acts as the abstraction between the UI and data sources.
class PlaylistRepository {
  final PlaylistDao _dao;
  final PlaylistSyncService _sync;
  final AudioService _audio;

  /// Creates a PlaylistRepository with required dependencies.
  PlaylistRepository(
    this._dao,
    this._sync,
    this._audio,
  );

  /// Returns all locally stored playlists.
  Future<List<Playlist>> getAllPlaylists() {
    return _dao.getAll();
  }

  /// Returns all tracks associated with a specific playlist.
  Future<List<Track>> getTracksForPlaylist(String playlistId) {
    return _dao.getTracks(playlistId);
  }

  /// Adds a track to a playlist.
  ///
  /// Performs:
  /// - Local relation insertion
  /// - Remote synchronization
  Future<void> addTrackToPlaylist({
    required String playlistId,
    required Track track,
  }) async {
    await _dao.addTrack(playlistId, track.id);
    _sync.syncAddTrack(playlistId, track.id);
  }

  /// Removes a track from a playlist.
  ///
  /// Performs:
  /// - Local relation deletion
  /// - Audio state update
  /// - Remote synchronization
  Future<void> removeTrackFromPlaylist({
    required String playlistId,
    required Track track,
  }) async {
    await _dao.removeTrack(playlistId, track.id);
    _audio.onTrackDeleted(track.id);
    _sync.syncRemoveTrack(playlistId, track.id);
  }

  /// Creates a new playlist.
  ///
  /// Performs:
  /// - Unique ID generation
  /// - Local insertion
  /// - Remote synchronization
  Future<void> createPlaylist(String name) async {
    final uuid = Uuid();
    final playlistId = uuid.v4();

    final userId = Supabase.instance.client.auth.currentUser!.id;

    final playlist = Playlist(
      id: playlistId,
      name: name,
      createdAt: DateTime.now(),
    );

    await _dao.insertPlaylist(playlist);

    await _sync.syncCreatePlaylist(
      playlistId: playlistId,
      name: name,
      userId: userId,
    );
  }

  /// Deletes a playlist.
  ///
  /// Performs:
  /// - Track retrieval (for audio cleanup)
  /// - Local deletion
  /// - Remote synchronization
  /// - Audio state update
  Future<void> deletePlaylist(String playlistId) async {

    // Retrieve tracks before deletion for audio cleanup.
    final tracks = await _dao.getTracks(playlistId);

    // Delete locally.
    await _dao.deletePlaylist(playlistId);

    // Synchronize remotely.
    await _sync.syncDeletePlaylist(playlistId);

    // Update audio state if any deleted track was active.
    for (final track in tracks) {
      _audio.onTrackDeleted(track.id);
    }
  }
}