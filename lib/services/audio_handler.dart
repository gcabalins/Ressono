import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class MyAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final _player = AudioPlayer();

  MyAudioHandler() {
    _player.playerStateStream.listen(_broadcastState);
    _player.currentIndexStream.listen((index) {
      final list = queue.value;

      if (index != null && list.isNotEmpty && index < list.length) {
        mediaItem.add(list[index]);
      }

    });
  }

  void _broadcastState(PlayerState state) {
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          state.playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
        ],
        androidCompactActionIndices: const [0, 1, 2],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[state.processingState]!,
        playing: state.playing,
      ),
    );
  }

  Future<void> playFromList(
    List<Map<String, dynamic>> tracks,
    int index,
  ) async {
    final mediaItems = tracks.map((t) {
      return MediaItem(
        id: t['audio_url'],
        title: t['title'],
        artist: t['artist'] ?? '',
      );
    }).toList();

    queue.add(mediaItems);

    final sources = tracks.map((t) {
      return AudioSource.uri(Uri.parse(t['audio_url']));
    }).toList();

    await _player.setAudioSource(
      ConcatenatingAudioSource(children: sources),
      initialIndex: index,
    );

    await play();
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }
}