import 'package:flutter/material.dart';

class MarqueeText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final double velocity; // px/sec
  const MarqueeText(this.text, {super.key, required this.style, this.velocity = 28});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: style),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout();

      // Se il testo entra, niente scroll.
      if (tp.width <= constraints.maxWidth) {
        return Align(
          alignment: Alignment.centerLeft,
          child: Text(text, style: style, maxLines: 1, overflow: TextOverflow.clip),
        );
      }
      return _Scrolling(
        text: text,
        style: style,
        textWidth: tp.width,
        viewWidth: constraints.maxWidth,
        velocity: velocity,
      );
    });
  }
}

class _Scrolling extends StatefulWidget {
  final String text;
  final TextStyle style;
  final double textWidth;
  final double viewWidth;
  final double velocity;
  const _Scrolling({
    required this.text,
    required this.style,
    required this.textWidth,
    required this.viewWidth,
    required this.velocity,
  });

  @override
  State<_Scrolling> createState() => _ScrollingState();
}

class _ScrollingState extends State<_Scrolling>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  void _setup() {
    final overflow = widget.textWidth - widget.viewWidth;
    final ms = ((overflow / widget.velocity) * 1000).round().clamp(1500, 15000);
    _c = AnimationController(vsync: this, duration: Duration(milliseconds: ms))
      ..repeat(reverse: true); 
  }

  @override
  void didUpdateWidget(_Scrolling old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text ||
        old.textWidth != widget.textWidth ||
        old.viewWidth != widget.viewWidth) {
      _c.dispose();
      _setup();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final overflow = widget.textWidth - widget.viewWidth;
    return ClipRect(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final t = Curves.easeInOut.transform(_c.value);
          return Transform.translate(
              offset: Offset(-overflow * t, 0), child: child);
        },
        child: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: widget.textWidth,
            child: Text(widget.text,
                style: widget.style, maxLines: 1, softWrap: false),
          ),
        ),
      ),
    );
  }
}