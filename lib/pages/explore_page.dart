// pages/explore_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/explore_service.dart';
import '../services/audio_service.dart';
import '../models/track.dart';
import '../app_dependencies.dart'; // para trackRepository, playlistRepository

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  late final ExploreService _exploreService;
  final AudioService _audio = AudioService();

  late Future<List<Track>> _tracksFuture;
  String _search = '';
  String _order = 'recent'; // 'recent' | 'title'

  @override
  void initState() {
    super.initState();
    _exploreService = ExploreService(Supabase.instance.client);
    _loadTracks();
  }

  void _loadTracks() {
    setState(() {
      _tracksFuture = _exploreService.getPublicTracks(
        search: _search,
        orderBy: _order == 'recent' ? 'created_at' : 'title',
        descending: _order == 'recent',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchAndFilters(),
        Expanded(
          child: FutureBuilder<List<Track>>(
            future: _tracksFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No hay canciones públicas'));
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
                        leading: const Icon(Icons.music_note),
                        title: Text(track.title),
                        subtitle: Text(track.artist ?? 'Unknown Artist'),
                        onTap: () {
                          // Streaming con caché (igual que SongListPage)
                          _audio.playFromList(tracks, index, 'explore');
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () {
                            _showTrackOptions(context, track);
                          },
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar por título o artista',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _search = value;
                _loadTracks();
              },
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _order,
            items: const [
              DropdownMenuItem(
                value: 'recent',
                child: Text('Recientes'),
              ),
              DropdownMenuItem(
                value: 'title',
                child: Text('Título A-Z'),
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

  void _showTrackOptions(BuildContext context, Track track) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Descargar a mis canciones'),
                onTap: () async {
                  Navigator.pop(context);

                  // Guardar en SQLite (metadatos) y sincronizar
                  await trackRepository.insertTrack(track);

                  // Opcional: precachear audio
                  // await AudioCacheManager.manager.getSingleFile(track.audioUrl);

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Canción descargada'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.playlist_add),
                title: const Text('Añadir a lista'),
                onTap: () async {
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
                        content: Text('Añadido a "${playlist.name}"'),
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
