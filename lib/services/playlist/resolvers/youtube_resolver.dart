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
    final music = original.host == 'music.youtube.com';
    // No key (e.g. a build without --dart-define): read the playlist the way
    // youtube.com itself does. Same result, minus the official quota.
    if (_apiKey.isEmpty) return _fetchWeb(id, music);

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

  // --- Without API key: YouTube's web API (/youtubei/v1/browse) ---
  //
  // youtube_explode_dart 3.1.0 finds 0 videos here: YouTube now sends them as
  // "lockupViewModel" (verified 2026-10-23), so we read the JSON ourselves.
  // If YouTube changes it again, this is the code to update.

  static final _browse =
      Uri.https('www.youtube.com', '/youtubei/v1/browse', {'prettyPrint': 'false'});
  static const _client = {'clientName': 'WEB', 'clientVersion': '2.20261022.01.00', 'hl': 'en'};

  Future<PlaylistData> _fetchWeb(String id, bool music) async {
    var res = await _http.postJson(_browse, {'context': {'client': _client}, 'browseId': 'VL$id'});
    if (res['contents'] == null) {
      // No 404: an "ERROR" alert ("does not exist", "unviewable" for mixes).
      if (id.startsWith('RD')) {
        throw const PlaylistException(PlaylistErrorKind.unsupportedLink, 'mix automatico');
      }
      throw PlaylistException(PlaylistErrorKind.notFound, _alert(res));
    }
    final first = res; // title and author live on the first page only

    final tracks = <PlaylistTrack>[];
    String? next;
    var pages = 0;
    while (true) {
      next = null;
      for (final item in _webItems(res).whereType<Map>()) {
        final lockup = item['lockupViewModel'];
        if (lockup is Map) {
          final t = _webTrack(lockup, id, music);
          if (t != null) tracks.add(t);
        }
        next ??= _dig(item, const ['continuationItemViewModel', 'continuationCommand',
            'innertubeCommand', 'continuationCommand', 'token']) as String?;
      }
      if (next == null || ++pages >= _maxPages) break;
      res = await _http.postJson(_browse, {'context': {'client': _client}, 'continuation': next});
    }

    final owner = _dig(first['header'], const ['pageHeaderRenderer', 'content', 'pageHeaderViewModel',
        'metadata', 'contentMetadataViewModel', 'metadataRows', 0, 'metadataParts', 0,
        'avatarStack', 'avatarStackViewModel', 'text', 'content']) as String?;
    return PlaylistData(
      source: source,
      id: id,
      title: _dig(first['metadata'], const ['playlistMetadataRenderer', 'title']) as String? ??
          'Playlist YouTube',
      owner: owner?.replaceFirst(RegExp(r'^by\s+'), ''),
      coverUrl: tracks.isEmpty ? null : tracks.first.artworkUrl,
      sourceUrl: music
          ? 'https://music.youtube.com/playlist?list=$id'
          : 'https://www.youtube.com/playlist?list=$id',
      tracks: tracks,
      truncated: next != null,
    );
  }

  /// Videos (plus the "load more" marker) of the first page or of a continuation.
  List _webItems(Map res) {
    final sections = _dig(res, const ['contents', 'twoColumnBrowseResultsRenderer', 'tabs', 0,
        'tabRenderer', 'content', 'sectionListRenderer', 'contents']);
    if (sections is List) {
      for (final s in sections) {
        final items = _dig(s, const ['itemSectionRenderer', 'contents']);
        if (items is List && items.any((i) => i is Map && i['lockupViewModel'] != null)) {
          return items;
        }
      }
      return const [];
    }
    for (final a in (res['onResponseReceivedActions'] as List? ?? const [])) {
      final items = _dig(a, const ['appendContinuationItemsAction', 'continuationItems']);
      if (items is List) return items;
    }
    return const [];
  }

  PlaylistTrack? _webTrack(Map lockup, String listId, bool music) {
    final videoId = lockup['contentId'];
    if (videoId is! String || lockup['contentType'] != 'LOCKUP_CONTENT_TYPE_VIDEO') return null;
    final meta = _dig(lockup, const ['metadata', 'lockupMetadataViewModel']);
    final title = _dig(meta, const ['title', 'content']) as String?;
    final owner = _dig(meta, const ['metadata', 'contentMetadataViewModel', 'metadataRows', 0,
        'metadataParts', 0, 'text', 'content']) as String?;
    if (title == null || owner == null) return null; // deleted or private video

    Duration? duration;
    final overlays = _dig(lockup, const ['contentImage', 'thumbnailViewModel', 'overlays']);
    for (final o in (overlays is List ? overlays : const [])) {
      final badges = _dig(o, const ['thumbnailBottomOverlayViewModel', 'badges']);
      for (final b in (badges is List ? badges : const [])) {
        duration ??= _clock(_dig(b, const ['thumbnailBadgeViewModel', 'text']));
      }
    }

    return PlaylistTrack(
      title: title,
      // Auto-generated YT Music channels are named "Artist - Topic"
      artist: owner.replaceFirst(RegExp(r' - Topic$'), ''),
      duration: duration,
      artworkUrl: 'https://i.ytimg.com/vi/$videoId/mqdefault.jpg',
      openUrl: music
          ? 'https://music.youtube.com/watch?v=$videoId&list=$listId'
          : 'https://www.youtube.com/watch?v=$videoId&list=$listId',
    );
  }

  /// "3:25" or "1:02:03"; null for "LIVE", "SHORTS" and the like.
  static Duration? _clock(Object? text) {
    if (text is! String || !RegExp(r'^\d+(:\d{2}){1,2}$').hasMatch(text)) return null;
    final p = text.split(':').map(int.parse).toList();
    var s = 0;
    for (final x in p) {
      s = s * 60 + x;
    }
    return Duration(seconds: s);
  }

  static String? _alert(Map res) {
    final runs = _dig(res, const ['alerts', 0, 'alertRenderer', 'text', 'runs']);
    return runs is List ? runs.map((r) => r is Map ? r['text'] ?? '' : '').join() : null;
  }

  /// Walks maps and lists; null as soon as a step is missing.
  static Object? _dig(Object? o, List<Object> path) {
    for (final k in path) {
      if (k is int) {
        o = o is List && k < o.length ? o[k] : null;
      } else {
        o = o is Map ? o[k] : null;
      }
      if (o == null) return null;
    }
    return o;
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