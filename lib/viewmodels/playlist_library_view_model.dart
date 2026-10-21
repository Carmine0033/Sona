import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:media_overlay/models/playlist.dart';
import 'package:media_overlay/models/saved_playlist.dart';
import 'package:media_overlay/services/library_store.dart';
import 'package:media_overlay/services/playlist/playlist_link_service.dart';
import 'package:media_overlay/services/settings_service.dart';
import 'package:media_overlay/viewmodels/playlist_view_model.dart';

final libraryStoreProvider = Provider<LibraryStore>((ref) => LibraryStore.defaultLocation());
final playlistLibraryProvider = AsyncNotifierProvider<PlaylistLibraryViewModel, List<SavedPlaylist>>(PlaylistLibraryViewModel.new);

class PlaylistLibraryViewModel extends AsyncNotifier<List<SavedPlaylist>> {
  static const _legacyKey = 'lastPlaylistUrl';

  LibraryStore get _store => ref.read(libraryStoreProvider);
  PlaylistLinkService get _links => ref.read(playlistLinkServiceProvider);
  List<SavedPlaylist> get _items => state.asData?.value ?? const [];

  @override
  Future<List<SavedPlaylist>> build() async {
    final items = await ref.watch(libraryStoreProvider).load();
    // One-time migration of the single playlist saved by older versions.
    // The old link is dropped only once it's in the library, so being
    // offline on first launch doesn't lose it.
    final old = SettingsService.getString(_legacyKey);
    if (items.isEmpty && old != null && old.isNotEmpty) {
      try {
        final data = await _links.load(old);
        final now = DateTime.now();
        items.add(SavedPlaylist(data: data, link: old, addedAt: now, syncedAt: now));
        await _store.save(items);
        SettingsService.remove(_legacyKey);
      } catch (_) {}
    }
    return items;
  }

  void _commit(List<SavedPlaylist> next) {
    state = AsyncData(next);
    _store.save(next);
  }

  Future<SavedPlaylist> add(String link) async {
    // Wait for the library to load, or the first add would overwrite it.
    await future;
    final data = await _links.load(link);
    final now = DateTime.now();
    final fresh = SavedPlaylist(data: data, link: link.trim(), addedAt: now, syncedAt: now);
    final existing = _items.where((p) => p.key == fresh.key).firstOrNull;
    final saved = existing?.copyWith(data: data, syncedAt: now) ?? fresh;
    _commit([saved, ..._items.where((p) => p.key != saved.key)]);
    return saved;
  }

  Future<void> sync(String key) async {
    final p = _items.where((x) => x.key == key).firstOrNull;
    if (p == null) return;
    final data = await _links.load(p.link);
    final now = DateTime.now();
    // Re-read the list: it may have changed while loading.
    _commit([for (final x in _items) x.key == key ? x.copyWith(data: data, syncedAt: now) : x]);
  }

  void toggleFavorite(String key) =>
      _commit([for (final x in _items) x.key == key ? x.copyWith(favorite: !x.favorite) : x]);

  void remove(String key) => _commit(_items.where((x) => x.key != key).toList());
}

class LibraryFilter {
  const LibraryFilter({this.source, this.favoritesOnly = false});
  final MusicSource? source;
  final bool favoritesOnly;

  bool accepts(SavedPlaylist p) =>
      (source == null || p.data.source == source) && (!favoritesOnly || p.favorite);
}

final libraryFilterProvider = NotifierProvider<LibraryFilterNotifier, LibraryFilter>(LibraryFilterNotifier.new);

class LibraryFilterNotifier extends Notifier<LibraryFilter> {
  @override
  LibraryFilter build() => const LibraryFilter();
  void all() => state = const LibraryFilter();
  void source(MusicSource s) => state = LibraryFilter(source: s);
  void favorites() => state = const LibraryFilter(favoritesOnly: true);
}

final openPlaylistKeyProvider = NotifierProvider<OpenPlaylistNotifier, String?>(OpenPlaylistNotifier.new);

class OpenPlaylistNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void open(String key) => state = key;
  void close() => state = null;
}
