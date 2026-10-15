import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import 'package:media_overlay/models/playlist.dart';
import 'package:media_overlay/services/audio/track_audio_source.dart';

class YouTubeAudioSource implements TrackAudioSource {
  final _yt = YoutubeExplode();

  // Cache the matched VIDEO, not the audio URL: YouTube URLs expire
  // after a few hours and are tied to the IP.
  final _matches = <String, VideoId>{};

  /// Clients to try, in order. Verified 2026-10-14: only these two work.
  /// Update HERE (and the library) when YouTube changes its blocks.
  static final _clients = [YoutubeApiClient.android, YoutubeApiClient.androidSdkless];

  @override
  Future<ResolvedAudio> resolve(PlaylistTrack t) async {
    final video = await _match(t);
    Object? lastError;

    // One client at a time: if one is blocked, try the next.
    for (final client in _clients) {
      try {
        final manifest = await _yt.videos.streamsClient.getManifest(
          video.id,
          ytClients: [client],
        );
        // Audio-only streams need a PO token, otherwise YouTube serves 1 MB
        // and then 403s (verified 2026-10-14). Muxed itag 18 (mp4 360p, AAC)
        // has no such limit and supports seeking; mpv drops the video
        // (vid=no in the view model). Same choice as Spotube/NewPipe.
        final muxed = manifest.muxed.where((s) => s.tag == 18);
        final stream = muxed.isNotEmpty
            ? muxed.first
            : manifest.muxed.isNotEmpty
            ? manifest.muxed.withHighestBitrate()
            : null;
        if (stream == null) {
          lastError = 'nessuno stream muxed';
          continue;
        }
        return ResolvedAudio(
          url: stream.url, // use right away: contains "expire", never store it
          matchedTitle: '${video.author} | ${video.title}',
        );
      } catch (e) {
        lastError = e;
      }
    }

    // Clear category for the UI instead of the raw exception.
    final msg = '$lastError';
    if (msg.contains('not a bot') || msg.contains('Sign in')) {
      throw AudioResolveException(AudioErrorKind.blocked, msg);
    }
    throw AudioResolveException(AudioErrorKind.unavailable, '${t.title}: $msg');
  }

  Future<Video> _match(PlaylistTrack t) async {
    final key = '${t.artist}|${t.title}'.toLowerCase();
    final cachedId = _matches[key];
    if (cachedId != null) return _yt.videos.get(cachedId);

    final results = await _yt.search.search('${t.artist} - ${t.title}');
    Video? best;
    var bestScore = -1000;
    for (final v in results.take(8)) {
      final s = _score(t, v);
      if (s > bestScore) { best = v; bestScore = s; }
    }
    if (best == null || bestScore <= -1000) {
      throw AudioResolveException(AudioErrorKind.noMatch, t.title);
    }
    _matches[key] = best.id;
    return best;
  }

  static String _norm(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r'\s*-\s*topic$'), '')
    .replaceAll(RegExp(r'vevo$|official$'), '')
    .replaceAll(RegExp(r'[^a-z0-9]'), '');

  
  int _score(PlaylistTrack t, Video v) {
    var s = 0;
    final d = v.duration;
    if (t.duration != null && d != null) {
      final diff = (d - t.duration!).inSeconds.abs();
      if (diff > 8) return -1000;
      s += diff <= 2 ? 15 : diff <= 5 ? 8 : 2;
    }

    final author= v.author;
    final artist= _norm(t.artist.split(',').first);
    if (author.endsWith(' - Topic')) {
      s += 25;

    } else if (artist.isNotEmpty && _norm(author).contains(artist)) {
      s+=20;
    }
    final title = v.title.toLowerCase();
    final wanted = t.title.toLowerCase();
    if (title.trim() == wanted.trim()){
      s+=15;
    } else if (title.contains(wanted)) {
      s+=10;
    }
    if (title.contains('official audio')) s += 3;
    for (final bad in const ['live', 'cover', 'karaoke', 'remix', 'sped up', 'slowed', 'nightcore', '8d']) {
      if (title.contains(bad) && !wanted.contains(bad)) s -= 12;
    }
    return s;
  }

  @override
  void dispose() => _yt.close();
}