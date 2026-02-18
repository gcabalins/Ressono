// services/explore_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/track.dart';

class ExploreService {
  final SupabaseClient _client;

  ExploreService(this._client);

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

  Future<List<Track>> getRecentTracks() {
    return getPublicTracks(orderBy: 'created_at', descending: true);
  }

  // Si más adelante tienes una métrica de popularidad, puedes añadir:
  // Future<List<Track>> getPopularTracks() { ... }
}
