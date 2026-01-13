import 'package:flutter/material.dart';
import '../services/audio_controller.dart';
import 'playlist_detail_page.dart';

class PlaylistsPage extends StatefulWidget {
  const PlaylistsPage({super.key});

  @override
  State<PlaylistsPage> createState() => _PlaylistsPageState();
}

class _PlaylistsPageState extends State<PlaylistsPage> {
  late Future<List<Map<String, dynamic>>> _playlistsFuture;

  @override
  void initState() {
    super.initState();
    _playlistsFuture = fetchPlaylists();
  }

  Future<void> _reload() async {
    setState(() {
      _playlistsFuture = fetchPlaylists();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _reload,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _playlistsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return ListView(
              children: [
                SizedBox(height: 200),
                Center(child: CircularProgressIndicator()),
              ],
            );
          }

          final playlists = snapshot.data!;

          if (playlists.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 120),
                Center(
                  child: Text(
                    'No tienes listas todavía',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: playlists.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final playlist = playlists[index];

              return ListTile(
                leading: const Icon(Icons.queue_music),
                title: Text(
                  playlist['name'],
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Lista de reproducción'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlaylistDetailPage(
                        playlistId: playlist['id'],
                        playlistName: playlist['name'],
                      ),
                    ),
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
