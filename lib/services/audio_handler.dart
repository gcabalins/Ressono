import 'package:audio_service/audio_service.dart';
import 'audio_controller.dart' as app; 

class AppAudioHandler extends BaseAudioHandler {
  final app.AudioController audio = app.AudioController();

  AppAudioHandler() {
    // Estado inicial
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          MediaControl.play,
          MediaControl.pause,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.play,
          MediaAction.pause,
          MediaAction.skipToNext,
          MediaAction.skipToPrevious,
        },
        playing: audio.isPlaying,
      ),
    );

    // Escuchar cambios de tu reproductor
    audio.addListener(_syncState);
  }

  void _syncState() {
    playbackState.add(
      playbackState.value.copyWith(
        playing: audio.isPlaying,
      ),
    );
  }

  // 🎧 CASCOS / SISTEMA
  @override
  Future<void> play() async {
    print('🎧 PLAY desde sistema');
    audio.togglePlayPause();
  }

  @override
  Future<void> pause() async {
    print('🎧 PAUSE desde sistema');
    audio.togglePlayPause();
  }

  @override
  Future<void> skipToNext() async {
    print('🎧 NEXT desde sistema');
    audio.playNext();
  }

  @override
  Future<void> skipToPrevious() async {
    print('🎧 PREVIOUS desde sistema');
    audio.playPrevious();
  }

  @override
  Future<void> stop() async {
    print('🎧 STOP desde sistema');
    audio.stopAndClear();
  }
}
