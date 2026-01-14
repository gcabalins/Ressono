import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/audio_service.dart';

class SongListPage extends StatefulWidget {
  const SongListPage({super.key});

  @override
  State<SongListPage> createState() => _SongListPageState();
}

class _SongListPageState extends State<SongListPage> {
  late Future<List<Map<String, dynamic>>> _tracksFuture;

  @override
  void initState() {
    super.initState();
    _tracksFuture = fetchTracks();
  }

  String _formatDuration(int? seconds) {
    if (seconds == null) return '--:--';
    final d = Duration(seconds: seconds);
    return '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:'
        '${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final audio = AudioService();

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _tracksFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final songs = snapshot.data!;

        return AnimatedBuilder(
          animation: audio,
          builder: (_, __) {
            return ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: songs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final song = songs[index];
                final isCurrent =
                    audio.currentTrack?['id'] == song['id'];

                return ListTile(
                  selected: isCurrent,
                  title: Text(song['title']),
                  subtitle: Text(song['artist'] ?? 'Desconocido'),
                  trailing: IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () {
                        _showTrackOptions(context, song);
                      },
                    ),
                  onTap: () {
                    audio.playFromList(songs, index, sourceLabel: 'Canciones');
                  },
                );
              },
            );
          },
        );
      },
    );
  }
  void _showTrackOptions(
    BuildContext context,
    Map<String, dynamic> track,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.playlist_add),
                title: const Text('Añadir a lista'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddToPlaylistModal(context, track);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Eliminar cancion'),
                onTap: () async {
                  Navigator.pop(context);
                  await deleteTrack(track['id']);
                  setState(() {
                    _tracksFuture = fetchTracks();
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }
  void _showAddToPlaylistModal(
    BuildContext context,
    Map<String, dynamic> track,
  ) async {
    final playlists = await fetchPlaylists();

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (playlists.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No tienes listas todavía'),
                ),

              for (final playlist in playlists)
                ListTile(
                  leading: const Icon(Icons.queue_music),
                  title: Text(playlist['name']),
                  onTap: () async {
                    await addTrackToPlaylist(
                      playlistId: playlist['id'],
                      trackId: track['id'],
                    );

                    if (!context.mounted) return;
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Añadido a "${playlist['name']}"',
                        ),
                      ),
                    );
                  },
                ),

              const Divider(),

              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Crear nueva lista'),
                onTap: () {
                  Navigator.pop(context);
                  _showCreatePlaylistDialog(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
  void _showCreatePlaylistDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Nueva lista'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Nombre de la lista',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) return;

                await createPlaylist(name);

                if (!context.mounted) return;
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lista creada')),
                );
              },
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );
  }



}