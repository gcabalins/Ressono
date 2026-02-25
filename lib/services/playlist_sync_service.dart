import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles remote synchronization of playlists
/// and playlist-track relations with Supabase.
///
/// This service is responsible only for remote
/// persistence and does not manage local state.
class PlaylistSyncService {
  final SupabaseClient _supabase;

  /// Creates a PlaylistSyncService instance.
  PlaylistSyncService(this._supabase);

  /// Creates a playlist in the remote database.
  ///
  /// Inserts a new record into the `playlists` table.
  Future<void> syncCreatePlaylist({
    required String playlistId,
    required String name,
    required String userId,
  }) async {
    await _supabase.from('playlists').insert({
      'id': playlistId,
      'user_id': userId,
      'name': name,
    });
  }

  /// Deletes a playlist from the remote database.
  ///
  /// Removes the record from the `playlists` table.
  Future<void> syncDeletePlaylist(String playlistId) async {
    await _supabase
        .from('playlists')
        .delete()
        .eq('id', playlistId);
  }

  /// Adds a track to a playlist in the remote database.
  ///
  /// Inserts a relation into the `playlist_tracks` table.
  Future<void> syncAddTrack(
    String playlistId,
    String trackId,
  ) async {
    await _supabase.from('playlist_tracks').insert({
      'playlist_id': playlistId,
      'track_id': trackId,
    });
  }

  /// Removes a track from a playlist in the remote database.
  ///
  /// Deletes the relation from the `playlist_tracks` table.
  Future<void> syncRemoveTrack(
    String playlistId,
    String trackId,
  ) async {
    await _supabase
        .from('playlist_tracks')
        .delete()
        .eq('playlist_id', playlistId)
        .eq('track_id', trackId);
  }
}