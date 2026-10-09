import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/now_playing.dart';
import '../providers/app_providers.dart';

class SeekBar extends ConsumerStatefulWidget {
  const SeekBar({super.key});

  @override
  ConsumerState<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends ConsumerState<SeekBar>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  Duration _base = Duration.zero;
  Duration _duration = Duration.zero;
  DateTime _anchor = DateTime.now();
  bool _playing = false;
  double _speed = 1.0;

  bool _dragging = false;
  double _dragFraction = 0.0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) {
      // ridisegna mentre suona: fa avanzare sia la posizione sia l'onda
      if (_playing && !_dragging) setState(() {});
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _sync(NowPlaying info) {
    _base = info.position;
    _duration = info.duration;
    _anchor = DateTime.now();
    _playing = info.isPlaying;
    _speed = 1.0;
  }

  Duration get _estimated {
    if (!_playing) return _base;
    final elapsed = DateTime.now().difference(_anchor);
    final est = _base + elapsed * _speed;
    if (est > _duration) return _duration;
    if (est < Duration.zero) return Duration.zero;
    return est;
  }

  Future<void> _commitSeek(double fraction) async {
    final target = _duration * fraction;
    final ok = await ref.read(playbackControllerProvider).seek(target);
    setState(() {
      _dragging = false;
      if (ok) {
        _base = target;
        _anchor = DateTime.now();
      }
    });
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString();
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(nowPlayingProvider, (prev, next) {
      final info = next.asData?.value;
      if (info != null) setState(() => _sync(info));
    });

    final style = ref.watch(seekBarStyleProvider);

    final pos = _dragging ? _duration * _dragFraction : _estimated;
    final fraction = _duration.inMilliseconds == 0
        ? 0.0
        : (pos.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        style == SeekBarStyle.wave ? _buildWave(fraction) : _buildLine(fraction),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_fmt(pos),
                  style: const TextStyle(color: Colors.white70, fontSize: 11)),
              Text(_fmt(_duration),
                  style: const TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLine(double fraction) {
    final accent = Theme.of(context).colorScheme.primary;
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
        activeTrackColor: accent,
        inactiveTrackColor: Colors.white24,
        thumbColor: accent,
      ),
      child: Slider(
        value: fraction,
        onChangeStart: (_) => setState(() => _dragging = true),
        onChanged: (v) => setState(() => _dragFraction = v),
        onChangeEnd: _commitSeek,
      ),
    );
  }

  Widget _buildWave(double fraction) {
    final accent = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: LayoutBuilder(builder: (context, c) {
        final width = c.maxWidth;
        final phase = DateTime.now().millisecondsSinceEpoch / 1000.0 * 3.0;
        final amplitude = _playing ? 4.0 : 1.0; // ampiezza bilanciata per la card

        void setFromX(double dx) =>
            setState(() => _dragFraction = (dx / width).clamp(0.0, 1.0));

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (_) => setState(() => _dragging = true),
          onHorizontalDragUpdate: (d) => setFromX(d.localPosition.dx),
          onHorizontalDragEnd: (_) => _commitSeek(_dragFraction),
          onTapDown: (d) {
            setState(() => _dragging = true);
            setFromX(d.localPosition.dx);
          },
          onTapUp: (_) => _commitSeek(_dragFraction),
          child: SizedBox(
            height: 22,
            width: double.infinity,
            child: CustomPaint(
              painter: _WavePainter(
                progress: _dragging ? _dragFraction : fraction,
                phase: phase,
                amplitude: amplitude,
                played: accent,
                remaining: Colors.white24,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double progress;
  final double phase;
  final double amplitude;
  final Color played;
  final Color remaining;

  _WavePainter({
    required this.progress,
    required this.phase,
    required this.amplitude,
    required this.played,
    required this.remaining,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    const waves = 7.0; // numero di "gobbe" sulla larghezza
    final k = (2 * math.pi * waves) / size.width;
    final progressX = (progress * size.width).clamp(0.0, size.width);

    final playedPaint = Paint()
      ..color = played
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final remPaint = Paint()
      ..color = remaining
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final playedPath = Path();
    final remPath = Path();
    bool sp = false, sr = false;
    for (double x = 0; x <= size.width; x += 1.5) {
      final y = midY + amplitude * math.sin(x * k + phase);
      if (x <= progressX) {
        sp ? playedPath.lineTo(x, y) : playedPath.moveTo(x, y);
        sp = true;
      } else {
        sr ? remPath.lineTo(x, y) : remPath.moveTo(x, y);
        sr = true;
      }
    }
    canvas.drawPath(remPath, remPaint);
    canvas.drawPath(playedPath, playedPaint);

    final thumbY = midY + amplitude * math.sin(progressX * k + phase);
    canvas.drawCircle(Offset(progressX, thumbY), 4, Paint()..color = played);
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) =>
      old.progress != progress ||
      old.phase != phase ||
      old.amplitude != amplitude;
}