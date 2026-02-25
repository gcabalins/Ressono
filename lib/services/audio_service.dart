import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/track.dart';
import './audio_cache_manager.dart';

/// Represents a picked local audio file.
class PickedAudio {
  final File file;
  final String name;

  PickedAudio({
    required this.file,
    required this.name,
  });
}

/// Opens a file picker restricted to audio files.
///
/// Returns a PickedAudio instance if a file is selected,
/// otherwise returns null.
Future<PickedAudio?> pickAudioFile() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.audio,
  );

  if (result == null || result.files.single.path == null) {
    return null;
  }

  return PickedAudio(
    file: File(result.files.single.path!),
    name: result.files.single.name,
  );
}

/// Retrieves audio duration in seconds from a remote URL.
///
/// A temporary AudioPlayer instance is created and disposed.
Future<int> getAudioDurationSeconds(String audioUrl) async {
  final player = AudioPlayer();
  try {
    await player.setUrl(audioUrl);
    return player.duration?.inSeconds ?? 0;
  } finally {
    await player.dispose();
  }
}

/// Central audio playback service.
///
/// Responsibilities:
/// - Manage playback state.
/// - Maintain playback queue.
/// - Handle track changes.
/// - Notify UI listeners of state updates.
///
/// Implemented as a singleton.
class AudioService extends ChangeNotifier {
  static final AudioService _instance =
      AudioService._internal();

  /// Returns the singleton instance.
  factory AudioService() => _instance;

  AudioService._internal() {
    _init();
  }

  final AudioPlayer _player = AudioPlayer();
  final List<Track> _queue = [];

  int _currentIndex = -1;
  String? _currentSourceLabel;

  /// Exposes the internal AudioPlayer.
  AudioPlayer get player => _player;

  /// Indicates whether playback is active.
  bool get isPlaying => _player.playing;

  /// Optional label describing the source of the current queue.
  String? get currentSourceLabel => _currentSourceLabel;

  /// Returns the currently active track.
  Track? get currentTrack =>
      (_currentIndex >= 0 && _currentIndex < _queue.length)
          ? _queue[_currentIndex]
          : null;

  /// Initializes player listeners.
  ///
  /// Subscribes to:
  /// - current index changes
  /// - player state changes
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

  /// Adds a track to the internal queue.
  Future<void> addTrack(Track track) async {
    _queue.add(track);
    notifyListeners();
  }

  /// Replaces the current queue and starts playback.
  ///
  /// Steps:
  /// - Clears existing queue
  /// - Loads cached audio files
  /// - Sets audio source
  /// - Starts playback
  Future<void> playFromList(
    List<Track> tracks,
    int index,
    String? sourceLabel,
  ) async {
    _queue
      ..clear()
      ..addAll(tracks);

    _currentIndex = index;
    _currentSourceLabel = sourceLabel;

    notifyListeners();

    final sources = <AudioSource>[];

    for (final t in tracks) {
      final file =
          await AudioCacheManager.manager.getSingleFile(t.audioUrl);

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

  /// Toggles between play and pause states.
  void togglePlayPause() {
    if (_player.playing) {
      _player.pause();
    } else {
      _player.play();
    }
    notifyListeners();
  }

  /// Skips to the next track if available.
  void playNext() {
    if (_player.hasNext) {
      _player.seekToNext();
    }
  }

  /// Returns to the previous track if available.
  void playPrevious() {
    if (_player.hasPrevious) {
      _player.seekToPrevious();
    }
  }

  /// Stops playback and clears the queue.
  void stopAndClear() {
    _player.stop();
    _queue.clear();
    _currentIndex = -1;
    notifyListeners();
  }

  /// Stops playback without clearing queue.
  void stopOnProfile() {
    _player.stop();
    _currentIndex = -1;
    notifyListeners();
  }

  /// Removes a deleted track from the queue.
  ///
  /// Adjusts current index if necessary.
  void onTrackDeleted(String trackId) {
    _queue.removeWhere((t) => t.id == trackId);

    if (_currentIndex >= _queue.length) {
      _currentIndex =
          _queue.isEmpty ? -1 : _queue.length - 1;
    }

    notifyListeners();
  }
}