import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:media_overlay/core/theme.dart';
import 'package:media_overlay/l10n/app_localizations.dart';
import 'package:media_overlay/models/sona_player_view_model.dart';
import 'package:media_overlay/providers/app_providers.dart';
import 'package:media_overlay/services/artwork_service.dart';
import 'package:media_overlay/services/audio/track_audio_source.dart';

class SonaPlayerBar extends ConsumerWidget {
  const SonaPlayerBar({super.key, this.onLyrics});
  final VoidCallback? onLyrics;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sonaPlayerProvider);
    final t = s.track;
    if (t == null) return const SizedBox.shrink();

    final vm = ref.read(sonaPlayerProvider.notifier);
    final accent = ref.watch(accentColorProvider);
    final cover = ref.watch(trackArtworkProvider(t)).asData?.value;
    final l = AppLocalizations.of(context)!;

    final subtitle = switch (s.phase) {
      PlayerPhase.resolving => l.findingAudio,
      PlayerPhase.error => audioErrorText(l, s.errorKind),
      _ => t.artist,
    };

    // On error, Play retries the same track.
    final VoidCallback onPlay = s.phase == PlayerPhase.error
        ? () => vm.playAt(s.playlist!, s.index)
        : vm.togglePlay;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF181818).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final compact = c.maxWidth < 620;
          return Row(
            children: [
              if (!compact)
                _IconBtn(
                  icon: Icons.shuffle,
                  tooltip: l.shuffle,
                  active: s.shuffle,
                  accent: accent,
                  onTap: vm.toggleShuffle,
                ),
              _IconBtn(
                icon: Icons.skip_previous_rounded,
                tooltip: l.previousTrack,
                accent: accent,
                onTap: vm.previous,
              ),
              _PlayButton(
                phase: s.phase,
                tooltip: s.phase == PlayerPhase.playing ? l.pause : l.play,
                accent: accent,
                onTap: onPlay,
              ),
              _IconBtn(
                icon: Icons.skip_next_rounded,
                tooltip: l.nextTrack,
                accent: accent,
                onTap: vm.next,
              ),
              if (!compact)
                _IconBtn(
                  icon: s.loop == LoopMode.one ? Icons.repeat_one : Icons.repeat,
                  tooltip: s.loop == LoopMode.one ? l.repeatOne : l.repeat,
                  active: s.loop != LoopMode.off,
                  accent: accent,
                  onTap: vm.cycleLoop,
                ),
              const SizedBox(width: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: _Cover(url: cover, size: 44),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: s.phase == PlayerPhase.error
                            ? ThemeColors.error
                            : Colors.white60,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 12,
                      child: _WaveProgress(
                        accent: accent,
                        playing: s.phase == PlayerPhase.playing,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (onLyrics != null)
                _IconBtn(
                  icon: Icons.lyrics_outlined,
                  accent: accent,
                  onTap: onLyrics!,
                ),
              if (!compact) _VolumeControl(accent: accent),
              // Without this there's no way back to the system player bar.
              _IconBtn(
                icon: Icons.close_rounded,
                tooltip: l.stopPlayback,
                accent: accent,
                onTap: vm.stop,
              ),
            ],
          );
        },
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
    color: active ? accent : Colors.white70,
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
    // Dark or light text/icon depending on accent luminance.
    final onAccent = accent.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;
    final resolving = phase == PlayerPhase.resolving;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: accent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: resolving ? null : onTap,
            child: SizedBox.square(
              dimension: 38,
              child: resolving
                  ? Padding(
                      padding: const EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: onAccent,
                      ),
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
    );
  }
}

class _VolumeControl extends ConsumerWidget {
  const _VolumeControl({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = (ref.watch(sonaVolumeProvider).asData?.value ?? 1.0).clamp(
      0.0,
      1.0,
    );
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
          color: Colors.white70,
        ),
        SizedBox(
          width: 90,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape: SliderComponentShape.noOverlay,
              activeTrackColor: accent,
              thumbColor: accent,
              inactiveTrackColor: Colors.white24,
            ),
            child: Slider(min: 0, max: 1, value: v, onChanged: vm.setVolume),
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
      color: Colors.white10,
      child: Icon(Icons.music_note, size: size * 0.45, color: Colors.white38),
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
          ..color = Colors.white24
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
