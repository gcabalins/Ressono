import 'package:audio_service/audio_service.dart';
import 'package:Ressono/services/audio_handler.dart';


late final AudioHandler audioHandler;

Future<void> initAudioService() async {
  audioHandler = await AudioService.init(
    builder: () => AppAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.ressono.audio',
      androidNotificationChannelName: 'Ressono Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );
}
