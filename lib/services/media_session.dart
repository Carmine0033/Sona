import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/now_playing.dart';
import '../models/sona_player_view_model.dart';
import '../providers/app_providers.dart';

/// Channel to windows/runner/media_session.cpp: publishes internal
/// playback to Windows media controls and receives their commands.
class MediaSessionChannel {
  MediaSessionChannel([MethodChannel? channel])
    : _ch = channel ?? const MethodChannel('sona/media_session');
  final MethodChannel _ch;

  /// [artwork]: pass [keepArtwork] to leave the cover unchanged
  /// (avoids resending bytes on every play/pause).
  Future<void> update(
    NowPlaying n, {
    required bool hasNext,
    Object? artwork = keepArtwork,
  }) => _call('update', {
    'title': n.title,
    'artist': n.artist,
    'album': n.album,
    'isPlaying': n.isPlaying,
    'positionMs': n.position.inMilliseconds,
    'durationMs': n.duration.inMilliseconds,
    'hasNext': hasNext,
    if (!identical(artwork, keepArtwork)) 'artwork': artwork as Uint8List?,
  });

  Future<void> clear() => _call('clear');

  void setHandler(Future<void> Function(MethodCall call)? handler) =>
      _ch.setMethodCallHandler(handler);

  Future<void> _call(String method, [Object? args]) async {
    try {
      await _ch.invokeMethod<void>(method, args);
    } on MissingPluginException {
      // mini player process: no session to update
    }
  }

  static const keepArtwork = Object();
}

final mediaSessionChannelProvider = Provider<MediaSessionChannel>(
  (ref) => MediaSessionChannel(),
);

/// Keep alive in the main window (SonaApp). Syncs Windows media
/// controls with the internal player and runs their commands (media
/// keys, volume flyout, detached mini player).
final sonaMediaSessionProvider = Provider<void>((ref) {
  final channel = ref.watch(mediaSessionChannelProvider);
  var published = false;
  Uint8List? sentArtwork;

  void sync(NowPlaying? n) {
    if (n == null) {
      if (published) channel.clear();
      published = false;
      sentArtwork = null;
      return;
    }
    final artChanged = !published || !identical(n.artwork, sentArtwork);
    published = true;
    sentArtwork = n.artwork;
    channel.update(
      n,
      hasNext: ref.read(sonaPlayerProvider.notifier).canGoNext,
      artwork: artChanged ? n.artwork : MediaSessionChannel.keepArtwork,
    );
  }

  ref.listen<NowPlaying?>(
    sonaNowPlayingProvider,
    (_, n) => sync(n),
    fireImmediately: true,
  );
  // shuffle/repeat change whether "next" is available
  ref.listen(
    sonaPlayerProvider.select((s) => (s.shuffle, s.loop, s.index)),
    (_, _) => sync(ref.read(sonaNowPlayingProvider)),
  );

  channel.setHandler((call) async {
    final vm = ref.read(sonaPlayerProvider.notifier);
    if (ref.read(sonaPlayerProvider).phase == PlayerPhase.idle) return;
    switch (call.method) {
      case 'button':
        switch (call.arguments) {
          case 'play':
            await vm.play();
          case 'pause':
            await vm.pause();
          case 'next':
            await vm.next();
          case 'previous':
            await vm.previous();
          case 'stop':
            await vm.stop();
        }
      case 'seek':
        final ms = call.arguments;
        if (ms is int) await vm.seek(Duration(milliseconds: ms));
    }
  });

  ref.onDispose(() {
    channel.setHandler(null);
    if (published) channel.clear();
  });
});
