import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/explore_service.dart';
import '../services/audio_service.dart';
import '../models/track.dart';
import '../app_dependencies.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

/// ExplorePage
///
/// Displays publicly available tracks retrieved from Supabase.
/// 
/// Features:
/// - Search functionality
/// - Sorting options
/// - Animated track list
/// - Playback integration
/// - Add to playlist / download actions
class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage>
    with SingleTickerProviderStateMixin {

  late final ExploreService _exploreService;
  final AudioService _audio = AudioService();

  late Future<List<Track>> _tracksFuture;

  String _search = '';
  String _order = 'recent';

  late final AnimationController _waveController;

  /// Stores uploader avatar URLs indexed by user ID.
  Map<String, String?> uploaderAvatars = {};

  /// Ensures avatars are loaded only once per fetch cycle.
  bool avatarsLoaded = false;

  @override
  void initState() {
    super.initState();

    // Animation controller used for the playing indicator.
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _exploreService = ExploreService(Supabase.instance.client);

    _loadTracks();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  /// Fetches public tracks from the remote service
  /// based on current search and sorting configuration.
  void _loadTracks() {
    _tracksFuture = _exploreService.getPublicTracks(
      search: _search,
      orderBy: _order == 'recent' ? 'created_at' : 'title',
      descending: _order == 'recent',
    );

    setState(() {});
  }

  /// Loads avatar URLs for all unique uploaders in the track list.
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(
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
                      'No public tracks available',
                      style: AppTextStyles.subtitle,
                    ),
                  );
                }

                final tracks = snapshot.data!;

                if (!avatarsLoaded) {
                  avatarsLoaded = true;
                  _loadUploaderAvatars(tracks);
                }

                return _buildTrackList(tracks);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the animated track list.
  Widget _buildTrackList(List<Track> tracks) {
    return AnimatedBuilder(
      animation: _audio,
      builder: (_, __) {
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: tracks.length,
          itemBuilder: (context, index) {
            final track = tracks[index];
            final isPlaying = _audio.currentTrack?.id == track.id;

            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 250 + index * 30),
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
              child: _buildTrackItem(track, tracks, index, isPlaying),
            );
          },
        );
      },
    );
  }

  /// Builds a single track list item.
  Widget _buildTrackItem(
      Track track, List<Track> tracks, int index, bool isPlaying) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _audio.playFromList(tracks, index, 'explore'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isPlaying ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isPlaying
              ? Border.all(color: AppColors.primaryGold, width: 1)
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
                        ? AppTextStyles.title
                            .copyWith(color: AppColors.primaryGold)
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
              icon: const Icon(Icons.more_vert,
                  color: AppColors.textSecondary),
              onPressed: () => _showTrackOptions(context, track),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the search bar and sorting dropdown.
  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle:
                    const TextStyle(color: AppColors.textSecondary),
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                _search = value;
                _loadTracks();
              },
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<String>(
            dropdownColor: AppColors.surface,
            value: _order,
            style: const TextStyle(color: AppColors.textPrimary),
            items: const [
              DropdownMenuItem(
                value: 'recent',
                child: Text('Recent'),
              ),
              DropdownMenuItem(
                value: 'title',
                child: Text('Title A–Z'),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              _order = value;
              _loadTracks();
            },
          ),
        ],
      ),
    );
  }

  /// Displays available actions for a selected track.
  void _showTrackOptions(BuildContext context, Track track) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading:
                    const Icon(Icons.download, color: AppColors.primaryGold),
                title: const Text('Download'),
                onTap: () async {
                  Navigator.pop(context);
                  await trackRepository.insertTrack(track);

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Track downloaded')),
                  );
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.playlist_add, color: AppColors.primaryGold),
                title: const Text('Add to Playlist'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddToPlaylist(context, track);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Displays playlist selection modal.
  void _showAddToPlaylist(BuildContext context, Track track) async {
    final playlists = await playlistRepository.getAllPlaylists();
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (playlists.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('You do not have any playlists yet'),
                ),
              for (final playlist in playlists)
                ListTile(
                  title: Text(playlist.name),
                  onTap: () async {
                    await playlistRepository.addTrackToPlaylist(
                      playlistId: playlist.id,
                      track: track,
                    );
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('Added to "${playlist.name}"'),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}