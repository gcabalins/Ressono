/// Represents a playlist entity in the application.
///
/// This model maps directly to the `playlists` table
/// in the local database.
class Playlist {
  final String id;
  final String name;
  final DateTime createdAt;

  /// Creates a Playlist instance.
  Playlist({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  /// Creates a Playlist instance from a database map.
  factory Playlist.fromMap(Map<String, dynamic> map) {
    return Playlist(
      id: map['id'],
      name: map['name'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  /// Converts the Playlist instance into a database map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }
}