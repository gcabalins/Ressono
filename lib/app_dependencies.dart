import 'package:supabase_flutter/supabase_flutter.dart';
import 'database/local_database.dart';
import 'dao/track_dao.dart';
import 'dao/playlist_dao.dart';
import 'services/track_sync_service.dart';
import 'services/audio_service.dart';
import 'repositories/track_repository.dart';
import 'repositories/playlist_repository.dart';
import 'services/playlist_sync_service.dart';

late final TrackRepository trackRepository;
late final PlaylistRepository playlistRepository;

Future<void> setupDependencies() async {
  // SQLite
  final database = await LocalDatabase.instance;

  // Core services
  final audioService = AudioService();
  final supabase = Supabase.instance.client;

  // DAOs
  final trackDao = TrackDao(database);
  final playlistDao = PlaylistDao(database);

  // Sync services
  final trackSyncService = TrackSyncService(supabase);
  final playlistSyncService = PlaylistSyncService(supabase);

  // Repositories
  trackRepository = TrackRepository(
    trackDao,
    trackSyncService,
    audioService,
  );

  playlistRepository = PlaylistRepository(
    playlistDao,
    playlistSyncService,
    audioService,
  );
}
