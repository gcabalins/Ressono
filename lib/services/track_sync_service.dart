import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/track.dart';

/// Handles remote synchronization of tracks with Supabase.
///
/// This service performs best-effort operations:
/// - Insert or update tracks
/// - Delete tracks and related storage files
///
/// Errors are intentionally suppressed to avoid
/// interrupting local application flow.
class TrackSyncService {
  final SupabaseClient _supabase;

  /// Creates a TrackSyncService instance.
  TrackSyncService(this._supabase);

  /// Inserts or updates a track in the remote database.
  ///
  /// Uses upsert with conflict resolution on `id`.
  /// Operation is skipped if no authenticated user exists.
  Future<void> syncInsert(Track track) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase.from('tracks').upsert(
        {
          'id': track.id,
          'user_id': user.id,
          'title': track.title,
          'artist': track.artist,
          'audio_url': track.audioUrl,
          'duration_seconds': track.durationSeconds,
        },
        onConflict: 'id',
      );
    } catch (_) {
      // Best-effort strategy: errors are ignored.
    }
  }

  /// Deletes a track remotely.
  ///
  /// Steps:
  /// 1. Remove playlist relations
  /// 2. Delete track record
  /// 3. Remove associated file from Supabase Storage
  ///
  /// All operations follow a best-effort strategy.
  Future<void> syncDelete(String trackId, String audioUrl) async {
    try {
      // Remove playlist relations.
      await _supabase
          .from('playlist_tracks')
          .delete()
          .eq('track_id', trackId);

      // Delete track record.
      await _supabase
          .from('tracks')
          .delete()
          .eq('id', trackId);

      // Remove file from storage bucket.
      try {
        final uri = Uri.parse(audioUrl);
        final path = uri.pathSegments.skip(1).join('/');
        await _supabase.storage.from('audio').remove([path]);
      } catch (_) {
        // Storage deletion ignored.
      }
    } catch (_) {
      // Best-effort strategy: errors are ignored.
    }
  }
}