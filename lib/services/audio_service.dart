import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

final supabase = Supabase.instance.client;

/// ===============================
///  PICK + UPLOAD (IGUAL QUE ANTES)
/// ===============================

Future<File?> pickAudioFile() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['mp3', 'wav', 'm4a'],
  );

  if (result == null || result.files.single.path == null) return null;
  return File(result.files.single.path!);
}

Future<String> uploadAudioFile(File file) async {
  final user = supabase.auth.currentUser;
  if (user == null) throw Exception('Necesitas estar logueado');

  final fileName = DateTime.now().millisecondsSinceEpoch.toString();
  final filePath = 'users/${user.id}/$fileName.mp3';

  final storage = supabase.storage.from('audio');
  await storage.upload(filePath, file);

  return storage.getPublicUrl(filePath);
}

Future<int?> getAudioDurationSeconds(File file) async {
  final player = AudioPlayer();
  try {
    await player.setFilePath(file.path);
    return player.duration?.inSeconds;
  } finally {
    await player.dispose();
  }
}

Future<void> insertTrack({
  required String title,
  String? artist,
  required String audioUrl,
  required int durationSeconds,
}) async {
  final user = supabase.auth.currentUser;
  if (user == null) throw Exception('Necesitas estar logueado');

  await supabase.from('tracks').insert({
    'user_id': user.id,
    'title': title,
    'artist': artist,
    'audio_url': audioUrl,
    'duration_seconds': durationSeconds,
  });
}

Future<List<Map<String, dynamic>>> fetchTracks() async {
  final user = supabase.auth.currentUser;
  if (user == null) throw Exception('Necesitas estar logueado');

  final data = await supabase
      .from('tracks')
      .select('id, title, artist, audio_url, duration_seconds')
      .eq('user_id', user.id)
      .order('created_at', ascending: false);

  return List<Map<String, dynamic>>.from(data);
}

/// ===============================
///  AUDIO CONTROLLER (CLAVE)
/// ===============================

class AudioService extends ChangeNotifier {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal() {
    _init();
  }

  final AudioPlayer _player = AudioPlayer();
  List<Map<String, dynamic>> _queue = [];
  int _currentIndex = -1;

  AudioPlayer get player => _player;

  Map<String, dynamic>? get currentTrack =>
      (_currentIndex >= 0 && _currentIndex < _queue.length)
          ? _queue[_currentIndex]
          : null;

  bool get isPlaying => _player.playing;

  void _init() {
    _player.currentIndexStream.listen((index) {
      if (index != null) {
        _currentIndex = index;
        notifyListeners();
      }
    });

    _player.playerStateStream.listen((_) {
      notifyListeners();
    });
  }

  Future<void> playFromList(
    List<Map<String, dynamic>> tracks,
    int index,
  ) async {
    _queue = tracks;

    final sources = tracks.map((t) {
      return AudioSource.uri(Uri.parse(t['audio_url']));
    }).toList();

    await _player.setAudioSource(
      ConcatenatingAudioSource(children: sources),
      initialIndex: index,
    );

    await _player.play();
    notifyListeners();
  }

  void togglePlayPause() {
    _player.playing ? _player.pause() : _player.play();
    notifyListeners();
  }

  void stopAndClear() {
    _player.stop();
    _queue = [];
    _currentIndex = -1;
    notifyListeners();
  }
  void playNext() {
    if (_player.hasNext) {
      _player.seekToNext();
    }
  }

  void playPrevious() {
    if (_player.hasPrevious) {
      _player.seekToPrevious();
    }
  }

}
  Future<void> createPlaylist(String name) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('No autenticado');

    await supabase.from('playlists').insert({
      'user_id': user.id,
      'name': name,
    });
  }
  Future<List<Map<String, dynamic>>> fetchPlaylists() async {
  final user = supabase.auth.currentUser;
  if (user == null) throw Exception('No autenticado');

  final data = await supabase
      .from('playlists')
      .select('id, name, created_at')
      .eq('user_id', user.id)
      .order('created_at');

  return List<Map<String, dynamic>>.from(data);
}
Future<void> addTrackToPlaylist({
  required String playlistId,
  required String trackId,
}) async {
  // obtener posición actual máxima
  final existing = await supabase
      .from('playlist_tracks')
      .select('position')
      .eq('playlist_id', playlistId)
      .order('position', ascending: false)
      .limit(1);

  int nextPosition = 0;
  if (existing.isNotEmpty) {
    nextPosition = (existing.first['position'] as int) + 1;
  }

  await supabase.from('playlist_tracks').insert({
    'playlist_id': playlistId,
    'track_id': trackId,
    'position': nextPosition,
  });
}

Future<List<Map<String, dynamic>>> fetchTracksFromPlaylist(
  String playlistId,
) async {
  final data = await supabase
      .from('playlist_tracks')
      .select('''
        position,
        tracks (
          id,
          title,
          artist,
          audio_url,
          duration_seconds
        )
      ''')
      .eq('playlist_id', playlistId)
      .order('position');

  return data.map<Map<String, dynamic>>((row) {
    return {
      'position': row['position'],
      ...row['tracks'],
    };
  }).toList();
}


