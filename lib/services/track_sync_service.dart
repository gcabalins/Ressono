import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/track.dart';

class TrackSyncService {
  final SupabaseClient _supabase;

  TrackSyncService(this._supabase);

  /// ⬆️ Insert / Update remoto (best effort)
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
      // silencio absoluto (best effort)
    }
  }

  /// 🗑 Delete remoto (best effort)
  Future<void> syncDelete(String trackId, String audioUrl) async {
    try {
      // 1️⃣ borrar referencias
      await _supabase
          .from('playlist_tracks')
          .delete()
          .eq('track_id', trackId);

      // 2️⃣ borrar track
      await _supabase
          .from('tracks')
          .delete()
          .eq('id', trackId);

      // 3️⃣ borrar archivo de storage
      try {
        final uri = Uri.parse(audioUrl);
        final path = uri.pathSegments.skip(1).join('/');
        await _supabase.storage.from('audio').remove([path]);
      } catch (_) {}
    } catch (_) {
      // silencio absoluto
    }
  }
}