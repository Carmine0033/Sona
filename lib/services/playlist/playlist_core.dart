import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:http/http.dart' as http;

import 'package:media_overlay/models/playlist.dart';


// Errors
enum PlaylistErrorKind {
  invalidLink,    
  unsupportedLink, 
  notFound,      
  forbidden,    
  rateLimited,  
  network,        
  parse,          
  missingKey,     
}

final class PlaylistException implements Exception {
  const PlaylistException(this.kind, [this.detail]);
  final PlaylistErrorKind kind;
  final String? detail;

  @override
  String toString() =>
      'PlaylistException(${kind.name}${detail == null ? '' : ': $detail'})';
}

abstract interface class PlaylistResolver {
   MusicSource get source;

  /// Playlist ID
  String? matchId(Uri uri);

  Future<PlaylistData> fetch(String id, Uri original);
}

class PlaylistHttp {
  PlaylistHttp([http.Client? client]) : _client = client ?? http.Client();

  final http.Client _client;
  static const _timeout= Duration(seconds: 12);
  static const _ua = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
      'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36';
  
  Future<String> getText(Uri url, {Map<String, String>? headers}) async {
    final res= await _net(() => _client.get(url, headers: {
        'User-Agent': _ua,
        'Accept-Language': 'it-IT,it;q=0.9,en;q=0.8',
        ...?headers,
    }));
    return _check(res);
  }

  /// POST with a JSON body (YouTube's web API).
  Future<Map<String, dynamic>> postJson(Uri url, Map<String, Object?> body) async {
    final res = await _net(() => _client.post(url,
        headers: {'User-Agent': _ua, 'Content-Type': 'application/json'},
        body: jsonEncode(body)));
    return _decode(_check(res));
  }

  String _check(http.Response res) {
    switch (res.statusCode) {
      case 200:
        return utf8.decode(res.bodyBytes, allowMalformed: true);
      case 401 || 403:
        throw PlaylistException(PlaylistErrorKind.forbidden, 'HTTP ${res.statusCode}');
      case 404:
        throw const PlaylistException(PlaylistErrorKind.notFound);
      case 429:
        throw const PlaylistException(PlaylistErrorKind.rateLimited);
      default:
        throw PlaylistException(PlaylistErrorKind.network, 'HTTP ${res.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getJson(Uri url) async => _decode(await getText(url));

  Map<String, dynamic> _decode(String text) {
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) return decoded;
    } on FormatException {
      // handled below
    }
    throw const PlaylistException(PlaylistErrorKind.parse, 'JSON non valido');
  }

   Future<Uri> expand(Uri url, {int maxHops = 5}) async {
    var current = url;
    for (var hop = 0; hop < maxHops; hop++) {
      final req = http.Request('GET', current)
        ..followRedirects = false
        ..headers['User-Agent'] = _ua;
      final res = await _net(() => _client.send(req));
      final location = res.headers['location'];
      if (res.statusCode >= 300 && res.statusCode < 400 && location != null) {
        await res.stream.drain<void>();
        current = current.resolve(location);
        continue;
      }

      final body = await res.stream.bytesToString();
      final m = _longLink.firstMatch(body);
      return m == null ? current : Uri.parse(htmlUnescape(m.group(0)!));
    }
    return current;
   }
  
  void close() => _client.close();

   Future<T> _net<T>(Future<T> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on TimeoutException {
      throw const PlaylistException(PlaylistErrorKind.network, 'timeout');
    } on SocketException catch (e) {
      throw PlaylistException(PlaylistErrorKind.network, e.message);
    } on http.ClientException catch (e) {
      throw PlaylistException(PlaylistErrorKind.network, e.message);
    }
  }

  static final _longLink = RegExp(
    r'''https://(?:open\.spotify\.com|(?:www\.)?deezer\.com|music\.apple\.com|(?:music|www)\.youtube\.com)/[^\s"'<>\\]+''',
  );
}

Iterable<Map<String, dynamic>> walkMaps (Object? node, bool Function(Map<String, dynamic> m) test,) sync* {
  if (node is Map) {
      final m = node.cast<String, dynamic>();
      if (test(m)) yield m;
      for (final v in m.values) {
        yield* walkMaps(v, test);
  }
  } else if (node is List) {
    for (final v in node) {
      yield* walkMaps(v, test);
    }
  }
}

String? metaContent(String html, String property) {
  for (final m in _metaTag.allMatches(html)) {
    final tag = m.group(0)!;
    if (!tag.contains('"$property"')) continue;
    final content = _contentAttr.firstMatch(tag)?.group(1);
    if (content != null) return htmlUnescape(content);
  }
  return null;
}

final _metaTag = RegExp(r'<meta\b[^>]*>', caseSensitive: false);
final _contentAttr = RegExp(r'content="([^"]*)"');

String htmlUnescape(String s) => s
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'")
    .replaceAll('&#x27;', "'")
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&amp;', '&');

void debugDump(String name, String content) {
  if (!kDebugMode) return;
  try {
    File('${Directory.systemTemp.path}${Platform.pathSeparator}sona_$name.html')
        .writeAsStringSync(content);
  } catch (_) {}
}