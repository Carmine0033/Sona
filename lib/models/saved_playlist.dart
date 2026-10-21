import 'package:media_overlay/models/playlist.dart';

/// A playlist in the user's library: its data plus how and when it was added.
class SavedPlaylist {
  SavedPlaylist({
    required this.data,
    required this.link,
    required this.addedAt,
    this.syncedAt,
    this.favorite = false,
  });

  final PlaylistData data;
  final String link; // used by "Sync"
  final DateTime addedAt;
  final DateTime? syncedAt;
  final bool favorite;

  /// Stable identity: pasting the same link twice doesn't create a duplicate.
  String get key => '${data.source.name}:${data.id}';

  bool matches(PlaylistData other) => other.source == data.source && other.id == data.id;

  // Computed once: the grid reads them on every rebuild.
  late final Duration totalDuration =
      data.tracks.fold(Duration.zero, (sum, t) => sum + (t.duration ?? Duration.zero));

  late final List<String> topArtists = () {
    final counts = <String, int>{};
    for (final t in data.tracks) {
      final a = t.artist.split(',').first.trim();
      if (a.isNotEmpty) counts[a] = (counts[a] ?? 0) + 1;
    }
    final sorted = counts.keys.toList()..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    return sorted.take(4).toList();
  }();

  SavedPlaylist copyWith({PlaylistData? data, DateTime? syncedAt, bool? favorite}) => SavedPlaylist(
        data: data ?? this.data,
        link: link,
        addedAt: addedAt,
        syncedAt: syncedAt ?? this.syncedAt,
        favorite: favorite ?? this.favorite,
      );

  Map<String, dynamic> toJson() => {
        'link': link,
        'addedAt': addedAt.toIso8601String(),
        if (syncedAt != null) 'syncedAt': syncedAt!.toIso8601String(),
        'favorite': favorite,
        'data': _dataToJson(data),
      };

  /// null if the entry is unreadable: one broken entry must not lose the others.
  static SavedPlaylist? tryParse(Map<String, dynamic> j) {
    try {
      final data = _dataFromJson(j['data'] as Map<String, dynamic>);
      if (data == null) return null;
      return SavedPlaylist(
        data: data,
        link: j['link'] as String,
        addedAt: DateTime.parse(j['addedAt'] as String),
        syncedAt: j['syncedAt'] == null ? null : DateTime.parse(j['syncedAt'] as String),
        favorite: j['favorite'] == true,
      );
    } catch (_) {
      return null;
    }
  }
}

Map<String, dynamic> _dataToJson(PlaylistData d) => {
      'source': d.source.name,
      'id': d.id,
      'title': d.title,
      'owner': d.owner,
      'cover': d.coverUrl,
      'url': d.sourceUrl,
      'truncated': d.truncated,
      'tracks': [
        for (final t in d.tracks)
          {
            't': t.title,
            'a': t.artist,
            if (t.album != null) 'al': t.album,
            if (t.duration != null) 'd': t.duration!.inMilliseconds,
            if (t.artworkUrl != null) 'art': t.artworkUrl,
            if (t.openUrl != null) 'o': t.openUrl,
          },
      ],
    };

PlaylistData? _dataFromJson(Map<String, dynamic> j) {
  final source = MusicSource.values.asNameMap()[j['source']];
  if (source == null) return null;
  return PlaylistData(
    source: source,
    id: j['id'] as String,
    title: j['title'] as String,
    owner: j['owner'] as String?,
    coverUrl: j['cover'] as String?,
    sourceUrl: j['url'] as String,
    truncated: j['truncated'] == true,
    tracks: [
      for (final t in (j['tracks'] as List? ?? const []).whereType<Map>())
        PlaylistTrack(
          title: t['t'] as String,
          artist: t['a'] as String,
          album: t['al'] as String?,
          duration: t['d'] is int ? Duration(milliseconds: t['d'] as int) : null,
          artworkUrl: t['art'] as String?,
          openUrl: t['o'] as String?,
        ),
    ],
  );
}
