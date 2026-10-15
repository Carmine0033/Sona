import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';

import 'package:media_overlay/models/playlist.dart';
import 'package:media_overlay/services/audio/track_audio_source.dart';
import 'package:media_overlay/services/audio/youtube_audio_source.dart';

enum PlayerPhase { idle, resolving, playing, paused, error }

// Not "RepeatMode": that name clashes with Flutter's material.dart.
enum LoopMode { off, all, one }

class SonaPlayerState {
  const SonaPlayerState({
    this.phase = PlayerPhase.idle,
    this.playlist,
    this.index = -1,
    this.errorKind,
    this.shuffle = false,
    this.loop = LoopMode.off,
  });

  final PlayerPhase phase;
  final PlaylistData? playlist;
  final int index;
  final AudioErrorKind? errorKind;
  final bool shuffle;
  final LoopMode loop;

  PlaylistTrack? get track =>
      (playlist != null && index >= 0 && index < playlist!.tracks.length)
      ? playlist!.tracks[index]
      : null;

  /// [errorKind] is reset on every copyWith unless passed explicitly.
  SonaPlayerState copyWith({
    PlayerPhase? phase,
    PlaylistData? playlist,
    int? index,
    AudioErrorKind? errorKind,
    bool? shuffle,
    LoopMode? loop,
  }) => SonaPlayerState(
    phase: phase ?? this.phase,
    playlist: playlist ?? this.playlist,
    index: index ?? this.index,
    errorKind: errorKind,
    shuffle: shuffle ?? this.shuffle,
    loop: loop ?? this.loop,
  );
}

final sonaPlayerProvider =
    NotifierProvider<SonaPlayerViewModel, SonaPlayerState>(
      SonaPlayerViewModel.new,
    );

/// Current position of the internal player.
final sonaPositionProvider = StreamProvider<Duration>((ref) {
  final player = ref.watch(sonaPlayerProvider.notifier).player;
  return player.stream.position;
});

final sonaDurationProvider = StreamProvider<Duration>((ref) {
  final player = ref.watch(sonaPlayerProvider.notifier).player;
  return player.stream.duration;
});

/// Internal player volume, 0..1 (media_kit uses 0..100).
final sonaVolumeProvider = StreamProvider<double>((ref) {
  final player = ref.watch(sonaPlayerProvider.notifier).player;
  return player.stream.volume.map((v) => v / 100);
});

class SonaPlayerViewModel extends Notifier<SonaPlayerState> {
  SonaPlayerViewModel({Player Function()? createPlayer, TrackAudioSource? source})
    : _createPlayer = createPlayer,
      _injectedSource = source;

  final Player Function()? _createPlayer;
  final TrackAudioSource? _injectedSource;

  Player? _player;
  TrackAudioSource? _source;
  final _subs = <StreamSubscription<Object?>>[];
  int _request = 0;
  Future<ResolvedAudio?>? _prefetch;
  PlaylistData? _prefetchPlaylist;
  int _prefetchIndex = -1;
  DateTime? _prefetchAt;
  List<int> _order = [];
  int _orderPos = 0;

  Player get player => _player!;
  static const _prefetchTtl = Duration(minutes: 30);

  @override
  SonaPlayerState build() {
    final p = _player = _createPlayer?.call() ?? _defaultPlayer();
    _source = _injectedSource ?? YouTubeAudioSource();

    _subs
      ..add(
        // Single track-end listener: next(auto) handles repeat,
        // shuffle and the end of the playlist.
        p.stream.completed.listen((done) {
          if (done) next(auto: true);
        }),
      )
      ..add(
        p.stream.playing.listen((playing) {
          if (state.phase == PlayerPhase.playing ||
              state.phase == PlayerPhase.paused) {
            state = state.copyWith(
              phase: playing ? PlayerPhase.playing : PlayerPhase.paused,
            );
          }
        }),
      )
      ..add(
        p.stream.error.listen((_) {
          state = state.copyWith(
            phase: PlayerPhase.error,
            errorKind: AudioErrorKind.playback,
          );
        }),
      );

    ref.onDispose(() {
      for (final s in _subs) {
        s.cancel();
      }
      _subs.clear();
      _player?.dispose();
      _source?.dispose();
    });
    return const SonaPlayerState();
  }

  static Player _defaultPlayer() {
    final p = Player();
    final native = p.platform;
    if (native is NativePlayer) {
      native.setProperty(
        'user-agent',
        'com.google.android.youtube/19.09.37 (Linux; U; Android 11) gzip',
      );
      // The YouTube stream is mp4 with video (itag 18): play audio only.
      native.setProperty('vid', 'no');
    }
    return p;
  }

  /// Index of the next track, or null at the end of the playlist.
  /// [auto]: the track ended on its own (only then repeat-one applies).
  int? _peekNext({required bool auto}) {
    final p = state.playlist;
    if (p == null || p.tracks.isEmpty) return null;
    if (auto && state.loop == LoopMode.one) return state.index;
    if (state.shuffle && _order.isNotEmpty) {
      if (_orderPos + 1 < _order.length) return _order[_orderPos + 1];
      return state.loop == LoopMode.all ? _order.first : null;
    }
    final n = state.index + 1;
    if (n < p.tracks.length) return n;
    return state.loop == LoopMode.all ? 0 : null;
  }

  /// Shuffled order with the current track first.
  void _rebuildOrder(int current) {
    final n = state.playlist?.tracks.length ?? 0;
    final rest = [
      for (var i = 0; i < n; i++)
        if (i != current) i,
    ]..shuffle();
    _order = [if (current >= 0 && current < n) current, ...rest];
    _orderPos = 0;
  }

  Future<void> playAt(PlaylistData playlist, int index) async {
    if (index < 0 || index >= playlist.tracks.length) return;
    final changed = !identical(state.playlist, playlist);
    state = state.copyWith(playlist: playlist, index: index);
    if (state.shuffle || changed) _rebuildOrder(index);
    await _play(playlist, index);
  }

  Future<void> _play(PlaylistData playlist, int index) async {
    if (index < 0 || index >= playlist.tracks.length) return;
    final req = ++_request;
    state = state.copyWith(
      phase: PlayerPhase.resolving,
      playlist: playlist,
      index: index,
    );
    try {
      final audio =
          await _takePrefetch(playlist, index) ??
          await _source!.resolve(playlist.tracks[index]);
      if (req != _request) return;
      await player.open(
        Media(audio.url.toString(), httpHeaders: audio.headers),
      );
      if (req != _request) return;
      state = state.copyWith(phase: PlayerPhase.playing);
      _prefetchNext(playlist);
    } on AudioResolveException catch (e) {
      if (req != _request) return;
      state = state.copyWith(phase: PlayerPhase.error, errorKind: e.kind);
    } catch (_) {
      if (req != _request) return;
      state = state.copyWith(
        phase: PlayerPhase.error,
        errorKind: AudioErrorKind.network,
      );
    }
  }

  Future<void> next({bool auto = false}) async {
    final p = state.playlist;
    final target = _peekNext(auto: auto);
    if (p == null || target == null) {
      if (auto) state = state.copyWith(phase: PlayerPhase.paused); // end of playlist
      return;
    }
    // Repeat one: the stream is already open, just rewind.
    if (auto && target == state.index && state.loop == LoopMode.one) {
      await player.seek(Duration.zero);
      await player.play();
      return;
    }
    if (state.shuffle && _order.isNotEmpty) {
      _orderPos = _orderPos + 1 < _order.length ? _orderPos + 1 : 0;
    }
    await _play(p, target);
  }

  Future<void> previous() async {
    final p = state.playlist;
    if (p == null) return;
    if (player.state.position > const Duration(seconds: 3)) {
      await player.seek(Duration.zero);
      return;
    }
    if (state.shuffle && _order.isNotEmpty) {
      if (_orderPos == 0) {
        await player.seek(Duration.zero);
        return;
      }
      _orderPos--;
      await _play(p, _order[_orderPos]);
    } else if (state.index > 0) {
      await _play(p, state.index - 1);
    } else {
      await player.seek(Duration.zero);
    }
  }

  void toggleShuffle() {
    state = state.copyWith(shuffle: !state.shuffle, errorKind: state.errorKind);
    if (state.shuffle && state.index >= 0) _rebuildOrder(state.index);
    _refreshPrefetch(); // next track changed
  }

  void cycleLoop() {
    final nextMode =
        LoopMode.values[(state.loop.index + 1) % LoopMode.values.length];
    state = state.copyWith(loop: nextMode, errorKind: state.errorKind);
    _refreshPrefetch();
  }

  void _refreshPrefetch() {
    final p = state.playlist;
    if (p != null && state.index >= 0) _prefetchNext(p);
  }

  void _prefetchNext(PlaylistData playlist) {
    final next = _peekNext(auto: true);
    if (next == null || next == state.index) {
      _prefetch = null; // repeat one: nothing to prefetch
      _prefetchIndex = -1;
      return;
    }
    _prefetchPlaylist = playlist;
    _prefetchIndex = next;
    _prefetchAt = DateTime.now();
    _prefetch = _source!
        .resolve(playlist.tracks[next])
        .then<ResolvedAudio?>(
          (a) => a,
          onError: (Object _) => null,
        );
  }

  /// Prefetched audio if it matches and is still valid, otherwise null.
  Future<ResolvedAudio?> _takePrefetch(PlaylistData playlist, int index) async {
    final ok =
        _prefetch != null &&
        identical(_prefetchPlaylist, playlist) &&
        _prefetchIndex == index &&
        DateTime.now().difference(_prefetchAt!) < _prefetchTtl;
    final future = ok ? _prefetch : null;
    _prefetch = null; // single use
    _prefetchIndex = -1;
    return future == null ? null : await future;
  }

  /// Whether a manual "next" is possible (shuffle and repeat included).
  /// Enables the button in Windows media controls.
  bool get canGoNext => _peekNext(auto: false) != null;

  Future<void> togglePlay() => player.playOrPause();
  Future<void> play() => player.play();
  Future<void> pause() => player.pause();
  Future<void> seek(Duration d) => player.seek(d);
  Future<void> setVolume(double v) =>
      player.setVolume((v * 100).clamp(0.0, 100.0));

  /// Stops playback; shuffle and repeat are kept.
  Future<void> stop() async {
    _request++;
    _prefetch = null;
    _prefetchIndex = -1;
    state = SonaPlayerState(shuffle: state.shuffle, loop: state.loop);
    await player.stop();
  }
}
