import 'package:flutter/material.dart';
import '../app_dependencies.dart';
import '../models/playlist.dart';
import 'playlist_detail_page.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

/// PlaylistsPage
///
/// Displays all user playlists.
///
/// Responsibilities:
/// - Load playlists from repository
/// - Navigate to playlist details
/// - Create new playlists
/// - Delete playlists with confirmation
class PlaylistsPage extends StatefulWidget {
  const PlaylistsPage({super.key});

  @override
  State<PlaylistsPage> createState() => _PlaylistsPageState();
}

/// _PlaylistsPageState
///
/// Manages playlist loading, UI state,
/// animations, and user interactions.
class _PlaylistsPageState extends State<PlaylistsPage> {
  late Future<List<Playlist>> _playlistsFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Loads all playlists from the repository.
  void _load() {
    _playlistsFuture = playlistRepository.getAllPlaylists();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryGold,
        onPressed: _createPlaylist,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: FutureBuilder<List<Playlist>>(
        future: _playlistsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGold),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'You don’t have any playlists yet',
                style: AppTextStyles.subtitle,
              ),
            );
          }

          final playlists = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.only(top: 20, bottom: 100),
            physics: const BouncingScrollPhysics(),
            itemCount: playlists.length,
            itemBuilder: (_, index) {
              final playlist = playlists[index];

              return TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 200 + index * 50),
                tween: Tween(begin: 0, end: 1),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: _buildPlaylistItem(playlist),
              );
            },
          );
        },
      ),
    );
  }

  /// Builds a single playlist item widget.
  ///
  /// Includes:
  /// - Tap navigation to details
  /// - Swipe-to-delete gesture
  /// - Animated appearance
  Widget _buildPlaylistItem(Playlist playlist) {
    return Dismissible(
      key: ValueKey(playlist.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) async {
        return await _confirmDelete(playlist);
      },
      onDismissed: (_) async {
        await playlistRepository.deletePlaylist(playlist.id);
        setState(_load);
      },
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PlaylistDetailPage(playlist: playlist),
            ),
          );
          setState(_load);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryGold, Colors.amber],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.queue_music, color: Colors.black),
              ),
              const SizedBox(width: 16),
              Expanded(child: Text(playlist.name, style: AppTextStyles.title)),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Opens dialog to create a new playlist.
  ///
  /// Validates input and refreshes list after creation.
  void _createPlaylist() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('New Playlist'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Playlist name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) return;

                await playlistRepository.createPlaylist(name);

                Navigator.pop(context);
                setState(_load);
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  /// Shows confirmation dialog before deleting a playlist.
  ///
  /// Returns true if user confirms deletion.
  Future<bool> _confirmDelete(Playlist playlist) async {
    return await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete Playlist'),
            content: Text(
              'Are you sure you want to delete "${playlist.name}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }
}
