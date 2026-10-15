enum MusicSource { spotify, youtube, appleMusic, deezer}

extension MusicSourceLabel on MusicSource {
  String get label => switch(this) {
      MusicSource.spotify => 'Spotify',
      MusicSource.youtube => 'YouTube Music',
      MusicSource.appleMusic => 'Apple Music',
      MusicSource.deezer => 'Deezer',
  };
}

class PlaylistTrack {
  const PlaylistTrack({
    required this.title,
    required this.artist,
    this.album,
    this.duration,
    this.artworkUrl,
    this.openUrl,
  });

  final String title;
  final String artist;
  final String? album;
  final Duration? duration;
  final String? artworkUrl;

  /// Link that opens the track in its app.
  final String? openUrl;
}

class PlaylistData {
  const PlaylistData({
    required this.source,
    required this.id,
    required this.title,
    required this.tracks,
    required this.sourceUrl,
    this.owner,
    this.coverUrl,
    this.truncated = false,
  });

  final MusicSource source;
  final String id;
  final String title;
  final String? owner;
  final String? coverUrl;
  final String sourceUrl;
  final List<PlaylistTrack> tracks;

  final bool truncated;
}