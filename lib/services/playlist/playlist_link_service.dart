import 'package:http/http.dart' as http;

import 'package:media_overlay/models/playlist.dart';
import 'package:media_overlay/services/playlist/playlist_core.dart';
import 'package:media_overlay/services/playlist/resolvers/apple_music_resolver.dart';
import 'package:media_overlay/services/playlist/resolvers/deezer_resolver.dart';
import 'package:media_overlay/services/playlist/resolvers/spotify_resolver.dart';
import 'package:media_overlay/services/playlist/resolvers/youtube_resolver.dart';

class PlaylistLinkService {
  PlaylistLinkService({String youtubeApiKey = '', http.Client? client})
      : _http = PlaylistHttp(client) {
    _resolvers = [
      SpotifyResolver(_http),
      YouTubeResolver(_http, youtubeApiKey),
      AppleMusicResolver(_http),
      DeezerResolver(_http),
      // New service = one class + one line here.
    ];
  }

  final PlaylistHttp _http;
  late final List<PlaylistResolver> _resolvers;

  static const _shortHosts = {
    'spotify.link', 'spoti.fi',
    'link.deezer.com', 'deezer.page.link', 'dzr.page.link',
  };

  Future<PlaylistData> load(String raw) async {
    var uri = _parse(raw);
    if (_shortHosts.contains(uri.host)) uri = await _http.expand(uri);

    for (final r in _resolvers) {
      final id = r.matchId(uri);
      if (id != null) return r.fetch(id, uri);
    }
    throw const PlaylistException(PlaylistErrorKind.unsupportedLink);
  }

  Uri _parse(String raw) {
    var s = raw.trim();
    final found = RegExp(r'(https?://\S+|spotify:playlist:\S+)').firstMatch(s);
    if (found != null) s = found.group(0)!;
    if (s.isEmpty) throw const PlaylistException(PlaylistErrorKind.invalidLink);
    if (!s.contains('://') && !s.startsWith('spotify:')) s = 'https://$s';

    final uri = Uri.tryParse(s);
    if (uri == null || (uri.host.isEmpty && uri.scheme != 'spotify')) {
      throw const PlaylistException(PlaylistErrorKind.invalidLink);
    }
    return uri;
  }

  void dispose() => _http.close();
}