import "dart:typed_data";

class NowPlaying {
  final String title;
  final String artist;
  final String album;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final Uint8List? artwork;

  /// When [position] was read. Snapshots can be reused long after they were
  /// taken (e.g. returning to the player mid-track), so the live position
  /// must be extrapolated from here, not from when the widget got it.
  final DateTime capturedAt;

  NowPlaying({
    required this.title,
    required this.artist,
    required this.album,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.artwork,
    DateTime? capturedAt,
  }) : capturedAt = capturedAt ?? DateTime.now();

  /// Position right now, assuming playback continued since [capturedAt].
  Duration get livePosition {
    if (!isPlaying) return position;
    final p = position + DateTime.now().difference(capturedAt);
    return duration > Duration.zero && p > duration ? duration : p;
  }

  factory NowPlaying.fromMap(Map<String, dynamic> map) {
    return NowPlaying(
      title: (map['title'] as String?) ?? '',
      artist: (map['artist'] as String?) ?? '',
      album: (map['album'] as String?) ?? '',
      isPlaying: (map['isPlaying'] as bool?) ?? false,
      position: Duration(milliseconds: (map['positionMs'] as int?) ?? 0),
      duration: Duration(milliseconds: (map['durationMs'] as int?) ?? 0),
      artwork: map['thumbnail'] as Uint8List?,
    );
  }
}