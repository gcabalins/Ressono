import 'package:flutter/material.dart';
import 'song_list.dart';
import 'upload_track_page.dart';
import '../services/audio_service.dart';
import 'playlists_page.dart';
import 'profile_page.dart';



class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    final audio = AudioService();

    final pages = [
      const SongListPage(),
      const PlaylistsPage(),
      const UploadTrackPage(),
      const ProfilePage(),
    ];

    final titles = ['Canciones', 'Listas', 'Agregar', 'Perfil'];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_selectedIndex]),
        centerTitle: true,
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: audio,
            builder: (_, __) {
              if (audio.currentTrack == null) return const SizedBox();
              return _MiniPlayer();
            },
          ),
          NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) {
              setState(() => _selectedIndex = i);
            },
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.library_music), label: 'Canciones'),
              NavigationDestination(
                  icon: Icon(Icons.queue_music), label: 'Listas'),
              NavigationDestination(
                  icon: Icon(Icons.add_circle), label: 'Agregar'),
              NavigationDestination(
                  icon: Icon(Icons.person), label: 'Perfil'),
            ],
          ),
        ],
      ),
    );
  }
}

/// ===============================
/// MINI PLAYER
/// ===============================

class _MiniPlayer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final audio = AudioService();
    final track = audio.currentTrack!;
    final player = audio.player;


    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.black12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // INFO + CONTROLES
          Row(
            children: [
              const Icon(Icons.music_note),
              const SizedBox(width: 8),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track['title'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      track['artist'] ?? 'Artista desconocido',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (audio.sourceLabel  != null)
                      Text(
                        audio.sourceLabel!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
              ),

              IconButton(
                icon: const Icon(Icons.skip_previous),
                onPressed: audio.playPrevious,
              ),

              IconButton(
                icon: Icon(
                  audio.isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill,
                  size: 32,
                ),
                onPressed: audio.togglePlayPause,
              ),

              IconButton(
                icon: const Icon(Icons.skip_next),
                onPressed: audio.playNext,
              ),

              IconButton(
                icon: const Icon(Icons.close),
                onPressed: audio.stopAndClear,
              ),
            ],
          ),

          // 🔥 SEEK BAR
          StreamBuilder<Duration>(
            stream: player.positionStream,
            builder: (_, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              final duration = player.duration ?? Duration.zero;

              final max = duration.inMilliseconds.toDouble();
              final value = position.inMilliseconds
                  .clamp(0, max)
                  .toDouble();

              return Column(
                children: [
                  Slider(
                    min: 0,
                    max: max > 0 ? max : 1,
                    value: value,
                    onChanged: (v) {
                      player.seek(
                        Duration(milliseconds: v.toInt()),
                      );
                    },
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _format(position),
                          style: const TextStyle(fontSize: 11),
                        ),
                        Text(
                          _format(duration),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _format(Duration d) {
    final m =
        d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s =
        d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
