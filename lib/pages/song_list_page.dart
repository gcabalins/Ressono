import 'package:flutter/material.dart';
import '../app_dependencies.dart';
import '../services/audio_service.dart';
import '../models/track.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// SongListPage
///
/// Displays the list of available tracks in the library.
///
/// Responsibilities:
/// - Fetch tracks from repository
/// - Load uploader avatars from Supabase
/// - Handle playback interactions
/// - Provide track management options
class SongListPage extends StatefulWidget {
  const SongListPage({super.key});

  @override
  State<SongListPage> createState() => _SongListPageState();
}

/// _SongListPageState
///
/// State management for SongListPage.
///
/// Responsibilities:
/// - Maintain track list future
/// - Sync UI with AudioService playback state
/// - Handle track options and playlist operations
class _SongListPageState extends State<SongListPage> {
  late Future<List<Track>> _tracksFuture;
  final AudioService _audio = AudioService();

  Map<String, String?> uploaderAvatars = {};
  bool avatarsLoaded = false;

  /// initState()
  ///
  /// Initializes track loading process.
  ///
  /// Flow:
  /// 1. Call superclass initState
  /// 2. Retrieve all tracks from repository
  @override
  void initState() {
    super.initState();
    _tracksFuture = trackRepository.getAllTracks();
  }

  /// _loadUploaderAvatars()
  ///
  /// Fetches avatar URLs for all unique track uploaders.
  ///
  /// Flow:
  /// 1. Extract unique uploader IDs
  /// 2. Query Supabase profiles table
  /// 3. Store avatar URLs in local map
  /// 4. Refresh UI state
  Future<void> _loadUploaderAvatars(List<Track> tracks) async {
    final uploaderIds = tracks.map((t) => t.userId).toSet().toList();

    final data = await Supabase.instance.client
        .from("profiles")
        .select("id, avatar_url")
        .inFilter("id", uploaderIds);

    for (final row in data) {
      uploaderAvatars[row["id"]] = row["avatar_url"];
    }

    setState(() {});
  }

  /// build()
  ///
  /// Builds the track list UI.
  ///
  /// Responsibilities:
  /// - Display loading state
  /// - Handle empty state
  /// - Render animated track list
  /// - Sync UI with audio playback state
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: FutureBuilder<List<Track>>(
        future: _tracksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryGold,
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No songs available',
                style: AppTextStyles.subtitle,
              ),
            );
          }

          final tracks = snapshot.data!;

          if (!avatarsLoaded) {
            avatarsLoaded = true;
            _loadUploaderAvatars(tracks);
          }

          return AnimatedBuilder(
            animation: _audio,
            builder: (_, __) {
              return ListView.builder(
                padding: const EdgeInsets.only(top: 12, bottom: 100),
                physics: const BouncingScrollPhysics(),
                itemCount: tracks.length,
                itemBuilder: (context, index) {
                  final track = tracks[index];
                  final isPlaying =
                      _audio.currentTrack?.id == track.id &&
                          _audio.isPlaying;

                  return TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 200 + index * 40),
                    tween: Tween(begin: 0, end: 1),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 15 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: _buildTrackItem(
                        track, tracks, index, isPlaying),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  /// _buildTrackItem()
  ///
  /// Builds a single track list item.
  ///
  /// Responsibilities:
  /// - Display track metadata
  /// - Reflect current playback state
  /// - Trigger playback on tap
  /// - Open track options menu
  Widget _buildTrackItem(
      Track track,
      List<Track> tracks,
      int index,
      bool isPlaying) {

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        _audio.playFromList(tracks, index, "library");
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isPlaying ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: isPlaying
              ? Border.all(
                  color: AppColors.primaryGold,
                  width: 1,
                )
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: uploaderAvatars[track.userId] != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        uploaderAvatars[track.userId]!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(
                      Icons.person,
                      color: isPlaying
                          ? AppColors.primaryGold
                          : AppColors.textSecondary,
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: isPlaying
                        ? AppTextStyles.title.copyWith(
                            color: AppColors.primaryGold)
                        : AppTextStyles.title,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    track.artist ?? 'Unknown Artist',
                    style: AppTextStyles.subtitle,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.more_vert,
                color: AppColors.textSecondary,
              ),
              onPressed: () {
                _showTrackOptions(context, track);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// _showTrackOptions()
  ///
  /// Displays bottom sheet with track management options.
  ///
  /// Flow:
  /// 1. Show modal bottom sheet
  /// 2. Provide add-to-playlist option
  /// 3. Provide delete option
  void _showTrackOptions(
      BuildContext context, Track track) {

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(
                  Icons.playlist_add,
                  color: AppColors.primaryGold,
                ),
                title: const Text(
                  'Add to playlist',
                  style: AppTextStyles.subtitle,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showAddToPlaylist(context, track);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  'Delete song',
                  style: AppTextStyles.subtitle,
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await trackRepository.deleteTrack(track);
                  setState(() {
                    _tracksFuture =
                        trackRepository.getAllTracks();
                  });
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  /// _showAddToPlaylist()
  ///
  /// Displays bottom sheet with available playlists.
  ///
  /// Flow:
  /// 1. Fetch all playlists
  /// 2. Display playlist list
  /// 3. Add track to selected playlist
  /// 4. Allow creation of new playlist
  void _showAddToPlaylist(
      BuildContext context, Track track) async {

    final playlists = await playlistRepository.getAllPlaylists();
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              if (playlists.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'You do not have any playlists yet',
                    style: AppTextStyles.subtitle,
                  ),
                ),
              for (final playlist in playlists)
                ListTile(
                  leading: const Icon(
                    Icons.queue_music,
                    color: AppColors.primaryGold),
                  title: Text(
                    playlist.name,
                    style: AppTextStyles.subtitle,
                  ),
                  onTap: () async {
                    await playlistRepository.addTrackToPlaylist(
                      playlistId: playlist.id,
                      track: track,
                    );

                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Added to "${playlist.name}"'),
                      ),
                    );
                  },
                ),
              const Divider(color: AppColors.textSecondary),
              ListTile(
                leading: const Icon(
                  Icons.add,
                  color: AppColors.primaryGold),
                title: const Text(
                  'Create new playlist',
                  style: AppTextStyles.subtitle,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showCreatePlaylistDialog(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  /// _showCreatePlaylistDialog()
  ///
  /// Displays dialog to create a new playlist.
  ///
  /// Flow:
  /// 1. Show dialog with text input
  /// 2. Validate playlist name
  /// 3. Create playlist in repository
  /// 4. Show confirmation message
  void _showCreatePlaylistDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'New playlist',
            style: AppTextStyles.title,
          ),
          content: TextField(
            controller: controller,
            style: const TextStyle(
              color: AppColors.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Playlist name',
              hintStyle: TextStyle(
                color: AppColors.textSecondary),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                    color: AppColors.textSecondary),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                    color: AppColors.primaryGold),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) return;

                await playlistRepository.createPlaylist(name);

                if (!context.mounted) return;
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Playlist created'),
                  ),
                );
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }
}