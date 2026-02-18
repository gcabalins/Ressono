import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/track.dart';
import './audio_cache_manager.dart';
import 'package:path_provider/path_provider.dart';



/// ===============================
///  PICK AUDIO (MÓVIL)
/// ===============================

class PickedAudio {
  final File file;
  final String name;

  PickedAudio({
    required this.file,
    required this.name,
  });
}

Future<PickedAudio?> pickAudioFile() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.audio,
  );

  if (result == null || result.files.single.path == null) return null;

  return PickedAudio(
    file: File(result.files.single.path!),
    name: result.files.single.name,
  );
}

Future<int> getAudioDurationSeconds(String audioUrl) async {
  final player = AudioPlayer();
  try {
    await player.setUrl(audioUrl);
    return player.duration?.inSeconds ?? 0;
  } finally {
    await player.dispose();
  }
}

/// ===============================
///  AUDIO SERVICE (MVP)
/// ===============================

class AudioService extends ChangeNotifier {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal() {
    _init();
  }

  final AudioPlayer _player = AudioPlayer();
  final List<Track> _queue = [];
  int _currentIndex = -1;
  String? _currentSourceLabel;

  AudioPlayer get player => _player;
  bool get isPlaying => _player.playing;
  String? get currentSourceLabel => _currentSourceLabel;

  Track? get currentTrack =>
      (_currentIndex >= 0 && _currentIndex < _queue.length)
          ? _queue[_currentIndex]
          : null;

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

  /// ➕ Añadir track (desde Upload)
  Future<void> addTrack(Track track) async {
    _queue.add(track);
    notifyListeners();
  }

  /// ▶️ Reproducir lista
  Future<void> playFromList(List<Track> tracks, int index, String? sourceLabel,
  ) async {
    _queue
      ..clear()
      ..addAll(tracks);

    _currentIndex = index;
    _currentSourceLabel = sourceLabel;
    AudioService().printCachedTracks();



    notifyListeners();

    final sources = <AudioSource>[];

    for (final t in tracks) {
      final file = await AudioCacheManager.manager.getSingleFile(t.audioUrl);

      sources.add(
        AudioSource.uri(
          Uri.file(file.path),
        ),
      );
    }



    await _player.setAudioSource(
      ConcatenatingAudioSource(children: sources),
      initialIndex: index,
    );

    await _player.play();
    
  }

  /// ⏯ Play / Pause
  void togglePlayPause() {
    if (_player.playing) {
      _player.pause();
    } else {
      _player.play();
    }
    notifyListeners();
  }

  /// ⏭ Siguiente
  void playNext() {
    if (_player.hasNext) {
      _player.seekToNext();
    }
  }

  /// ⏮ Anterior
  void playPrevious() {
    if (_player.hasPrevious) {
      _player.seekToPrevious();
    }
  }

  /// ⏹ Stop
  void stopAndClear() {
    _player.stop();
    _queue.clear();
    _currentIndex = -1;
    notifyListeners();
  }
  void onTrackDeleted(String trackId) {
    _queue.removeWhere((t) => t.id == trackId);

    if (_currentIndex >= _queue.length) {
      _currentIndex = _queue.isEmpty ? -1 : _queue.length - 1;
    }

    notifyListeners();
  }


Future<void> printCachedTracks() async {
  final dir = await getTemporaryDirectory();
  final cacheDir = Directory("${dir.path}/audioCache");

  if (!cacheDir.existsSync()) {
    print("📭 No existe la carpeta de caché");
    return;
  }

  final files = cacheDir.listSync();

  if (files.isEmpty) {
    print("📭 No hay canciones en la caché");
    return;
  }

  print("🎵 Canciones en caché (${files.length}):");

  for (final f in files) {
    if (f is File) {
      final size = await f.length();
      print("""
-------------------------
Archivo: ${f.path.split('/').last}
Ruta:    ${f.path}
Tamaño:  $size bytes
-------------------------
""");
    }
  }
}

}
