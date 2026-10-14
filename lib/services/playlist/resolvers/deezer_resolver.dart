import 'package:media_overlay/models/playlist.dart';
import 'package:media_overlay/services/playlist/playlist_core.dart';

class DeezerResolver implements PlaylistResolver {
  DeezerResolver(this._http);
  final PlaylistHttp _http;

  static final _id = RegExp(r'/playlist/(\d+)');
  static const _maxTracks = 2000;

  @override
  MusicSource get source => MusicSource.deezer;

  @override
  String? matchId(Uri uri) =>
      uri.host.endsWith('deezer.com') ? _id.firstMatch(uri.path)?.group(1) : null;

  @override
  Future<PlaylistData> fetch(String id, Uri original) async {
    final meta = _checked(await _http.getJson(Uri.parse('https://api.deezer.com/playlist/$id')));

    final tracks = <PlaylistTrack>[];
    Uri? next = Uri.parse('https://api.deezer.com/playlist/$id/tracks?limit=100&index=0');
    while (next != null && tracks.length < _maxTracks) {
      final page = _checked(await _http.getJson(next));
      for (final t in (page['data'] as List? ?? const []).whereType<Map>()) {
        tracks.add(PlaylistTrack(
          title: (t['title_short'] ?? t['title'] ?? '') as String,
          artist: (t['artist']?['name'] ?? '') as String,
          album: t['album']?['title'] as String?,
          duration: t['duration'] is num
              ? Duration(seconds: (t['duration'] as num).toInt())
              : null,
          artworkUrl: t['album']?['cover_medium'] as String?,
          openUrl: t['link'] as String?,
        ));
      }
      final n = page['next'];
      next = n is String ? Uri.parse(n) : null;
    }

    return PlaylistData(
      source: source,
      id: id,
      title: meta['title'] as String? ?? 'Playlist Deezer',
      owner: meta['creator']?['name'] as String?,
      coverUrl: meta['picture_xl'] as String?,
      sourceUrl: 'https://www.deezer.com/playlist/$id',
      tracks: tracks,
      truncated: next != null,
    );
  }

  Map<String, dynamic> _checked(Map<String, dynamic> json) {
    final err = json['error'];
    if (err is! Map) return json;
    throw switch ((err['code'] as num?)?.toInt()) {
      800 => const PlaylistException(PlaylistErrorKind.notFound),
      4 => const PlaylistException(PlaylistErrorKind.rateLimited),
      _ => PlaylistException(PlaylistErrorKind.network, 'Deezer: ${err['message']}'),
    };
  }
}