import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'package:media_overlay/models/playlist.dart';

/// Cover and album found on Deezer for a track (either may be missing).
class TrackMeta {
  const TrackMeta({this.cover, this.album});
  final String? cover;
  final String? album;
  static const empty = TrackMeta();
}

class ArtworkService {
  ArtworkService([http.Client? client]) : _client = client ?? http.Client();

  final http.Client _client;
  final _cache = <String, TrackMeta>{};
  final _inflight = <String, Future<TrackMeta>>{};

  static const _maxParallel = 4;
  int _running = 0;
  final _waiters = <Completer<void>>[];

  Future<TrackMeta> find(String artist, String title) {
    final key = '${artist.toLowerCase()}|${title.toLowerCase()}';
    final hit = _cache[key];
    if (hit != null) return Future.value(hit);
    return _inflight[key] ??= _lookup(artist, title).then((m) {
      _cache[key] = m;
      return m;
    // Block body, not arrow: remove() returns this same future and
    // whenComplete would wait on itself.
    }).whenComplete(() {
      _inflight.remove(key);
    });
  }

  /// [TrackMeta.empty] = Deezer has nothing for this track (cached).
  /// Network errors and quota errors propagate and are NOT cached, so the
  /// next call retries instead of remembering "no cover" forever.
  Future<TrackMeta> _lookup(String artist, String title) async {
    await _acquire();
    try {
      final mainArtist = artist.split(',').first.trim();
      // 1) exact search, 2) free-text search as fallback
      for (final q in ['artist:"$mainArtist" track:"$title"', '$mainArtist $title']) {
        final uri = Uri.https('api.deezer.com', '/search', {'q': q, 'limit': '1'});
        final res = await _client.get(uri).timeout(const Duration(seconds: 8));
        if (res.statusCode != 200) {
          throw http.ClientException('Deezer HTTP ${res.statusCode}', uri);
        }
        final json = jsonDecode(utf8.decode(res.bodyBytes));
        // Deezer reports quota errors as 200 + {"error": ...}
        if (json is Map && json['error'] != null) {
          throw http.ClientException('Deezer: ${json['error']}', uri);
        }
        final data = json is Map ? json['data'] : null;
        if (data is List && data.isNotEmpty) {
          final album = (data.first as Map)['album'];
          if (album is Map) {
            return TrackMeta(
              cover: album['cover_medium'] as String?,
              album: album['title'] as String?,
            );
          }
        }
      }
      return TrackMeta.empty;
    } finally {
      _release();
    }
  }

  Future<void> _acquire() async {
    if (_running < _maxParallel) {
      _running++;
      return;
    }
    final c = Completer<void>();
    _waiters.add(c);
    await c.future; // slot handed over by the finishing task
  }

  void _release() {
    if (_waiters.isNotEmpty) {
      _waiters.removeAt(0).complete(); // hand over the slot without decrementing
    } else {
      _running--;
    }
  }

  /// Downloads the image: the card and blurred background use bytes,
  /// like SMTC artwork.
  Future<Uint8List> fetchBytes(String url) async {
    final uri = Uri.parse(url);
    final res = await _client.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200 || res.bodyBytes.isEmpty) {
      throw http.ClientException('Cover HTTP ${res.statusCode}', uri);
    }
    return res.bodyBytes;
  }

  void dispose() => _client.close();
}

final artworkServiceProvider = Provider<ArtworkService>((ref) {
  final service = ArtworkService();
  ref.onDispose(service.dispose);
  return service;
});

/// Cover + album of a track: the source's own data when complete,
/// otherwise looked up on Deezer.
final trackMetaProvider = FutureProvider.family<TrackMeta, PlaylistTrack>((ref, t) async {
  if (t.artworkUrl != null && t.album != null) {
    return TrackMeta(cover: t.artworkUrl, album: t.album); // no network
  }
  final m = await ref.watch(artworkServiceProvider).find(t.artist, t.title);
  return TrackMeta(cover: t.artworkUrl ?? m.cover, album: t.album ?? m.album);
});

/// Track artwork: the source's own if present, otherwise looked up.
final trackArtworkProvider = FutureProvider.family<String?, PlaylistTrack>((ref, t) async {
  // Known cover: never depend on the Deezer lookup (which may fail offline).
  if (t.artworkUrl != null) return t.artworkUrl;
  return (await ref.watch(trackMetaProvider(t).future)).cover;
});
