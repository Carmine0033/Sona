import 'dart:convert';

import 'package:media_overlay/models/playlist.dart';
import 'package:media_overlay/services/playlist/playlist_core.dart';

/// UNOFFICIAL scraping of the public music.apple.com page.
/// The official Apple Music API requires the Apple Developer Program.
class AppleMusicResolver implements PlaylistResolver {
  AppleMusicResolver(this._http);
  final PlaylistHttp _http;

  // pl.u-xxxx (shared user playlists) or pl.xxxx (editorial)
  static final _id = RegExp(r'/playlist/(?:[^/]+/)?(pl\.[\w-]+)');
  static final _serverData = RegExp(
    r'<script[^>]*id="serialized-server-data"[^>]*>(.*?)</script>',
    dotAll: true,
  );

  @override
  MusicSource get source => MusicSource.appleMusic;

  @override
  String? matchId(Uri uri) {
    if (uri.host != 'music.apple.com') return null;
    // /library/playlist/p.xxx = private library, unreachable without login
    if (uri.path.contains('/library/')) return null;
    return _id.firstMatch(uri.path)?.group(1);
  }

  @override
  Future<PlaylistData> fetch(String id, Uri original) async {
    // The original path holds the right storefront (it/us/...).
    final html = await _http.getText(Uri.https('music.apple.com', original.path));

    final raw = _serverData.firstMatch(html)?.group(1);
    if (raw == null) {
      debugDump('apple', html);
      throw const PlaylistException(PlaylistErrorKind.parse, 'Apple Music: dati pagina assenti');
    }

    final Object? json;
    try {
      json = jsonDecode(raw);
    } on FormatException {
      debugDump('apple', html);
      throw const PlaylistException(PlaylistErrorKind.parse, 'Apple Music: JSON non valido');
    }

    // A track is a map with title, artist and duration: its shape is enough.
    final tracks = <PlaylistTrack>[
      for (final m in walkMaps(json, _looksLikeTrack))
        PlaylistTrack(
          title: m['title'] as String,
          artist: m['artistName'] as String,
          album: m['albumName'] is String ? m['albumName'] as String : null,
          duration: Duration(
            milliseconds: ((m['duration'] ?? m['durationInMillis']) as num).toInt(),
          ),
          artworkUrl: _artwork(m['artwork']),
        ),
    ];
    if (tracks.isEmpty) {
      debugDump('apple', html);
      throw const PlaylistException(PlaylistErrorKind.notFound);
    }

    final rawTitle = metaContent(html, 'og:title') ?? 'Playlist Apple Music';
    return PlaylistData(
      source: source,
      id: id,
      title: rawTitle
          .replaceAll('\u200e', '') // Apple prepends an invisible LRM character
          .replaceFirst(RegExp(r'\s*(?:[-–|]|on|su)\s*Apple\s*Music$', caseSensitive: false), '')
          .trim(),
      coverUrl: metaContent(html, 'og:image'),
      sourceUrl: 'https://music.apple.com${original.path}',
      tracks: tracks,
    );
  }

  static bool _looksLikeTrack(Map<String, dynamic> m) =>
      m['title'] is String &&
      m['artistName'] is String &&
      (m['duration'] is num || m['durationInMillis'] is num);

  /// Apple URLs are templates: .../{w}x{h}bb.{f}
  static String? _artwork(Object? art) {
    final url = walkMaps(art, (m) => m['url'] is String)
        .map((m) => m['url'] as String)
        .firstOrNull;
    return url
        ?.replaceAll('{w}', '200')
        .replaceAll('{h}', '200')
        .replaceAll('{c}', 'bb')
        .replaceAll('{f}', 'jpg');
  }
}