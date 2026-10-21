import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:media_overlay/services/playlist/playlist_link_service.dart';

final playlistLinkServiceProvider = Provider<PlaylistLinkService>((ref) {
  final service = PlaylistLinkService(
    // Injected at compile time via --dart-define-from-file.
    youtubeApiKey: const String.fromEnvironment('YT_API_KEY'),
  );
  ref.onDispose(service.dispose);
  return service;
});
