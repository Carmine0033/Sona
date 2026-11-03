import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:media_overlay/providers/lyrics_providers.dart';
import 'package:media_overlay/theme/sona_tokens.dart';

enum _Pos { past, active, next }

const _out = Cubic(0.22, 1, 0.36, 1);

/// After a manual scroll, following the music resumes on its own after this.
const _resumeAfter = Duration(seconds: 4);

class LyricsView extends StatefulWidget {
  const LyricsView({
    super.key,
    required this.lines,
    required this.clock,
    required this.style,
    required this.accent,
    required this.resumeLabel,
    this.size = LyricsSize.medium,
    this.baseFontSize = 20,
    this.offset = Duration.zero,
    this.onSeek,
  });

  final List<SyncedLine> lines;
  final PlaybackClock Function() clock;
  final LyricsStyle style;
  final LyricsSize size;
  final double baseFontSize; // 26 now playing, 18 side panel, 15 mini card
  final Duration offset;
  final Color accent;
  final String resumeLabel;
  final ValueChanged<Duration>? onSeek;

  @override
  State<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<LyricsView> with SingleTickerProviderStateMixin {
  // Started in initState: a lazy `late` initializer would only run on dispose.
  late final Ticker _ticker;
  final _scroll = ScrollController();
  final _progress = ValueNotifier<double>(0); // karaoke fill of the active line
  late List<GlobalKey> _keys = _makeKeys();
  int _active = -1;
  bool _browsing = false;
  Timer? _resumeTimer;

  List<GlobalKey> _makeKeys() => List.generate(widget.lines.length, (_) => GlobalKey());

  double get _scale => switch (widget.size) {
        LyricsSize.small => 0.85,
        LyricsSize.medium => 1.0,
        LyricsSize.large => 1.2,
      };

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void didUpdateWidget(LyricsView old) {
    super.didUpdateWidget(old);
    if (!identical(old.lines, widget.lines)) {
      // New track: start again from the top.
      _keys = _makeKeys();
      _active = -1;
      _browsing = false;
      _resumeTimer?.cancel();
      if (_scroll.hasClients) _scroll.jumpTo(0);
    }
    if (old.style != widget.style || old.size != widget.size) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _follow(animate: false));
    }
  }

  @override
  void dispose() {
    _resumeTimer?.cancel();
    _ticker.dispose();
    _scroll.dispose();
    _progress.dispose();
    super.dispose();
  }

  Duration get _pos => widget.clock().now() + widget.offset;

  /// Binary search: last line that has already started.
  int _indexAt(Duration pos) {
    var lo = 0, hi = widget.lines.length - 1, ans = -1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      if (widget.lines[mid].start <= pos) {
        ans = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return ans;
  }

  void _onTick(Duration _) {
    if (widget.lines.isEmpty) return;
    final pos = _pos;
    final idx = _indexAt(pos);
    // Rebuild only when the line changes; in between, only the karaoke
    // fill updates, through _progress.
    if (idx != _active) {
      setState(() => _active = idx);
      WidgetsBinding.instance.addPostFrameCallback((_) => _follow());
    }
    if (widget.style == LyricsStyle.karaoke && idx >= 0) {
      _progress.value = _lineProgress(idx, pos);
    }
  }

  double _lineProgress(int i, Duration pos) {
    final start = widget.lines[i].start;
    final end = i + 1 < widget.lines.length
        ? widget.lines[i + 1].start - const Duration(milliseconds: 300)
        : start + const Duration(seconds: 4);
    final ms = (end - start).inMilliseconds;
    if (ms <= 0) return 1;
    // Above ~4 words per second (rap, fast songs) an estimated fill is
    // visibly off: light the whole line instead.
    final words = widget.lines[i].text.trim().split(RegExp(r'\s+')).length;
    if (words / (ms / 1000) > 4) return 1;
    return ((pos - start).inMilliseconds / ms).clamp(0.0, 1.0);
  }

  void _follow({bool animate = true}) {
    if (!mounted || _browsing || _active < 0 || _active >= _keys.length) return;
    final ctx = _keys[_active].currentContext;
    if (ctx == null) return;
    final reduce = MediaQuery.disableAnimationsOf(context);
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.36, // active line sits a little above the middle
      duration: (animate && !reduce) ? const Duration(milliseconds: 450) : Duration.zero,
      curve: _out,
    );
  }

  /// Manual scroll: stop following the music until resumed or idle.
  void _startBrowsing() {
    _resumeTimer?.cancel();
    _resumeTimer = Timer(_resumeAfter, () {
      if (mounted && _browsing) _resume();
    });
    if (!_browsing) setState(() => _browsing = true);
  }

  void _resume() {
    _resumeTimer?.cancel();
    setState(() => _browsing = false);
    _follow();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (widget.style == LyricsStyle.twoLines) {
      return _TwoLines(
        lines: widget.lines,
        active: _active,
        fontSize: widget.baseFontSize * _scale,
        reduce: reduce,
      );
    }

    final gap = widget.style == LyricsStyle.compact ? 4.0 : 14.0 * _scale;

    return LayoutBuilder(builder: (context, c) {
      return Stack(children: [
        // Faded top and bottom edges: lines enter and leave without a hard cut.
        ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (r) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.white, Colors.white, Colors.transparent],
            stops: [0, 0.12, 0.84, 1],
          ).createShader(r),
          child: Listener(
            // The mouse wheel doesn't start a drag on desktop, so catch it here.
            onPointerSignal: (e) {
              if (e is PointerScrollEvent) _startBrowsing();
            },
            child: NotificationListener<ScrollStartNotification>(
              onNotification: (n) {
                if (n.dragDetails != null) _startBrowsing(); // scrollbar drag
                return false;
              },
              child: SingleChildScrollView(
                controller: _scroll,
                // Room above and below so the first and last lines can reach the focus point.
                padding: EdgeInsets.fromLTRB(18, c.maxHeight * 0.36, 18, c.maxHeight * 0.6),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  for (var i = 0; i < widget.lines.length; i++)
                    KeyedSubtree(
                      key: _keys[i],
                      child: Padding(padding: EdgeInsets.symmetric(vertical: gap / 2), child: _line(i, reduce)),
                    ),
                ]),
              ),
            ),
          ),
        ),
        if (_browsing)
          Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            child: Center(
              child: Material(
                color: SonaColors.surfaceHigh,
                shape: const StadiumBorder(side: BorderSide(color: SonaColors.outline)),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: _resume,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Text(widget.resumeLabel.toUpperCase(), style: SonaText.labelSm.copyWith(color: SonaColors.text)),
                  ),
                ),
              ),
            ),
          ),
      ]);
    });
  }

  Widget _line(int i, bool reduce) {
    final pos = i == _active ? _Pos.active : (i < _active ? _Pos.past : _Pos.next);
    final line = widget.lines[i];
    final text = line.text.trim().isEmpty ? '♪' : line.text; // instrumental break

    final child = widget.style == LyricsStyle.compact
        ? _CompactLine(
            text: text,
            start: line.start,
            pos: pos,
            accent: widget.accent,
            fontSize: 14.5 * _scale,
            reduce: reduce,
          )
        : _BigLine(
            text: text,
            pos: pos,
            karaoke: widget.style == LyricsStyle.karaoke,
            progress: _progress,
            fontSize: widget.baseFontSize * _scale,
            reduce: reduce,
          );

    if (widget.onSeek == null) return child;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          // The offset moves the text, not the music: remove it to seek to the right spot.
          widget.onSeek!(line.start - widget.offset + const Duration(milliseconds: 10));
          _resume();
        },
        child: child,
      ),
    );
  }
}

// ───────────────────────── Karaoke and Focus ─────────────────────────

class _BigLine extends StatelessWidget {
  const _BigLine({
    required this.text,
    required this.pos,
    required this.karaoke,
    required this.progress,
    required this.fontSize,
    required this.reduce,
  });

  final String text;
  final _Pos pos;
  final bool karaoke, reduce;
  final ValueNotifier<double> progress;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: 'SpaceGrotesk',
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      height: 1.25,
      color: SonaColors.text,
    );

    // Floor of 0.25: any fainter and the text gets tiring to follow.
    final opacity = switch (pos) {
      _Pos.active => 1.0,
      _Pos.next => 0.42,
      _Pos.past => karaoke ? 0.42 : 0.25,
    };

    Widget t = (pos == _Pos.active && karaoke)
        ? ValueListenableBuilder<double>(
            valueListenable: progress,
            builder: (_, p, _) => _KaraokeText(text: text, progress: p, style: style),
          )
        : Text(text, style: style);

    // Focus: sung lines are slightly blurred (no blur with reduced motion).
    if (!karaoke && pos == _Pos.past && !reduce) {
      t = ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 1.2, sigmaY: 1.2), child: t);
    }

    final d = reduce ? Duration.zero : const Duration(milliseconds: 300);
    return AnimatedOpacity(
      opacity: opacity,
      duration: d,
      child: AnimatedScale(
        scale: (!karaoke && pos == _Pos.active) ? 1.03 : 1.0,
        alignment: Alignment.centerLeft,
        duration: d,
        curve: _out,
        child: t,
      ),
    );
  }
}

/// Fill by character: with one timestamp per line, splitting by characters
/// moves smoothly and tracks the voice better than jumping word by word.
class _KaraokeText extends StatelessWidget {
  const _KaraokeText({required this.text, required this.progress, required this.style});
  final String text;
  final double progress;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final chars = text.characters; // graphemes: emoji are never split
    final n = (chars.length * progress).round();
    return Text.rich(TextSpan(style: style, children: [
      TextSpan(text: chars.take(n).toString()),
      TextSpan(
        text: chars.skip(n).toString(),
        // Above the 0.42 of the other lines, so the active one always stands out.
        style: TextStyle(color: SonaColors.text.withValues(alpha: 0.55)),
      ),
    ]));
  }
}

// ───────────────────────── Compact ─────────────────────────

class _CompactLine extends StatelessWidget {
  const _CompactLine({
    required this.text,
    required this.start,
    required this.pos,
    required this.accent,
    required this.fontSize,
    required this.reduce,
  });

  final String text;
  final Duration start;
  final _Pos pos;
  final Color accent;
  final double fontSize;
  final bool reduce;

  @override
  Widget build(BuildContext context) {
    final active = pos == _Pos.active;
    final light = SonaColors.light(accent);
    final ts = '${start.inMinutes}:${(start.inSeconds % 60).toString().padLeft(2, '0')}';
    final d = reduce ? Duration.zero : const Duration(milliseconds: 200);

    return AnimatedOpacity(
      opacity: active ? 1 : (pos == _Pos.past ? 0.5 : 0.75),
      duration: d,
      child: AnimatedContainer(
        duration: d,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: active ? accent.withValues(alpha: 0.14) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 40,
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(ts, style: SonaText.labelSm.copyWith(color: active ? light : SonaColors.textMuted)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: SonaText.bodyMd.copyWith(
                  fontSize: fontSize,
                  height: 1.45,
                  color: active ? SonaColors.text : SonaColors.textMid,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                )),
          ),
        ]),
      ),
    );
  }
}

// ───────────────────────── Two lines ─────────────────────────

class _TwoLines extends StatelessWidget {
  const _TwoLines({
    required this.lines,
    required this.active,
    required this.fontSize,
    required this.reduce,
  });
  final List<SyncedLine> lines;
  final int active;
  final double fontSize;
  final bool reduce;

  @override
  Widget build(BuildContext context) {
    final cur = active < 0 || lines[active].text.trim().isEmpty ? '♪' : lines[active].text;
    final next = active + 1 < lines.length ? lines[active + 1].text : '';
    final d = reduce ? Duration.zero : const Duration(milliseconds: 320);
    Widget fade(Widget child, Animation<double> a) => FadeTransition(
          opacity: a,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.15), end: Offset.zero)
                .animate(CurvedAnimation(parent: a, curve: _out)),
            child: child,
          ),
        );

    // Clipped: in the 88px mini card a long line must never overflow.
    return ClipRect(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
          AnimatedSwitcher(
            duration: d,
            transitionBuilder: fade,
            child: Text(
              cur,
              key: ValueKey('c$active'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: fontSize * 1.2,
                fontWeight: FontWeight.w700,
                height: 1.2,
                color: SonaColors.text,
              ),
            ),
          ),
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: d,
            child: Text(
              next,
              key: ValueKey('n$active'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SonaText.bodyMd.copyWith(fontSize: fontSize * 0.8, color: SonaColors.textMuted),
            ),
          ),
        ]),
      ),
    );
  }
}
