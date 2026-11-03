import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/lyrics.dart';

class LyricsService {
  static const _ua = 'Sona/0.1.0 (https://github.com/Carmine0033/Sona)';
  static const _timeout = Duration(seconds: 8);

  static Future<List<LyricLine>> fetchSynced(
      String artist, String title, String album, int durationSec) async {
    try {
      final getUri = Uri.https('lrclib.net', '/api/get', {
        'artist_name': artist,
        'track_name': title,
        if (album.isNotEmpty) 'album_name': album,
        if (durationSec > 0) 'duration': '$durationSec',
      });
      var res = await http
          .get(getUri, headers: {'User-Agent': _ua})
          .timeout(_timeout);

      if (res.statusCode == 200) {
        final synced =
            (jsonDecode(res.body) as Map<String, dynamic>)['syncedLyrics']
                as String?;
        if (synced != null && synced.isNotEmpty) return parseLrc(synced);
      }
      // No exact match (LRCLIB currently answers 503 for that too): search.

      final searchUri = Uri.https('lrclib.net', '/api/search', {
        'track_name': title,
        'artist_name': artist,
      });
      res = await http
          .get(searchUri, headers: {'User-Agent': _ua})
          .timeout(_timeout);

      if (res.statusCode == 200) {
        // A song can have many versions (album, live, remaster) whose timings
        // differ by tens of seconds: take the one closest in length.
        String? best;
        var bestGap = double.infinity;
        for (final item in (jsonDecode(res.body) as List).whereType<Map>()) {
          final synced = item['syncedLyrics'] as String?;
          if (synced == null || synced.isEmpty) continue;
          if (durationSec <= 0) return parseLrc(synced);
          final d = (item['duration'] as num?)?.toDouble();
          final gap = d == null ? double.maxFinite : (d - durationSec).abs();
          if (gap < bestGap) {
            best = synced;
            bestGap = gap;
          }
        }
        if (best != null) return parseLrc(best);
      } else if (res.statusCode >= 500) {
        throw TimeoutException('Server error (lrclib.net HTTP ${res.statusCode})');
      }
      return [];
    } on TimeoutException {
      rethrow;
    } on SocketException {
      throw TimeoutException('lrclib.net non raggiungibile (Timeout server)');
    } on http.ClientException {
      throw TimeoutException('lrclib.net non raggiungibile (Timeout server)');
    } catch (_) {
      return [];
    }
  }
}