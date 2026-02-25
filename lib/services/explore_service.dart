import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/track.dart';

/// Service responsible for fetching public tracks
/// from the remote Supabase database.
class ExploreService {
  final SupabaseClient _client;

  ExploreService(this._client);

  /// Retrieves public tracks with optional search and sorting.
  ///
  /// Parameters:
  /// - search: filters by title or artist
  /// - orderBy: column used for sorting
  /// - descending: sorting direction
  Future<List<Track>> getPublicTracks({
    String? search,
    String orderBy = 'created_at',
    bool descending = true,
  }) async {
    dynamic query = _client
        .from('tracks')
        .select()
        .eq('is_public', true);

    if (search != null && search.trim().isNotEmpty) {
      final q = '%${search.trim()}%';
      query = query.or('title.ilike.$q,artist.ilike.$q');
    }

    query = query.order(orderBy, ascending: !descending);

    final data = await query;

    return (data as List)
        .map((row) => Track.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  /// Retrieves the most recently created public tracks.
  Future<List<Track>> getRecentTracks() {
    return getPublicTracks(orderBy: 'created_at', descending: true);
  }
}