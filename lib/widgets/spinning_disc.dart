import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import 'dart:io';

class SpinningDisc extends ConsumerStatefulWidget {
  final Uint8List? albumArt;
  final bool spinning;
  final double size;

  const SpinningDisc({
    super.key,
    required this.albumArt,
    required this.spinning,
    this.size = 185,
  });

  @override
  ConsumerState<SpinningDisc> createState() => _SpinningDiscState();
}

class _SpinningDiscState extends ConsumerState<SpinningDisc>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotation; // giro del disco

  @override
  void initState() {
    super.initState();
    _rotation = AnimationController(
        vsync: this, duration: const Duration(seconds: 8));
    _applySpinning();
  }

  void _applySpinning() {
    if (widget.spinning) {
      if (!_rotation.isAnimating) _rotation.repeat();
    } else {
      _rotation.stop();
    }
  }

  @override
  void didUpdateWidget(SpinningDisc old) {
    super.didUpdateWidget(old);
    if (old.spinning != widget.spinning) _applySpinning();
  }

  @override
  void dispose() {
    _rotation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = ref.watch(discStyleProvider);
    switch (style) {
      case DiscStyle.vinyl:
        return _buildVinyl(context);
      case DiscStyle.fullAlbum:
        return _buildFullAlbum(context);
    }
  }

  bool get _hasArt => widget.albumArt != null && widget.albumArt!.isNotEmpty;

  Widget _fallback() => Container(
        color: const Color(0xFF1C1C1C),
        child: const Icon(Icons.music_note, color: Colors.white38, size: 30),
      );

  Widget _art({BoxFit fit = BoxFit.cover}) {
    final custom = ref.watch(customMediaPathProvider);
    if (custom != null) {
      return Image.file(
        File(custom),
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => _fallback(),
      );
    }
    return _hasArt
        ? Image.memory(widget.albumArt!,
            fit: fit, errorBuilder: (_, _, _) => _fallback())
        : _fallback();
  }

  //Vynil + Album
  Widget _buildVinyl(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final s = widget.size;
    final labelD = s * 0.42;
    final holeD = s * 0.035;
    return RotationTransition(
      turns: _rotation,
      child: Container(
        width: s,
        height: s,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.22),
              blurRadius: 24,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(size: Size(s, s), painter: _VinylPainter()),
            Container(
              width: labelD,
              height: labelD,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: accent.withValues(alpha: 0.55), width: 2),
              ),
              child: ClipOval(child: _art()),
            ),
            Container(
              width: holeD,
              height: holeD,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0A0A0A),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15), width: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //Full album
  Widget _buildFullAlbum(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final s = widget.size;
    return RotationTransition(
      turns: _rotation,
      child: Container(
        width: s,
        height: s,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.25),
              blurRadius: 24,
              spreadRadius: 2,
            ),
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                spreadRadius: 2),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipOval(child: SizedBox(width: s, height: s, child: _art())),
            // forellino centrale per mantenere il "feel" da disco
            Container(
              width: s * 0.05,
              height: s * 0.05,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xCC0A0A0A),
                border: Border.all(
                    color: accent.withValues(alpha: 0.4), width: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Vinile: base nera + scanalature
class _VinylPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final labelR = r * 0.42;

    canvas.drawCircle(center, r, Paint()..color = const Color(0xFF0B0B0B));
    canvas.drawCircle(
        center,
        r,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.35, -0.45),
            radius: 1.1,
            colors: [Colors.white.withValues(alpha: 0.12), Colors.transparent],
          ).createShader(Rect.fromCircle(center: center, radius: r)));

    final groove = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    int i = 0;
    for (double rr = labelR + 4; rr < r - 3; rr += 3) {
      groove.color = Colors.white.withValues(alpha: i.isEven ? 0.05 : 0.02);
      canvas.drawCircle(center, rr, groove);
      i++;
    }
    canvas.drawCircle(
        center,
        r - 1,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = Colors.white.withValues(alpha: 0.10));
  }

  @override
  bool shouldRepaint(covariant _VinylPainter old) => false;
}