class Track {
  final String id;
  final String title;
  final String? artist;
  final String audioUrl;
  final int durationSeconds;

  const Track({
    required this.id,
    required this.title,
    this.artist,
    required this.audioUrl,
    required this.durationSeconds,
  });

  /// SQLite / Supabase → Model
  factory Track.fromMap(Map<String, dynamic> map) {
    return Track(
      id: map['id'] as String,
      title: map['title'] as String,
      artist: map['artist'] as String?,
      audioUrl: map['audio_url'] as String,
      durationSeconds: map['duration_seconds'] as int,
    );
  }

  /// Model → SQLite / Supabase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'audio_url': audioUrl,
      'duration_seconds': durationSeconds,
    };
  }

  /// Copia inmutable (útil para sync)
  Track copyWith({
    String? id,
    String? title,
    String? artist,
    String? audioUrl,
    int? durationSeconds,
  }) {
    return Track(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      audioUrl: audioUrl ?? this.audioUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
    );
  }
}
