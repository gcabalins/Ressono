import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'audio_cache.dart';
import 'metadata_cache.dart';


final AudioCacheManager _cache = AudioCacheManager();
final supabase = Supabase.instance.client;


/// ===============================
///  PICK + UPLOAD (IGUAL QUE ANTES)
/// ===============================

class PickedAudio {
  final File? file;       // móvil
  final List<int>? bytes; // web
  final String name;

  PickedAudio({
    this.file,
    this.bytes,
    required this.name,
  });
}

Future<PickedAudio?> pickAudioFile() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['mp3', 'wav', 'm4a'],
    withData: kIsWeb,
  );

  if (result == null) {
    print('❌ Selección cancelada');
    return null;
  }

  final file = result.files.single;

  if (kIsWeb) {
    if (file.bytes == null) {
      print('❌ Archivo WEB sin bytes');
      return null;
    }

    print('🌐 Archivo seleccionado en WEB: ${file.name}');
    return PickedAudio(
      bytes: file.bytes!,
      name: file.name,
    );
  }

  if (file.path == null) {
    print('❌ Archivo móvil sin path');
    return null;
  }

  print('📱 Archivo seleccionado en MÓVIL: ${file.path}');
  return PickedAudio(
    file: File(file.path!),
    name: file.name,
  );
}

Future<String> uploadAudioFile(PickedAudio audio) async {
  final user = supabase.auth.currentUser;
  if (user == null) throw Exception('Necesitas estar logueado');

  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final filePath = 'users/${user.id}/$timestamp.mp3';

  final storage = supabase.storage.from('audio');

  if (kIsWeb) {
    print('⬆️ Subiendo audio WEB: ${audio.name}');
    await storage.uploadBinary(
      filePath,
      Uint8List.fromList(audio.bytes!),
      fileOptions: const FileOptions(
        contentType: 'audio/mpeg',
      ),
    );
  } else {
    print('⬆️ Subiendo audio MÓVIL: ${audio.name}');
    await storage.upload(filePath, audio.file!);
  }

  final url = storage.getPublicUrl(filePath);
  print('✅ Audio subido: $url');

  return url;
}


Future<int> getAudioDurationSeconds(File file) async {
  final player = AudioPlayer();
  try {
    await player.setFilePath(file.path);
    return player.duration?.inSeconds ?? 0;
  } catch (e) {
    print('❌ Error obteniendo duración: $e');
    return 0;
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

  print('✅ Track insertado: $title');
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
  String? _sourceLabel;
  String? get sourceLabel => _sourceLabel;

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
    int index ,{
    String? sourceLabel,
  }) async {
    _queue = tracks;
    _sourceLabel = sourceLabel;
    print('▶️ Reproduciendo de lista $sourceLabel');


    final sources = <AudioSource>[];

    for (final track in tracks) {
      final id = track['id'].toString();
      final url = track['audio_url'];

      final cachedFile = await _cache.getCachedAudio(trackId: id, audioUrl: url);

      if (cachedFile != null) {
        print('▶️ Reproduciendo desde CACHE: $id');
        sources.add(AudioSource.file(cachedFile.path));
      } else {
        print('🌐 Reproduciendo desde RED: $id');
        sources.add(AudioSource.uri(Uri.parse(url)));
      }
       _cache.cacheInBackground(trackId: id, audioUrl: url);
    }
      

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
    _sourceLabel = null;
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
    final cache = MetadataCache();
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('No autenticado');

    try {
      final data = await supabase
          .from('playlists')
          .select('id, name, created_at')
          .eq('user_id', user.id)
          .order('created_at');

      final playlists = List<Map<String, dynamic>>.from(data);
      await cache.save('playlists', playlists);
      return playlists;
    } catch (_) {
      final cached = await cache.load('playlists');
      if (cached != null) {
        print('⚠️ Sin internet → usando playlists cacheadas');
        return cached;
      }
      rethrow;
    }
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
  final cache = MetadataCache();
  final key = 'playlist_$playlistId';

  try {
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

    final tracks = data.map<Map<String, dynamic>>((row) {
      return {
        'position': row['position'],
        ...row['tracks'],
      };
    }).toList();

    await cache.save(key, tracks);
    return tracks;
  } catch (_) {
    final cached = await cache.load(key);
    if (cached != null) {
      print('⚠️ Sin internet → usando canciones cacheadas');
      return cached;
    }
    rethrow;
  }
}

Future<int> getDurationFromUrl(String url) async {
  final player = AudioPlayer();
  print('⏱️ Leyendo duración desde URL: $url');

  try {
    await player.setUrl(url);

    // Esperar hasta que durationStream emita un valor distinto de null
    final duration = await player.durationStream.firstWhere(
      (d) => d != null,
      orElse: () => null,
    );

    if (duration != null) {
      print('⏱️ Duración obtenida desde URL: ${duration.inSeconds}s');
      return duration.inSeconds;
    } else {
      print('⚠️ No se pudo obtener la duración desde URL');
      return 0;
    }
  } catch (e) {
    print('❌ Error leyendo duración desde URL: $e');
    return 0;
  } finally {
    await player.dispose();
  }
}

Future<void> updateTrackDuration({
  required String audioUrl,
  required int durationSeconds,
}) async {
  await supabase
      .from('tracks')
      .update({'duration_seconds': durationSeconds})
      .eq('audio_url', audioUrl);

  print('✅ Duración actualizada en BD');
}
