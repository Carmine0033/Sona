import 'dart:convert';
import 'dart:io';

import 'package:media_overlay/models/saved_playlist.dart';

/// Saves the playlist library to %APPDATA%/Sona/library.json.
class LibraryStore {
  LibraryStore(this._file);

  factory LibraryStore.defaultLocation() {
    final base = Platform.environment['APPDATA'] ?? Directory.systemTemp.path;
    final sep = Platform.pathSeparator;
    return LibraryStore(File('$base${sep}Sona${sep}library.json'));
  }

  final File _file;
  Future<void> _queue = Future.value();

  Future<List<SavedPlaylist>> load() async {
    if (!await _file.exists()) return [];
    try {
      final raw = jsonDecode(await _file.readAsString());
      final list = (raw is Map ? raw['playlists'] : null) as List? ?? const [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(SavedPlaylist.tryParse)
          .whereType<SavedPlaylist>()
          .toList();
    } catch (_) {
      // Unreadable file: keep it aside instead of overwriting it.
      try {
        await _file.rename('${_file.path}.corrupt');
      } catch (_) {}
      return [];
    }
  }

  /// Writes are queued so an older save never overwrites a newer one.
  Future<void> save(List<SavedPlaylist> items) =>
      _queue = _queue.then((_) => _write(items)).catchError((Object _) {});

  // Write to a temp file, then rename: a crash mid-write can't corrupt the library.
  Future<void> _write(List<SavedPlaylist> items) async {
    await _file.parent.create(recursive: true);
    final tmp = File('${_file.path}.tmp');
    await tmp.writeAsString(
      jsonEncode({
        'version': 1,
        'playlists': [for (final p in items) p.toJson()],
      }),
      flush: true,
    );
    await tmp.rename(_file.path);
  }
}
