import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../models/track.dart';
import '../app_dependencies.dart';
import '../services/audio_service.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
/// PlaylistDetailPage
///
/// Displays the details of a selected playlist,
/// including its tracks and playback interaction.
///
/// Responsibilities:
/// - Load playlist tracks
/// - Display track list
/// - Handle track playback
/// - Allow track removal from playlist
class PlaylistDetailPage extends StatefulWidget {
  final Playlist playlist;

  const PlaylistDetailPage({
    super.key,
    required this.playlist,
  });

  @override
  State<PlaylistDetailPage> createState() => _PlaylistDetailPageState();
}
/// _PlaylistDetailPageState
///
/// Handles track loading, UI state,
/// and audio playback interactions.
class _PlaylistDetailPageState extends State<PlaylistDetailPage> {
  late Future<List<Track>> _tracksFuture;
  final AudioService _audio = AudioService();

  @override
  void initState() {
    super.initState();
    _load();
  }
  /// Loads all tracks associated with the current playlist.
  void _load() {
    _tracksFuture =
        playlistRepository.getTracksForPlaylist(widget.playlist.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<List<Track>>(
        future: _tracksFuture,
        builder: (_, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryGold,
              ),
            );
          }

          final tracks = snapshot.data ?? [];

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [

              /// Expanded Playlist Header
              ///
              /// Displays playlist name and decorative background.
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                backgroundColor: AppColors.background,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(
                    widget.playlist.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryGold,
                          AppColors.background,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.queue_music,
                        size: 80,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),

              /// Track List Section
              ///
              /// Shows playlist tracks or empty state message.
              if (tracks.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'Playlist is empty',
                      style: AppTextStyles.subtitle,
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final track = tracks[index];
                      final isPlaying =
                          _audio.currentTrack?.id == track.id &&
                          _audio.isPlaying;

                      return _buildTrackItem(
                        track,
                        tracks,
                        index,
                        isPlaying,
                      );
                    },
                    childCount: tracks.length,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
  /// Builds a single track item widget.
  ///
  /// Highlights currently playing track
  /// and handles playback on tap.
  Widget _buildTrackItem(
    Track track,
    List<Track> tracks,
    int index,
    bool isPlaying,
  ) {
    return InkWell(
      onTap: () {
        _audio.playFromList(
          tracks,
          index,
          widget.playlist.name,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isPlaying
              ? AppColors.surface
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Text(
              "${index + 1}",
              style: AppTextStyles.subtitle,
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    style: isPlaying
                        ? AppTextStyles.title.copyWith(
                            color: AppColors.primaryGold,
                          )
                        : AppTextStyles.title,
                  ),
                  Text(
                    track.artist ?? "Unknown Artist",
                    style: AppTextStyles.subtitle,
                  ),
                ],
              ),
            ),

            IconButton(
              icon: const Icon(
                Icons.close,
                color: Colors.redAccent,
              ),
              onPressed: () async {
                await playlistRepository.removeTrackFromPlaylist(
                  playlistId: widget.playlist.id,
                  track: track,
                );
                setState(_load);
              },
            ),
          ],
        ),
      ),
    );
  }
}
