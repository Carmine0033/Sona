import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:media_overlay/models/sona_player_view_model.dart';
import 'package:media_overlay/providers/app_providers.dart';
import 'package:media_overlay/services/lyrics_service.dart';
import 'package:media_overlay/services/settings_service.dart';

enum LyricsStyle { karaoke, focus, compact, twoLines, hidden }

enum LyricsSize { small, medium, large }

T _at<T>(List<T> values, int i) =>
    (i >= 0 && i < values.length) ? values[i] : values[0];

final lyricsStylePlayerProvider = StateProvider<LyricsStyle>(
  (ref) =>
      _at(LyricsStyle.values, SettingsService.getInt('lyricsStylePlayer', 0)),
  name: 'lyricsStylePlayer',
);
final lyricsStylePlaylistProvider = StateProvider<LyricsStyle>(
  (ref) =>
      _at(LyricsStyle.values, SettingsService.getInt('lyricsStylePlaylist', 0)),
  name: 'lyricsStylePlaylist',
);
final lyricsStyleMiniProvider = StateProvider<LyricsStyle>(
  (ref) => _at(
    LyricsStyle.values,
    SettingsService.getInt('lyricsStyleMini', LyricsStyle.twoLines.index),
  ),
  name: 'lyricsStyleMini',
);

/// Lyrics offset in ms (−1000…+1000). Positive = lines show earlier.
final lyricsOffsetProvider = StateProvider<int>(
  (ref) => SettingsService.getInt('lyricsOffset', 0).clamp(-1000, 1000),
  name: 'lyricsOffset',
);
final lyricsSizeProvider = StateProvider<LyricsSize>(
  (ref) => _at(LyricsSize.values, SettingsService.getInt('lyricsSize', 1)),
  name: 'lyricsSize',
);
final lyricsPanelOpenProvider = StateProvider<bool>(
  (ref) => SettingsService.getBool('lyricsPanel', true),
  name: 'lyricsPanel',
);

class SyncedLine {
  const SyncedLine(this.start, this.text);
  final Duration start;
  final String text;
}

class ActiveTrack {
  const ActiveTrack({
    required this.title,
    required this.artist,
    this.album,
    this.duration,
    this.internal = false,
  });
  final String title, artist;
  final String? album;
  final Duration? duration;

  /// Played by Sona: the audio is a YouTube match, not the album track.
  final bool internal;

  // Duration is part of the key: lyrics are picked by length, so they are
  // looked up again once the real length of the stream is known.
  String get key =>
      '${title.toLowerCase()}|${artist.toLowerCase()}|${duration?.inSeconds}';
}

/// Playback position at [at]; extrapolated while playing.
class PlaybackClock {
  const PlaybackClock({
    required this.anchor,
    required this.at,
    required this.playing,
  });
  final Duration anchor;
  final DateTime at;
  final bool playing;

  Duration now() => playing ? anchor + DateTime.now().difference(at) : anchor;

  static final stopped = PlaybackClock(
    anchor: Duration.zero,
    at: DateTime(2000),
    playing: false,
  );
}

// The built-in player wins over SMTC while it has a track loaded.
bool _internalActive(SonaPlayerState s) =>
    s.track != null &&
    (s.phase == PlayerPhase.playing ||
        s.phase == PlayerPhase.paused ||
        s.phase == PlayerPhase.resolving);

final activeTrackProvider = Provider<ActiveTrack?>((ref) {
  final s = ref.watch(sonaPlayerProvider);
  if (_internalActive(s)) {
    final t = s.track!;
    // The playlist's duration is the album track's; the stream can differ
    // (music videos have longer intros), so wait for the real one.
    final real = ref.watch(sonaDurationProvider).asData?.value;
    return ActiveTrack(
      title: t.title,
      artist: t.artist,
      album: t.album,
      duration: real != null && real > Duration.zero ? real : null,
      internal: true,
    );
  }
  final np = ref.watch(nowPlayingProvider).asData?.value;
  if (np == null || np.title.isEmpty) return null;
  return ActiveTrack(
    title: np.title,
    artist: np.artist,
    album: np.album,
    duration: np.duration,
  );
});

final playbackClockProvider = Provider<PlaybackClock>((ref) {
  final s = ref.watch(sonaPlayerProvider);
  if (_internalActive(s)) {
    final pos = ref.watch(sonaPositionProvider).asData?.value ?? Duration.zero;
    return PlaybackClock(
      anchor: pos,
      at: DateTime.now(),
      playing: s.phase == PlayerPhase.playing,
    );
  }
  final np = ref.watch(nowPlayingProvider).asData?.value;
  if (np == null) return PlaybackClock.stopped;
  // SMTC positions are as of capturedAt, not of when they reach us.
  return PlaybackClock(
    anchor: np.position,
    at: np.capturedAt,
    playing: np.isPlaying,
  );
});

final activeLyricsProvider = FutureProvider<List<SyncedLine>?>((ref) async {
  final key = ref.watch(activeTrackProvider.select((t) => t?.key));
  if (key == null) return null;
  final t = ref.read(activeTrackProvider)!;
  // Stay in "looking for lyrics" until the stream reports its length.
  if (t.internal && t.duration == null) return Completer<List<SyncedLine>?>().future;

  final lines = await LyricsService.fetchSynced(
    t.artist,
    t.title,
    t.album ?? '',
    t.duration?.inSeconds ?? 0,
  );
  if (lines.isEmpty) return null;
  return [for (final l in lines) SyncedLine(l.time, l.text)];
});

void seekLyrics(WidgetRef ref, Duration to) {
  if (_internalActive(ref.read(sonaPlayerProvider))) {
    ref.read(sonaPlayerProvider.notifier).seek(to);
  } else {
    ref.read(playbackControllerProvider).seek(to);
  }
}
