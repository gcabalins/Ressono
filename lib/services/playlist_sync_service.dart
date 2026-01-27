import 'package:supabase_flutter/supabase_flutter.dart';

class PlaylistSyncService {
  final SupabaseClient _supabase;

  PlaylistSyncService(this._supabase);

  /// ➕ Crear playlist en Supabase
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

  /// 🗑 Eliminar playlist
  Future<void> syncDeletePlaylist(String playlistId) async {
    await _supabase
        .from('playlists')
        .delete()
        .eq('id', playlistId);
  }

  /// ➕ Añadir track a playlist
  Future<void> syncAddTrack(
    String playlistId,
    String trackId,
  ) async {
    await _supabase.from('playlist_tracks').insert({
      'playlist_id': playlistId,
      'track_id': trackId,
    });
  }

  /// 🗑 Eliminar track de playlist
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
