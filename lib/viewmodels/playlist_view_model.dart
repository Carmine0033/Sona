import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:media_overlay/models/playlist.dart';
import 'package:media_overlay/services/playlist/playlist_link_service.dart';
import 'package:media_overlay/services/settings_service.dart';

final playlistLinkServiceProvider = Provider<PlaylistLinkService>((ref) {
  final service = PlaylistLinkService(
    // Injected at compile time via --dart-define-from-file (see below).
    youtubeApiKey: const String.fromEnvironment('YT_API_KEY'),
  );
  ref.onDispose(service.dispose);
  return service;
});

final playlistViewModelProvider =
    AsyncNotifierProvider<PlaylistViewModel, PlaylistData?>(PlaylistViewModel.new);

class PlaylistViewModel extends AsyncNotifier<PlaylistData?> {
  static const _prefKey = 'lastPlaylistUrl';
  int _request = 0;

  @override
  Future<PlaylistData?> build() async {
    final last = SettingsService.getString(_prefKey);
    if (last == null || last.isEmpty) return null;
    try {
      return await ref.watch(playlistLinkServiceProvider).load(last);
    } catch (_) {
      return null;
    }
  }

  Future<void> load(String link) async {
    final req = ++_request;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(playlistLinkServiceProvider).load(link),
    );
    if (req != _request) return;
    state = result;
    if (result.hasValue) SettingsService.setString(_prefKey, link.trim());
  }

  void clear() {
    _request++;
    state = const AsyncData(null);
    SettingsService.remove(_prefKey);
  }
}