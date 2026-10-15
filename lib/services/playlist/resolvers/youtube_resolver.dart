import 'package:media_overlay/models/playlist.dart';
import 'package:media_overlay/services/playlist/playlist_core.dart';

class YouTubeResolver implements PlaylistResolver {
  YouTubeResolver(this._http, this._apiKey);
  final PlaylistHttp _http;
  final String _apiKey;

  // 20 pages × 50 = 1000 tracks ≈ 21 quota units per load.
  static const _maxPages = 20;
  static const _hosts = {'youtube.com', 'www.youtube.com', 'm.youtube.com', 'music.youtube.com'};

  @override
  MusicSource get source => MusicSource.youtube;

  @override
  String? matchId(Uri uri) {
    if (!_hosts.contains(uri.host)) return null;
    final list = uri.queryParameters['list'];
    if (list != null && list.isNotEmpty) return list;
    // music.youtube.com/browse/VLPLxxxx: the real ID follows "VL"
    final seg = uri.pathSegments;
    if (seg.length == 2 && seg[0] == 'browse' && seg[1].startsWith('VL')) {
      return seg[1].substring(2);
    }
    return null;
  }

  @override
  Future<PlaylistData> fetch(String id, Uri original) async {
    if (_apiKey.isEmpty) {
      throw const PlaylistException(PlaylistErrorKind.missingKey, 'YouTube');
    }
    final music = original.host == 'music.youtube.com';

    try {
      final meta = await _http.getJson(_api('playlists', {'part': 'snippet', 'id': id}));
      final items = meta['items'] as List? ?? const [];
      // A private playlist doesn't 403: it just comes back empty.
      if (items.isEmpty) throw const PlaylistException(PlaylistErrorKind.notFound);
      final snip = (items.first as Map)['snippet'] as Map? ?? const {};

      final tracks = <PlaylistTrack>[];
      String? pageToken;
      var pages = 0;
      do {
        final page = await _http.getJson(_api('playlistItems', {
          'part': 'snippet',
          'maxResults': '50',
          'playlistId': id,
          'pageToken': ?pageToken,
        }));
        for (final it in (page['items'] as List? ?? const []).whereType<Map>()) {
          final s = it['snippet'] as Map? ?? const {};
          final owner = s['videoOwnerChannelTitle'] as String?;
          if (owner == null) continue; // deleted or private video
          final videoId = (s['resourceId'] as Map?)?['videoId'] as String?;
          tracks.add(PlaylistTrack(
            title: s['title'] as String? ?? '',
            // Auto-generated YT Music channels are named "Artist - Topic"
            artist: owner.replaceFirst(RegExp(r' - Topic$'), ''),
            artworkUrl: _thumb(s['thumbnails']),
            openUrl: videoId == null
                ? null
                : music
                    ? 'https://music.youtube.com/watch?v=$videoId&list=$id'
                    : 'https://www.youtube.com/watch?v=$videoId&list=$id',
          ));
        }
        pageToken = page['nextPageToken'] as String?;
      } while (pageToken != null && ++pages < _maxPages);

      return PlaylistData(
        source: source,
        id: id,
        title: snip['title'] as String? ?? 'Playlist YouTube',
        owner: snip['channelTitle'] as String?,
        coverUrl: _thumb(snip['thumbnails']),
        sourceUrl: music
            ? 'https://music.youtube.com/playlist?list=$id'
            : 'https://www.youtube.com/playlist?list=$id',
        tracks: tracks,
        truncated: pageToken != null,
      );
    } on PlaylistException catch (e) {
      if (e.kind == PlaylistErrorKind.forbidden) {
        throw const PlaylistException(PlaylistErrorKind.rateLimited, 'quota YouTube o chiave API');
      }
      if (e.kind == PlaylistErrorKind.notFound && id.startsWith('RD')) {
        throw const PlaylistException(PlaylistErrorKind.unsupportedLink, 'mix automatico');
      }
      rethrow;
    }
  }

  Uri _api(String endpoint, Map<String, String> q) =>
      Uri.https('www.googleapis.com', '/youtube/v3/$endpoint', {...q, 'key': _apiKey});

  String? _thumb(Object? t) {
    if (t is! Map) return null;
    for (final k in const ['medium', 'high', 'default']) {
      final u = (t[k] as Map?)?['url'];
      if (u is String) return u;
    }
    return null;
  }
}