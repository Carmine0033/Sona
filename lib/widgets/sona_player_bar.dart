import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:media_overlay/core/theme.dart' show formatDuration, tabularFigures;
import 'package:media_overlay/l10n/app_localizations.dart';
import 'package:media_overlay/models/sona_player_view_model.dart';
import 'package:media_overlay/providers/app_providers.dart';
import 'package:media_overlay/services/artwork_service.dart';
import 'package:media_overlay/services/audio/track_audio_source.dart';
import 'package:media_overlay/theme/sona_tokens.dart';

/// Space scrollable content must leave at the bottom while the floating
/// bar is visible: bar height plus its distance from the window edge.
const kPlayerBarReserve = 112.0;

/// Floating glass player bar for the internal player (see mock/code.html):
/// track on the left, controls and progress in the center, volume on the right.
class SonaPlayerBar extends ConsumerWidget {
  const SonaPlayerBar({super.key, this.onLyrics});
  final VoidCallback? onLyrics;

  static final _radius = BorderRadius.circular(18);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sonaPlayerProvider);
    final t = s.track;
    if (t == null) return const SizedBox.shrink();

    final vm = ref.read(sonaPlayerProvider.notifier);
    final accent = ref.watch(accentColorProvider);
    final light = SonaColors.light(accent);
    final cover = ref.watch(trackArtworkProvider(t)).asData?.value;
    final l = AppLocalizations.of(context)!;
    final playing = s.phase == PlayerPhase.playing;

    final subtitle = switch (s.phase) {
      PlayerPhase.resolving => l.findingAudio,
      PlayerPhase.error => audioErrorText(l, s.errorKind),
      _ => t.album == null || t.album!.isEmpty ? t.artist : '${t.artist} — ${t.album}',
    };

    // On error, Play retries the same track.
    final VoidCallback onPlay = s.phase == PlayerPhase.error
        ? () => vm.playAt(s.playlist!, s.index)
        : vm.togglePlay;

    Widget track({required bool compact}) => Row(children: [
          DecoratedBox(
            decoration: const BoxDecoration(
              boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 10)],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: _Cover(url: cover, size: 48),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: SonaText.titleMd),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SonaText.bodySm.copyWith(
                    color: s.phase == PlayerPhase.error ? SonaColors.error : SonaColors.textMid,
                  ),
                ),
                if (compact) ...[
                  const SizedBox(height: 4),
                  SizedBox(height: 12, child: _WaveProgress(accent: accent, playing: playing)),
                ],
              ],
            ),
          ),
        ]);

    final controls = Row(mainAxisSize: MainAxisSize.min, children: [
      _IconBtn(
        icon: Icons.shuffle,
        tooltip: l.shuffle,
        active: s.shuffle,
        accent: light,
        onTap: vm.toggleShuffle,
      ),
      _IconBtn(icon: Icons.skip_previous_rounded, tooltip: l.previousTrack, accent: light, onTap: vm.previous),
      _PlayButton(
        phase: s.phase,
        tooltip: playing ? l.pause : l.play,
        accent: accent,
        onTap: onPlay,
      ),
      _IconBtn(icon: Icons.skip_next_rounded, tooltip: l.nextTrack, accent: light, onTap: vm.next),
      _IconBtn(
        icon: s.loop == LoopMode.one ? Icons.repeat_one : Icons.repeat,
        tooltip: s.loop == LoopMode.one ? l.repeatOne : l.repeat,
        active: s.loop != LoopMode.off,
        accent: light,
        onTap: vm.cycleLoop,
      ),
    ]);

    final close = _IconBtn(
      // Without this there's no way back to the system player.
      icon: Icons.close_rounded,
      tooltip: l.stopPlayback,
      accent: light,
      onTap: vm.stop,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: _radius,
        boxShadow: [
          const BoxShadow(color: Colors.black87, blurRadius: 32, offset: Offset(0, 12)),
          BoxShadow(color: accent.withValues(alpha: 0.15), blurRadius: 16),
        ],
      ),
      child: ClipRRect(
        borderRadius: _radius,
        // The clip limits the blur to the bar: without it BackdropFilter
        // would blur the whole window (and cost a lot of GPU).
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: SonaColors.surfaceLow.withValues(alpha: 0.72),
              borderRadius: _radius,
              border: Border.all(color: SonaColors.specular),
            ),
            child: LayoutBuilder(builder: (context, c) {
              if (c.maxWidth < 720) {
                // Narrow: track + essential controls on one line.
                return Row(children: [
                  Expanded(child: track(compact: true)),
                  const SizedBox(width: 8),
                  _IconBtn(icon: Icons.skip_previous_rounded, tooltip: l.previousTrack, accent: light, onTap: vm.previous),
                  _PlayButton(phase: s.phase, tooltip: playing ? l.pause : l.play, accent: accent, onTap: onPlay),
                  _IconBtn(icon: Icons.skip_next_rounded, tooltip: l.nextTrack, accent: light, onTap: vm.next),
                  close,
                ]);
              }
              final side = c.maxWidth * 0.27;
              return Row(children: [
                SizedBox(width: side, child: track(compact: false)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    controls,
                    const SizedBox(height: 2),
                    Row(children: [
                      const _TimeLabel(total: false),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(height: 12, child: _WaveProgress(accent: accent, playing: playing)),
                      ),
                      const SizedBox(width: 10),
                      const _TimeLabel(total: true),
                    ]),
                  ]),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: side,
                  child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    if (onLyrics != null)
                      _IconBtn(icon: Icons.lyrics_outlined, accent: light, onTap: onLyrics!),
                    Flexible(child: _VolumeControl(accent: accent, light: light)),
                    close,
                  ]),
                ),
              ]);
            }),
          ),
        ),
      ),
    );
  }
}

String audioErrorText(AppLocalizations l, AudioErrorKind? k) => switch (k) {
  AudioErrorKind.blocked => l.audioErrorBlocked,
  AudioErrorKind.noMatch => l.audioErrorNoMatch,
  AudioErrorKind.unavailable => l.audioErrorUnavailable,
  AudioErrorKind.network => l.audioErrorNetwork,
  AudioErrorKind.playback || null => l.audioErrorPlayback,
};

class _IconBtn extends StatelessWidget {
  const _IconBtn({
    required this.icon,
    required this.accent,
    required this.onTap,
    this.tooltip,
    this.active = false,
  });
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  final String? tooltip;
  final bool active;

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onTap,
    tooltip: tooltip,
    icon: Icon(icon, size: 20),
    color: active ? accent : SonaColors.textMid,
    hoverColor: Colors.white.withValues(alpha: 0.06),
    visualDensity: VisualDensity.compact,
  );
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.phase,
    required this.tooltip,
    required this.accent,
    required this.onTap,
  });
  final PlayerPhase phase;
  final String tooltip;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Dark or light icon depending on accent luminance.
    final onAccent = accent.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    final resolving = phase == PlayerPhase.resolving;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Tooltip(
        message: tooltip,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.6), blurRadius: 14)],
          ),
          child: Material(
            color: accent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: resolving ? null : onTap,
              child: SizedBox.square(
                dimension: 40,
                child: resolving
                    ? Padding(
                        padding: const EdgeInsets.all(11),
                        child: CircularProgressIndicator(strokeWidth: 2, color: onAccent),
                      )
                    : Icon(
                        phase == PlayerPhase.playing
                            ? Icons.pause_rounded
                            : phase == PlayerPhase.error
                            ? Icons.refresh_rounded
                            : Icons.play_arrow_rounded,
                        color: onAccent,
                        size: 24,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Elapsed or total time next to the progress wave. Only this label
/// rebuilds on every position tick, not the whole bar.
class _TimeLabel extends ConsumerWidget {
  const _TimeLabel({required this.total});
  final bool total;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = total
        ? ref.watch(sonaDurationProvider).asData?.value
        : ref.watch(sonaPositionProvider).asData?.value;
    return Text(
      formatDuration(d ?? Duration.zero),
      style: SonaText.labelSm.copyWith(fontFeatures: tabularFigures),
    );
  }
}

class _VolumeControl extends ConsumerWidget {
  const _VolumeControl({required this.accent, required this.light});
  final Color accent, light;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = (ref.watch(sonaVolumeProvider).asData?.value ?? 1.0).clamp(0.0, 1.0);
    final vm = ref.read(sonaPlayerProvider.notifier);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          v == 0
              ? Icons.volume_off
              : v < 0.5
              ? Icons.volume_down
              : Icons.volume_up,
          size: 18,
          color: light,
        ),
        Flexible(
          child: SizedBox(
            width: 96,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                overlayShape: SliderComponentShape.noOverlay,
                activeTrackColor: accent,
                thumbColor: light,
                inactiveTrackColor: SonaColors.surfaceHighest,
              ),
              child: Slider(min: 0, max: 1, value: v, onChanged: vm.setVolume),
            ),
          ),
        ),
      ],
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.url, required this.size});
  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ph = Container(
      width: size,
      height: size,
      color: SonaColors.surfaceHigh,
      child: Icon(Icons.music_note, size: size * 0.45, color: SonaColors.textMuted),
    );
    if (url == null) return ph;
    return Image.network(
      url!,
      width: size,
      height: size,
      fit: BoxFit.cover,
      cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
      errorBuilder: (_, _, _) => ph,
    );
  }
}

class _WaveProgress extends ConsumerStatefulWidget {
  const _WaveProgress({required this.accent, required this.playing});
  final Color accent;
  final bool playing;

  @override
  ConsumerState<_WaveProgress> createState() => _WaveProgressState();
}

class _WaveProgressState extends ConsumerState<_WaveProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _phase = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  double? _dragFraction;

  @override
  void initState() {
    super.initState();
    if (widget.playing) _phase.repeat();
  }

  @override
  void didUpdateWidget(_WaveProgress old) {
    super.didUpdateWidget(old);
    if (widget.playing && !_phase.isAnimating) _phase.repeat();
    if (!widget.playing && _phase.isAnimating) _phase.stop();
  }

  @override
  void dispose() {
    _phase.dispose();
    super.dispose();
  }

  void _seekTo(double fraction, Duration dur) {
    if (dur <= Duration.zero) return; // duration unknown yet: no seek
    ref
        .read(sonaPlayerProvider.notifier)
        .seek(Duration(milliseconds: (dur.inMilliseconds * fraction).round()));
  }

  @override
  Widget build(BuildContext context) {
    final pos = ref.watch(sonaPositionProvider).asData?.value ?? Duration.zero;
    final dur = ref.watch(sonaDurationProvider).asData?.value ?? Duration.zero;
    final live = dur.inMilliseconds > 0
        ? pos.inMilliseconds / dur.inMilliseconds
        : 0.0;
    final progress = (_dragFraction ?? live).clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, c) {
        double frac(double dx) =>
            c.maxWidth > 0 ? (dx / c.maxWidth).clamp(0.0, 1.0) : 0.0;
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => _seekTo(frac(d.localPosition.dx), dur),
            onHorizontalDragUpdate: (d) =>
                setState(() => _dragFraction = frac(d.localPosition.dx)),
            onHorizontalDragEnd: (_) {
              if (_dragFraction != null) _seekTo(_dragFraction!, dur);
              setState(() => _dragFraction = null);
            },
            child: AnimatedBuilder(
              animation: _phase,
              builder: (_, _) => CustomPaint(
                size: Size(c.maxWidth, 12),
                painter: _WavePainter(
                  progress: progress,
                  phase: _phase.value * 2 * math.pi,
                  amplitude: widget.playing ? 2.5 : 0,
                  color: widget.accent,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({
    required this.progress,
    required this.phase,
    required this.amplitude,
    required this.color,
  });
  final double progress, phase, amplitude;
  final Color color;

  static const _wavelength = 14.0;

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    final playedX = size.width * progress;

    // Played part: sine wave in the accent color.
    final played = Path()..moveTo(0, midY);
    for (var x = 0.0; x <= playedX; x += 1.5) {
      played.lineTo(
        x,
        midY + math.sin(x / _wavelength * 2 * math.pi - phase) * amplitude,
      );
    }
    canvas.drawPath(
      played,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // Remaining part: faint straight line.
    if (playedX + 3 < size.width) {
      canvas.drawLine(
        Offset(playedX + 3, midY),
        Offset(size.width, midY),
        Paint()
          ..color = SonaColors.surfaceHighest
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_WavePainter o) =>
      o.progress != progress ||
      o.phase != phase ||
      o.amplitude != amplitude ||
      o.color != color;
}
