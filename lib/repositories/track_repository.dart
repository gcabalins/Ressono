import '../models/track.dart';
import '../services/audio_service.dart';
import '../services/track_sync_service.dart';
import '../dao/track_dao.dart';

class TrackRepository {
  final TrackDao _dao;
  final TrackSyncService _sync;
  final AudioService _audio;

  TrackRepository(
    this._dao,
    this._sync,
    this._audio,
  );

  Future<List<Track>> getAllTracks() {
    return _dao.getAll();
  }

  Future<void> insertTrack(Track track) async {
    await _dao.insert(track);
    _sync.syncInsert(track);
  }

  Future<void> deleteTrack(Track track) async {
    await _dao.delete(track.id);
    _audio.onTrackDeleted(track.id);
    _sync.syncDelete(track.id, _audioPathFromTrack(track));
  }

  String _audioPathFromTrack(Track track) {
    return '${track.id}.mp3';
  }
}
