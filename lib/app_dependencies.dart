import 'package:supabase_flutter/supabase_flutter.dart';
import 'database/local_database.dart';
import 'dao/track_dao.dart';
import 'dao/playlist_dao.dart';
import 'services/track_sync_service.dart';
import 'services/audio_service.dart';
import 'repositories/track_repository.dart';
import 'repositories/playlist_repository.dart';
import 'services/playlist_sync_service.dart';

/// Global repository instances.
///
/// These are initialized during application bootstrap
/// and provide access to the data layer across the app.
late final TrackRepository trackRepository;
late final PlaylistRepository playlistRepository;

/// Configures and initializes all application dependencies.
///
/// This function acts as the composition root of the app,
/// wiring together:
/// - Local database
/// - Data access objects (DAOs)
/// - Remote synchronization services
/// - Core infrastructure services
/// - Repositories
///
/// Must be executed before runApp().
Future<void> setupDependencies() async {
  // Initialize local SQLite database.
  final database = await LocalDatabase.instance;

  // Initialize core services.
  final audioService = AudioService();
  final supabase = Supabase.instance.client;

  // Initialize data access objects.
  final trackDao = TrackDao(database);
  final playlistDao = PlaylistDao(database);

  // Initialize remote synchronization services.
  final trackSyncService = TrackSyncService(supabase);
  final playlistSyncService = PlaylistSyncService(supabase);

  // Initialize repositories.
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