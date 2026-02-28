import 'package:flutter/material.dart';
import 'song_list_page.dart';
import 'upload_track_page.dart';
import 'profile_page.dart';
import '../services/audio_service.dart';
import '../models/track.dart';
import 'playlists_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'explore_page.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

/// HomePage
///
/// Main application container after authentication.
///
/// Responsibilities:
/// - Bottom navigation management
/// - Page switching
/// - Mini player visibility
/// - User avatar display
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final AudioService _audio = AudioService();
  final supabase = Supabase.instance.client;

  late final List<Widget> _pages;
  late final List<String> _titles;

  /// Stores the current user's avatar URL.
  String? avatarUrl;

  @override
  void initState() {
    super.initState();

    _loadAvatar();

    // Application main sections.
    _pages = const [
      SongListPage(),
      ExplorePage(),
      PlaylistsPage(),
      UploadTrackPage(),
      ProfilePage(),
    ];

    // Titles displayed in the top bar.
    _titles = const [
      'Songs',
      'Explore',
      'Playlists',
      'Upload',
      'Profile',
    ];
  }

  /// Loads the authenticated user's avatar from Supabase.
  Future<void> _loadAvatar() async {
    final userId = supabase.auth.currentUser!.id;

    final data = await supabase
        .from('profiles')
        .select('avatar_url')
        .eq('id', userId)
        .maybeSingle();

    setState(() {
      avatarUrl = data?['avatar_url'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      /// Custom top bar with gradient background.
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: Container(
          padding: const EdgeInsets.only(
            top: 50,
            left: 20,
            right: 20,
            bottom: 10,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.background,
                AppColors.surface,
              ],
            ),
          ),
          child: Row(
            children: [
              /// Dynamic page title.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _titles[_selectedIndex],
                      style: AppTextStyles.title,
                    ),
                  ],
                ),
              ),

              /// User avatar (navigates to profile tab).
              GestureDetector(
                onTap: () {
                  setState(() => _selectedIndex = 4);
                },
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primaryGold,
                  backgroundImage:
                      avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                  child: avatarUrl == null
                      ? Text(
                          supabase.auth.currentUser?.email
                                  ?.substring(0, 1)
                                  .toUpperCase() ??
                              "U",
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),

      body: _pages[_selectedIndex],

      /// Bottom section containing mini player and navigation bar.
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _audio,
            builder: (_, __) {
              // Hide mini player on profile page.
              if (_selectedIndex == 4) {
                return const SizedBox.shrink();
              }

              if (_audio.currentTrack == null) {
                _audio.stopOnProfile();
                return const SizedBox.shrink();
              }

              return _MiniPlayer();
            },
          ),
          _buildNavigationBar(),
        ],
      ),
    );
  }

  /// Builds the bottom navigation bar.
  Widget _buildNavigationBar() {
    return NavigationBar(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primaryGold,
      selectedIndex: _selectedIndex,
      onDestinationSelected: (i) {
        setState(() => _selectedIndex = i);
      },
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.library_music),
          label: 'Songs',
        ),
        NavigationDestination(
          icon: Icon(Icons.language_sharp),
          label: 'Explore',
        ),
        NavigationDestination(
          icon: Icon(Icons.format_list_bulleted_add),
          label: 'Playlists',
        ),
        NavigationDestination(
          icon: Icon(Icons.add_circle),
          label: 'Upload',
        ),
        NavigationDestination(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}

/// MiniPlayer
///
/// Displays currently playing track information
/// and playback controls.
class _MiniPlayer extends StatelessWidget {
  const _MiniPlayer();

  @override
  Widget build(BuildContext context) {
    final audio = AudioService();
    final Track track = audio.currentTrack!;
    final player = audio.player;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.music_note,
                color: AppColors.primaryGold,
              ),
              const SizedBox(width: 10),

              /// Track information.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.subtitle
                          .copyWith(color: AppColors.textPrimary),
                    ),
                    Text(
                      track.artist ?? 'Unknown Artist',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.subtitle,
                    ),
                  ],
                ),
              ),

              /// Playback controls.
              IconButton(
                icon: const Icon(Icons.skip_previous),
                color: AppColors.textPrimary,
                onPressed: audio.playPrevious,
              ),
              IconButton(
                icon: Icon(
                  audio.isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill,
                  size: 34,
                  color: AppColors.primaryGold,
                ),
                onPressed: audio.togglePlayPause,
              ),
              IconButton(
                icon: const Icon(Icons.skip_next),
                color: AppColors.textPrimary,
                onPressed: audio.playNext,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: audio.stopAndClear,
              ),
            ],
          ),

          /// Playback progress slider.
          StreamBuilder<Duration>(
            stream: player.positionStream,
            builder: (_, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              final duration = player.duration ?? Duration.zero;

              final max = duration.inMilliseconds.toDouble();
              final value =
                  position.inMilliseconds.clamp(0, max).toDouble();

              return Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.primaryGold,
                      inactiveTrackColor: AppColors.textSecondary,
                      thumbColor: AppColors.primaryGold,
                      overlayColor:
                          AppColors.primaryGold.withOpacity(0.2),
                      trackHeight: 2,
                    ),
                    child: Slider(
                      min: 0,
                      max: max > 0 ? max : 1,
                      value: value,
                      onChanged: (v) {
                        player.seek(
                          Duration(milliseconds: v.toInt()),
                        );
                      },
                    ),
                  ),

                  /// Time indicators.
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _format(position),
                          style: AppTextStyles.subtitle
                              .copyWith(fontSize: 11),
                        ),
                        Text(
                          _format(duration),
                          style: AppTextStyles.subtitle
                              .copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          )
        ],
      ),
    );
  }

  /// Formats a Duration into mm:ss.
  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}