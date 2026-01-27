import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../models/track.dart';
import '../app_dependencies.dart';
import '../services/audio_service.dart';

class PlaylistDetailPage extends StatefulWidget {
  final Playlist playlist;

  const PlaylistDetailPage({
    super.key,
    required this.playlist,
  });

  @override
  State<PlaylistDetailPage> createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends State<PlaylistDetailPage> {
  late Future<List<Track>> _tracksFuture;
  final AudioService _audio = AudioService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _tracksFuture =
        playlistRepository.getTracksForPlaylist(widget.playlist.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playlist.name),
      ),
      body: FutureBuilder<List<Track>>(
        future: _tracksFuture,
        builder: (_, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Lista vacía'));
          }

          final tracks = snapshot.data!;

          return AnimatedBuilder(
            animation: _audio,
            builder: (_, __) {
              return ListView.builder(
                itemCount: tracks.length,
                itemBuilder: (_, index) {
                  final track = tracks[index];

                  return ListTile(
                    title: Text(track.title),
                    subtitle:
                        Text(track.artist ?? 'Unknown Artist'),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () async {
                        await playlistRepository.removeTrackFromPlaylist(
                          playlistId: widget.playlist.id,
                          track: track,
                        );
                        setState(_load);
                      },
                    ),
                    onTap: () {
                      _audio.playFromList(
                        tracks,
                        index,
                        widget.playlist.name,
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
