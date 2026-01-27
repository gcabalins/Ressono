import '../dao/playlist_dao.dart';
import '../services/playlist_sync_service.dart';
import '../services/audio_service.dart';
import '../models/playlist.dart';
import '../models/track.dart';
import 'package:uuid/uuid.dart'; 


class PlaylistRepository {
  final PlaylistDao _dao;
  final PlaylistSyncService _sync;
  final AudioService _audio;

  PlaylistRepository(
    this._dao,
    this._sync,
    this._audio,
  );

  Future<List<Playlist>> getAllPlaylists() {
    return _dao.getAll();
  }

  Future<List<Track>> getTracksForPlaylist(String playlistId) {
    return _dao.getTracks(playlistId);
  }

  Future<void> addTrackToPlaylist({
    required String playlistId,
    required Track track,
  }) async {
    await _dao.addTrack(playlistId, track.id);
    _sync.syncAddTrack(playlistId, track.id);
  }

  Future<void> removeTrackFromPlaylist({
    required String playlistId,
    required Track track,
  }) async {
    await _dao.removeTrack(playlistId, track.id);
    _audio.onTrackDeleted(track.id);
    _sync.syncRemoveTrack(playlistId, track.id);
  }
  Future<void> createPlaylist(String name) async { 
    final uuid = Uuid(); 
    final playlistId = uuid.v4(); 
    final playlist = Playlist( 
      id: playlistId, 
      name: name, 
      createdAt: DateTime.now(), 
    ); 
    // Guardar en SQLite 
    await _dao.insertPlaylist(playlist); 
    // Sincronizar con Supabase 
    await _sync.syncCreatePlaylist( 
      playlistId: playlistId, 
      name: name, 
      userId: "7a5b6cb5-45f2-43b4-bc4c-e90c8eea7e77", 
      ); 
  }
}
