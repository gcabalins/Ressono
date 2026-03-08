/// Represents a track entity in the application.
///
/// This model maps directly to the `tracks` table
/// in the local database and may also be used for
/// remote data synchronization.
class Track {
  final String id;
  final String userId;
  final String title;
  final String? artist;
  final String audioUrl;
  final int durationSeconds;
  final DateTime createdAt;

  /// Creates a Track instance.
  const Track({
    required this.id,
    required this.userId,
    required this.title,
    this.artist,
    required this.audioUrl,
    required this.durationSeconds,
    required this.createdAt,

  });

  /// Creates a Track instance from a database or API map.
  factory Track.fromMap(Map<String, dynamic> map) {
    return Track(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      artist: map['artist'] as String?,
      audioUrl: map['audio_url'] as String,
      durationSeconds: map['duration_seconds'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Converts the Track instance into a database or API map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'artist': artist,
      'audio_url': audioUrl,
      'duration_seconds': durationSeconds,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  /// Returns a modified copy of the current Track instance.
  ///
  /// Useful for immutable updates.
  Track copyWith({
    String? id,
    String? userId,
    String? title,
    String? artist,
    String? audioUrl,
    int? durationSeconds,
    DateTime? createdAt,
  }) {
    return Track(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      audioUrl: audioUrl ?? this.audioUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}