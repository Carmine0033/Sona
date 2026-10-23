import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../core/theme.dart';
import '../models/now_playing.dart';
import '../services/playback_controller.dart';
import '../services/smtc_channel.dart';
import '../services/smtc_playback_controller.dart';
import '../services/sona_playback_controller.dart';
import '../services/artwork_service.dart';
import '../models/sona_player_view_model.dart';
import '../models/lyrics.dart';
import '../services/lyrics_service.dart';
import '../services/update_service.dart';
import '../services/settings_service.dart';
import 'package:flutter/material.dart';

// Preferences

final opaqueBackgroundProvider =
    StateProvider<bool>((ref) => SettingsService.getBool('opaque', false),
        name: 'opaque');


final alwaysOnTopProvider =
    StateProvider<bool>((ref) => SettingsService.getBool('alwaysOnTop', true),
        name: 'alwaysOnTop');

T _enumAt<T>(List<T> values, int i) =>
    (i >= 0 && i < values.length) ? values[i] : values[0];

final discDirectionProvider = StateProvider<int>((ref) => 1);

final seekBarStyleProvider = StateProvider<SeekBarStyle>(
    (ref) => _enumAt(SeekBarStyle.values, SettingsService.getInt('seekStyle', 0)),
    name: 'seekStyle');

final discStyleProvider = StateProvider<DiscStyle>(
    (ref) => _enumAt(DiscStyle.values, SettingsService.getInt('discStyle', 0)),
    name: 'discStyle');

final customMediaPathProvider = StateProvider<String?>(
    (ref) => SettingsService.getString('customMedia'),
    name: 'customMedia');

final accentColorProvider= StateProvider<Color>(
  // The user's saved value wins; Reiatsu Violet is only the default.
  (ref) => Color(
      SettingsService.getInt('accent', ThemeColors.primary.toARGB32())),
  name: 'accent'
);

final detachedProvider = StateProvider<bool>((ref) => false, name: 'detached');


// Two sources, one interface: the internal player while a playlist
// plays, otherwise the system app seen through SMTC.

final playbackControllerProvider= Provider<PlaybackController>((ref) {
  final internal = ref.watch(sonaNowPlayingProvider.select((n) => n != null));
  return internal
      ? SonaPlaybackController(ref.read(sonaPlayerProvider.notifier))
      : SmtcPlaybackController();
});

final nowPlayingProvider = Provider<AsyncValue<NowPlaying?>>((ref) {
  final internal = ref.watch(sonaNowPlayingProvider);
  if (internal != null) return AsyncData(internal);
  return ref.watch(smtcNowPlayingProvider);
});

final smtcNowPlayingProvider= StreamProvider<NowPlaying?>((ref) {
  return SmtcChannel.updates.map((map) {
    if (map == null) return null;
    return NowPlaying.fromMap(map);
  });
});

/// Internal player track in SMTC format; null when stopped.
///
/// Like SMTC, position is a snapshot that screens advance themselves,
/// so this rebuilds only on real changes (track, play/pause, duration,
/// artwork, seek), not on every tick.
final sonaNowPlayingProvider = Provider<NowPlaying?>((ref) {
  final s = ref.watch(sonaPlayerProvider);
  final t = s.track;
  if (s.phase == PlayerPhase.idle || t == null) return null;

  final player = ref.read(sonaPlayerProvider.notifier).player;
  ref.watch(sonaDurationProvider);
  ref.watch(_sonaPositionJumpProvider);
  final art = ref.watch(sonaArtworkBytesProvider).asData?.value;

  final duration = player.state.duration > Duration.zero
      ? player.state.duration
      : (t.duration ?? Duration.zero);
  return NowPlaying(
    title: t.title,
    artist: t.artist,
    album: t.album ?? '',
    isPlaying: s.phase == PlayerPhase.playing,
    // while resolving, the position still belongs to the previous track
    position: s.phase == PlayerPhase.resolving
        ? Duration.zero
        : player.state.position,
    duration: duration,
    artwork: art,
  );
});

/// Emits only on position jumps (seek, rewind, resume).
final _sonaPositionJumpProvider = StreamProvider<Duration>((ref) {
  final player = ref.watch(sonaPlayerProvider.notifier).player;
  Duration? last;
  DateTime? lastAt;
  return player.stream.position.where((p) {
    final now = DateTime.now();
    final expected = last == null ? null : last! + now.difference(lastAt!);
    last = p;
    lastAt = now;
    return expected == null ||
        (p - expected).abs() > const Duration(milliseconds: 1500);
  });
});

/// Internal track artwork as bytes, like SMTC artwork.
final sonaArtworkBytesProvider = FutureProvider<Uint8List?>((ref) async {
  final t = ref.watch(sonaPlayerProvider.select((s) => s.track));
  if (t == null) return null;
  final url = await ref.watch(trackArtworkProvider(t).future);
  if (url == null) return null;
  return ref.read(artworkServiceProvider).fetchBytes(url);
});


// Update check
final updateProvider = FutureProvider<UpdateInfo?>((ref) async {
  return UpdateService.check();
});

final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return info.version;
});

enum AppSection { player, playlist, options }
enum SeekBarStyle { line, wave }
enum DiscStyle { vinyl, fullAlbum }
enum BarBackground { glass, albumBlur, custom }
enum BarIconStyle { filled, outlined, rounded, sharp }

// Player bar customization (see widgets/player_bar_settings.dart).
final barBackgroundProvider = StateProvider<BarBackground>(
  (ref) => _enumAt(BarBackground.values, SettingsService.getInt('barBackground', 0)),
  name: 'barBackground',
);

/// Custom bar image/GIF; null if unset or the file was deleted meanwhile.
final barMediaPathProvider = StateProvider<String?>(
  (ref) {
    final p = SettingsService.getString('barMedia');
    return (p != null && File(p).existsSync()) ? p : null;
  },
  name: 'barMedia',
);

final barDimProvider = StateProvider<int>(
  (ref) => SettingsService.getInt('barDim', 55).clamp(0, 90),
  name: 'barDim',
);

final barIconStyleProvider = StateProvider<BarIconStyle>(
  (ref) => _enumAt(BarIconStyle.values, SettingsService.getInt('barIconStyle', 2)), // default: rounded
  name: 'barIconStyle',
);

final selectedSectionProvider =StateProvider<AppSection>((ref) => AppSection.player);
final settingsOpenProvider = StateProvider<bool>((ref) => false);

enum SettingsSection { appearance, background, playerBar, audio, window, about }
final settingsSectionProvider= StateProvider<SettingsSection>((ref) => SettingsSection.appearance);

class TrackRef {
  final String title, artist, album;
  final int durationSec;
  const TrackRef(this.title, this.artist, this.album, this.durationSec);

  @override
  bool operator ==(Object other) =>
      other is TrackRef &&
      other.title == title &&
      other.artist == artist &&
      other.album == album;

  @override
  int get hashCode => Object.hash(title, artist, album);
}

final trackRefProvider = Provider<TrackRef?>((ref) {
  final np = ref.watch(nowPlayingProvider).asData?.value;
  if (np == null || np.title.isEmpty) return null;
  return TrackRef(np.title, np.artist, np.album, np.duration.inSeconds);
});

final lyricsProvider = FutureProvider<List<LyricLine>>((ref) async {
  final t = ref.watch(trackRefProvider);
  if (t == null) return [];
  return LyricsService.fetchSynced(t.artist, t.title, t.album, t.durationSec);
});

// Discord
final discordEnabledProvider = StateProvider<bool>(
  (ref) => SettingsService.getBool('discordPresence', false),
  name: 'discordPresence',
);