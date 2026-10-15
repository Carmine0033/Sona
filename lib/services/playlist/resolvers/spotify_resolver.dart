import 'dart:convert';

import 'package:media_overlay/models/playlist.dart';
import 'package:media_overlay/services/playlist/playlist_core.dart';


class SpotifyResolver implements PlaylistResolver {
  SpotifyResolver(this._http);
  final PlaylistHttp _http;

  // Spotify IDs are 22-char base62.
  static final _id = RegExp(r'playlist[/:]([A-Za-z0-9]{22})');
  static final _nextData = RegExp(
    r'<script[^>]*id="__NEXT_DATA__"[^>]*>(.*?)</script>',
    dotAll: true,
  );

  @override
  MusicSource get source => MusicSource.spotify;

  @override
  String? matchId(Uri uri) {
    final ok = uri.scheme == 'spotify' ||
        uri.host == 'open.spotify.com' ||
        uri.host == 'play.spotify.com';
    // toString covers both /intl-it/playlist/ID and spotify:playlist:ID
    return ok ? _id.firstMatch(uri.toString())?.group(1) : null;
  }

  @override
  Future<PlaylistData> fetch(String id, Uri original) async {
    final html = await _http.getText(Uri.parse('https://open.spotify.com/embed/playlist/$id'));

    final raw = _nextData.firstMatch(html)?.group(1);
    if (raw == null) {
      debugDump('spotify', html);
      throw const PlaylistException(PlaylistErrorKind.parse, 'Spotify: dati embed assenti');
    }

    final Object? json;
    try {
      json = jsonDecode(raw);
    } on FormatException {
      debugDump('spotify', html);
      throw const PlaylistException(PlaylistErrorKind.parse, 'Spotify: JSON non valido');
    }

    final entity = walkMaps(json, (m) => m['trackList'] is List).firstOrNull;
    if (entity == null) throw const PlaylistException(PlaylistErrorKind.notFound);

    final tracks = <PlaylistTrack>[
      for (final t in (entity['trackList'] as List).whereType<Map>())
        if (t['title'] is String)
          PlaylistTrack(
            title: t['title'] as String,
            artist: _str(t['subtitle'])?.replaceAll('\u00a0', ' ') ?? '',
            duration: t['duration'] is num
                ? Duration(milliseconds: (t['duration'] as num).toInt())
                : null,
            openUrl: _str(t['uri']), // spotify:track:... opens the desktop app
          ),
    ];

    return PlaylistData(
      source: source,
      id: id,
      title: _str(entity['name']) ?? _str(entity['title']) ?? 'Playlist Spotify',
      owner: _str(entity['subtitle']),
      coverUrl: _largestImage(entity['coverArt']),
      sourceUrl: 'https://open.spotify.com/playlist/$id',
      tracks: tracks,
    );
  }

  static String? _str(Object? v) => v is String ? v : null;

  static String? _largestImage(Object? coverArt) {
    final sources = coverArt is Map ? coverArt['sources'] : null;
    if (sources is! List) return null;
    final list = sources.whereType<Map>().where((s) => s['url'] is String).toList()
      ..sort((a, b) => ((b['width'] ?? 0) as num).compareTo((a['width'] ?? 0) as num));
    return list.isEmpty ? null : list.first['url'] as String;
  }
}