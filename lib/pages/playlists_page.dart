import 'package:flutter/material.dart';
import '../app_dependencies.dart';
import '../models/playlist.dart';
import 'playlist_detail_page.dart';

class PlaylistsPage extends StatefulWidget {
  const PlaylistsPage({super.key});

  @override
  State<PlaylistsPage> createState() => _PlaylistsPageState();
}

class _PlaylistsPageState extends State<PlaylistsPage> {
  late Future<List<Playlist>> _playlistsFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _playlistsFuture = playlistRepository.getAllPlaylists();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Playlist>>(
        future: _playlistsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No tienes listas todavía'));
          }

          final playlists = snapshot.data!;

          return ListView.builder(
            itemCount: playlists.length,
            itemBuilder: (_, index) {
              final playlist = playlists[index];

              return ListTile(
                leading: const Icon(Icons.queue_music),
                title: Text(playlist.name),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PlaylistDetailPage(playlist: playlist),
                    ),
                  );
                  setState(_load);
                },
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: _createPlaylist,
      ),
    );
  }

  void _createPlaylist() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Nueva lista'),
          content: TextField(
            controller: controller,
            decoration:
                const InputDecoration(hintText: 'Nombre de la lista'),
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
                setState(_load);
              },
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );
  }
}
