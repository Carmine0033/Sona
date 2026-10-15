import 'dart:async';
import 'dart:convert';
import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/now_playing.dart';
import '../models/sona_player_view_model.dart';
import '../providers/app_providers.dart';
import 'artwork_service.dart';

/// Channel to windows/runner/discord_rpc.cpp (Rich Presence over IPC).
class DiscordRpc {
  DiscordRpc({MethodChannel? channel, this.clientId = defaultClientId})
    : _ch = channel ?? const MethodChannel('sona/discord');
  final MethodChannel _ch;
  final String clientId;

  /// Application ID from the Discord Developer Portal. Can also be set at
  /// build time: `--dart-define=DISCORD_CLIENT_ID=...`.
  static const defaultClientId = String.fromEnvironment(
    'DISCORD_CLIENT_ID',
    defaultValue: '1560424909769801768',
  );

  /// Presence stays off while the ID is still the placeholder.
  bool get configured => RegExp(r'^\d+$').hasMatch(clientId);

  Future<void> start() => _call('start', clientId);
  Future<void> set(Map<String, Object?> activity) =>
      _call('setActivity', jsonEncode(activity));
  Future<void> clear() => _call('clear');

  Future<void> _call(String method, [Object? args]) async {
    try {
      await _ch.invokeMethod<void>(method, args);
    } on MissingPluginException {
      // mini player process: the main window owns Discord
    } on PlatformException {
      // presence is optional: never break playback
    }
  }
}

final discordRpcProvider = Provider<DiscordRpc>((ref) => DiscordRpc());

/// Builds the "Listening to" activity for [n]. [now] is epoch ms.
Map<String, Object?> buildDiscordActivity(
  NowPlaying n, {
  required int now,
  required AppLocalizations l10n,
  String? coverUrl,
}) {
  // Discord rejects strings shorter than 2 or longer than 128 chars.
  String clip(String s) => s.length < 2
      ? s.padRight(2)
      : (s.length > 128 ? '${s.substring(0, 125)}...' : s);
  final start = now - n.position.inMilliseconds;
  final album = n.album.trim();
  return {
    'type': 2, // Listening
    'status_display_type': 1, // member list shows the artist
    'details': clip(n.title),
    'state': clip(n.artist.isEmpty ? '—' : n.artist),
    if (n.isPlaying && n.duration > Duration.zero)
      'timestamps': {'start': start, 'end': start + n.duration.inMilliseconds},
    'assets': {
      'large_image': coverUrl ?? 'sona_logo',
      if (album.isNotEmpty) 'large_text': clip(album),
      'small_image': 'sona_logo',
      'small_text': n.isPlaying ? 'Sona' : l10n.discordPaused,
    },
    'buttons': [
      {
        'label': l10n.discordDownload,
        'url': 'https://github.com/Carmine0033/Sona',
      },
    ],
  };
}

AppLocalizations _systemL10n() {
  final code = PlatformDispatcher.instance.locale.languageCode;
  return lookupAppLocalizations(
    AppLocalizations.supportedLocales.any((l) => l.languageCode == code)
        ? Locale(code)
        : const Locale('en'),
  );
}

/// Keep alive in the main window (SonaApp). Publishes what the player
/// shows: the internal playlist if playing, otherwise the SMTC session.
final discordPresenceProvider = Provider<void>((ref) {
  final rpc = ref.watch(discordRpcProvider);
  if (!ref.watch(discordEnabledProvider) || !rpc.configured) return;
  rpc.start();

  Timer? throttle;
  String? lastKey;
  int? lastStart;
  var published = false;
  var gen = 0; // drops pushes superseded while fetching the cover
  var disposed = false;

  Future<String?> cover(NowPlaying n) async {
    if (ref.read(sonaNowPlayingProvider) != null) {
      final url = ref.read(sonaPlayerProvider).track?.artworkUrl;
      if (url != null && url.startsWith('http')) return url;
    }
    try {
      return await ref.read(artworkServiceProvider).find(n.artist, n.title);
    } catch (_) {
      return null; // offline: fall back to the logo
    }
  }

  Future<void> push() async {
    final n = ref.read(nowPlayingProvider).asData?.value;
    if (n == null || n.title.isEmpty) {
      gen++;
      if (published) await rpc.clear();
      published = false;
      lastKey = null;
      lastStart = null;
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final start = now - n.position.inMilliseconds;
    // Duration matters: YouTube reports it after start, and without a new
    // push the time bar would be missing for the whole track.
    final key =
        '${n.title}|${n.artist}|${n.isPlaying}|${n.duration.inSeconds}';
    // While paused the position is frozen and start drifts: not a seek.
    final seeked =
        n.isPlaying && lastStart != null && (start - lastStart!).abs() > 3000;
    if (key == lastKey && !seeked) return;
    lastKey = key;
    lastStart = start;

    final my = ++gen;
    final url = await cover(n);
    if (disposed || my != gen) return;
    published = true;
    await rpc.set(
      buildDiscordActivity(n, now: now, l10n: _systemL10n(), coverUrl: url),
    );
  }

  // At most one push per second; unlike a debounce it is never
  // postponed forever by a steady stream of updates.
  void schedule() {
    throttle ??= Timer(const Duration(seconds: 1), () {
      throttle = null;
      push();
    });
  }

  ref.listen(nowPlayingProvider, (_, _) => schedule());

  ref.onDispose(() {
    disposed = true;
    throttle?.cancel();
    if (published) rpc.clear();
  });
  schedule();
});
