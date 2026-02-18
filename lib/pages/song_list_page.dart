import 'package:flutter/material.dart';
import '../app_dependencies.dart';
import '../services/audio_service.dart';
import '../models/track.dart';

class SongListPage extends StatefulWidget {
  const SongListPage({super.key});

  @override
  State<SongListPage> createState() => _SongListPageState();
}

class _SongListPageState extends State<SongListPage> {
  late Future<List<Track>> _tracksFuture;
  final AudioService _audio = AudioService();

  @override
  void initState() {

    super.initState();
    _tracksFuture = trackRepository.getAllTracks();
  }
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Track>>(
      future: _tracksFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No hay canciones'));
        }

        final tracks = snapshot.data!;

        return AnimatedBuilder(
          animation: _audio,
          builder: (_, __) {
            return ListView.builder(
              itemCount: tracks.length,
              
              itemBuilder: (context, index) {
                final track = tracks[index];
                return ListTile(
                  title: Text(track.title),
                  subtitle: Text(track.artist ?? 'Unknown Artist'),
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      _showTrackOptions(context, track);
                    },
                  ),
                  onTap: () {
                    _audio.playFromList(tracks, index, "");
                  },
                );
              },
            );
          },
        );
      },
    );
  }
 void _showTrackOptions(BuildContext context, Track track) {
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
                _showAddToPlaylist(context, track);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Eliminar canción'),
              onTap: () async {
                Navigator.pop(context);
                await trackRepository.deleteTrack(track);
                setState(() {
                  _tracksFuture = trackRepository.getAllTracks();
                });
              },
            ),
          ],
        ),
      );
    },
  );
}

void _showAddToPlaylist(BuildContext context, Track track) async {
  final playlists = await playlistRepository.getAllPlaylists();
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
                title: Text(playlist.name),
                onTap: () async {
                  await playlistRepository.addTrackToPlaylist(
                    playlistId: playlist.id, 
                    track: track,
                  );

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Añadido a "${playlist.name}"',
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

              await playlistRepository.createPlaylist(name);

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
