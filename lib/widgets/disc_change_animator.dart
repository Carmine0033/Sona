import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Track change animation around the disc: the old disc leaves, the new
/// sleeve arrives with the disc inside, then slowly slides away.
class DiscChangeAnimator extends StatefulWidget {
  const DiscChangeAnimator({
    super.key,
    required this.trackKey,
    required this.artwork,
    required this.builder,
    this.direction = 1,
  });

  /// Track identity (e.g. "title|artist"): a change starts the animation.
  final String trackKey;

  /// Cover of the current track.
  final ImageProvider? artwork;

  /// 1 = next, -1 = previous: the side the old disc leaves from.
  final int direction;

  /// Builds the disc with the cover to show now, which during the exit
  /// is still the previous track's.
  final Widget Function(BuildContext context, ImageProvider? artwork) builder;

  @override
  State<DiscChangeAnimator> createState() => _DiscChangeAnimatorState();
}

class _DiscChangeAnimatorState extends State<DiscChangeAnimator>
    with SingleTickerProviderStateMixin {
  // Phase boundaries as fractions of the total duration.
  static const _totalMs = 1900.0;
  static const _exitEnd = 300 / _totalMs;   // cover swaps here
  static const _enterEnd = 820 / _totalMs;  // sleeve + disc centred
  static const _slideStart = 1000 / _totalMs; // short pause, then the sleeve slides off

  // No bounce.
  static const _out = Cubic(0.22, 1, 0.36, 1);
  static const _in = Cubic(0.55, 0, 1, 0.45);
  static const _slide = Curves.easeInOutCubic;

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: _totalMs.toInt()),
  )..addListener(_onTick);

  // Set in initState, not `late x = widget.x`: a lazy initializer would first
  // run in didUpdateWidget, already on the new track, missing the change.
  late String _key;
  ImageProvider? _shown;
  ImageProvider? _incoming;
  bool _swapped = true;
  double _dir = 1;

  @override
  void initState() {
    super.initState();
    _key = widget.trackKey;
    _shown = widget.artwork;
  }

  @override
  void didUpdateWidget(DiscChangeAnimator old) {
    super.didUpdateWidget(old);

    if (widget.trackKey != _key) {
      _key = widget.trackKey;
      _incoming = widget.artwork;
      _dir = widget.direction < 0 ? -1 : 1;

      // System "reduce motion": swap instantly.
      if (MediaQuery.disableAnimationsOf(context)) {
        _shown = _incoming;
        _swapped = true;
        _c.value = 1;
        return;
      }
      // Skipping mid-animation restarts from the cover shown now: no queue.
      _swapped = false;
      _c.forward(from: 0);
      return;
    }

    // Same track, cover changed (SMTC often sends the new title with the old
    // thumbnail first): update without animating. Compare bytes, not
    // objects: every SMTC event brings a new array with the same image.
    if (widget.artwork != null && !_sameImage(old.artwork, widget.artwork)) {
      if (_swapped) {
        _shown = widget.artwork;
      } else {
        _incoming = widget.artwork;
      }
    }
  }

  static bool _sameImage(ImageProvider? a, ImageProvider? b) {
    if (a is MemoryImage && b is MemoryImage) {
      return identical(a.bytes, b.bytes) || listEquals(a.bytes, b.bytes);
    }
    return a == b;
  }

  void _onTick() {
    if (!_swapped && _c.value >= _exitEnd) {
      setState(() {
        _shown = _incoming;
        _swapped = true;
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Progress 0..1 of [t] within [a, b], through [curve].
  static double _seg(double t, double a, double b, Curve curve) =>
      curve.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.biggest.shortestSide;

      return AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          // At rest: final state, disc centred, no sleeve.
          final t = _c.isAnimating ? _c.value : 1.0;

          double discX, discOpacity = 1, sleeveX = 0, sleeveOpacity = 0;

          if (t < _exitEnd) {
            // 1. Old disc slides out and fades
            final p = _seg(t, 0, _exitEnd, _in);
            discX = -1.4 * _dir * p;
            discOpacity = 1 - p;
          } else if (t < _enterEnd) {
            // 2. Sleeve + new disc arrive from the other side
            final p = _seg(t, _exitEnd, _enterEnd, _out);
            discX = 1.4 * _dir * (1 - p);
            sleeveX = discX;
            sleeveOpacity = p;
          } else {
            // 3. After a pause the sleeve slowly slides off and fades
            discX = 0;
            final q = _seg(t, _slideStart, 1, _slide);
            sleeveX = -1.1 * _dir * q;
            sleeveOpacity = 1 - _seg(t, _slideStart + 0.15, 1, Curves.easeIn);
          }

          return SizedBox.square(
            dimension: size,
            child: Stack(
              // The disc leaves its box while animating: no clipping.
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Transform.translate(
                  offset: Offset(discX * size, 0),
                  child: Opacity(
                    opacity: discOpacity,
                    child: widget.builder(context, _shown),
                  ),
                ),
                if (sleeveOpacity > 0)
                  Transform.translate(
                    offset: Offset(sleeveX * size, 0),
                    child: Opacity(
                      opacity: sleeveOpacity,
                      child: _Sleeve(artwork: _shown, size: size),
                    ),
                  ),
              ],
            ),
          );
        },
      );
    });
  }
}

/// Square sleeve, slightly larger than the disc so it hides it fully.
class _Sleeve extends StatelessWidget {
  const _Sleeve({required this.artwork, required this.size});
  final ImageProvider? artwork;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Transform.scale(
        scale: 1.08,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: const Color(0xFF2C2831),
            boxShadow: const [
              BoxShadow(color: Colors.black87, blurRadius: 34, offset: Offset(0, 16)),
            ],
            image: artwork == null
                ? null
                : DecorationImage(image: artwork!, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}