import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/audio_service.dart';

class PlaylistDetailPage extends StatefulWidget {
  final String playlistId;
  final String playlistName;

  const PlaylistDetailPage({
    super.key,
    required this.playlistId,
    required this.playlistName,
  });

  @override
  State<PlaylistDetailPage> createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends State<PlaylistDetailPage> {
  late Future<List<Map<String, dynamic>>> _tracksFuture;

  @override
  void initState() {
    super.initState();
    _tracksFuture = fetchTracksFromPlaylist(widget.playlistId);
    
  }

  String _formatDuration(int seconds) {
    final d = Duration(seconds: seconds);
    return '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:'
        '${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final audio = AudioService();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playlistName),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            tooltip: 'Reproducir lista',
            onPressed: () async {
              final tracks = await fetchTracksFromPlaylist(widget.playlistId);
              if (tracks.isEmpty) return;

              audio.playFromList(
                tracks,
                0,
                sourceLabel: 'Lista: ${widget.playlistName}',
              );

            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _tracksFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final tracks = snapshot.data!;

          if (tracks.isEmpty) {
            return const Center(
              child: Text('Esta lista está vacía'),
            );
          }

          return AnimatedBuilder(
            animation: audio,
            builder: (_, __) {
              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: tracks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final track = tracks[index];
                  final isCurrent =
                      audio.currentTrack?['id'] == track['id'];

                  return ListTile(
                    selected: isCurrent,
                    leading: Text('${index + 1}'),
                    title: Text(
                      track['title'],
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(track['artist'] ?? 'Desconocido'),
                    trailing: Text(
                      _formatDuration(track['duration_seconds']),
                      style: const TextStyle(
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    onTap: () {
                      audio.playFromList(
                        tracks,
                        index,
                        sourceLabel: 'Lista: ${widget.playlistName}',
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
