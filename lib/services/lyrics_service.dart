import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/lyrics.dart';

class LyricsService {
  static const _ua = 'Sona/0.1.0 (https://github.com/your/sona)';

  static Future<List<LyricLine>> fetchSynced(
      String artist, String title, String album, int durationSec) async {
    try {
      final getUri = Uri.https('lrclib.net', '/api/get', {
        'artist_name': artist,
        'track_name': title,
        if (album.isNotEmpty) 'album_name': album,
        if (durationSec > 0) 'duration': '$durationSec',
      });
      var res = await http.get(getUri, headers: {'User-Agent': _ua});
      if (res.statusCode == 200) {
        final synced =
            (jsonDecode(res.body) as Map<String, dynamic>)['syncedLyrics']
                as String?;
        if (synced != null && synced.isNotEmpty) return parseLrc(synced);
      }

      final searchUri = Uri.https('lrclib.net', '/api/search', {
        'track_name': title,
        'artist_name': artist,
      });
      res = await http.get(searchUri, headers: {'User-Agent': _ua});
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        for (final item in list) {
          final synced = item['syncedLyrics'] as String?;
          if (synced != null && synced.isNotEmpty) return parseLrc(synced);
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}