import "dart:typed_data";

class NowPlaying {
  final String title;
  final String artist;
  final String album;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final Uint8List? artwork;

  const NowPlaying({
    required this.title,
    required this.artist,
    required this.album,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.artwork,
  });

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