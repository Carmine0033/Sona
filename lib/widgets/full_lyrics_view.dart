import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../models/lyrics.dart';
import '../models/now_playing.dart';
import '../providers/app_providers.dart';

class FullLyricsView extends ConsumerStatefulWidget {
  const FullLyricsView({super.key});

  @override
  ConsumerState<FullLyricsView> createState() => _FullLyricsViewState();
}

class _FullLyricsViewState extends ConsumerState<FullLyricsView>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ScrollController _scrollController = ScrollController();

  Duration _base = Duration.zero;
  DateTime _anchor = DateTime.now();
  bool _playing = false;
  int _lastActiveIndex = -1;
  DateTime _lastUserInteraction = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) {
      if (_playing && mounted) {
        setState(() {});
        _autoScrollIfNeeded();
      }
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sync(NowPlaying i) {
    _base = i.position;
    _anchor = DateTime.now();
    _playing = i.isPlaying;
  }

  Duration get _pos =>
      _playing ? _base + DateTime.now().difference(_anchor) : _base;

  int _activeIndex(List<LyricLine> l, Duration pos) {
    int idx = -1;
    for (int k = 0; k < l.length; k++) {
      if (l[k].time <= pos) {
        idx = k;
      } else {
        break;
      }
    }
    return idx;
  }

  void _autoScrollIfNeeded() {
    final lyrics = ref.read(lyricsProvider).asData?.value;
    if (lyrics == null || lyrics.isEmpty) return;

    final idx = _activeIndex(lyrics, _pos);
    if (idx != _lastActiveIndex) {
      _lastActiveIndex = idx;
      if (DateTime.now().difference(_lastUserInteraction).inSeconds > 4) {
        _scrollToIndex(idx);
      }
    }
  }

  void _scrollToIndex(int index) {
    if (!_scrollController.hasClients || index < 0) return;
    const itemEstimate = 56.0;
    final viewportHeight = _scrollController.position.viewportDimension;
    final targetOffset = (index * itemEstimate) - (viewportHeight / 2) + (itemEstimate / 2);
    final clampedOffset = targetOffset.clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    _scrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(nowPlayingProvider, (p, n) {
      final i = n.asData?.value;
      if (i != null) setState(() => _sync(i));
    });

    final lyricsState = ref.watch(lyricsProvider);

    return lyricsState.when(
      loading: () => _buildStatusMessage(
        icon: Icons.search_rounded,
        title: 'Ricerca testo in corso...',
        subtitle: 'Sincronizzazione dei versi tramite LRCLIB',
        showProgress: true,
      ),
      error: (e, _) => _buildStatusMessage(
        icon: Icons.cloud_off_rounded,
        title: 'Lyrics unavailable',
        subtitle: 'Timeout server (lrclib.net non raggiungibile)',
      ),
      data: (lines) {
        if (lines.isEmpty) {
          return _buildStatusMessage(
            icon: Icons.music_note_outlined,
            title: 'Nessun testo sincronizzato',
            subtitle: 'Questo brano non ha un testo sincronizzato disponibile',
          );
        }

        final activeIdx = _activeIndex(lines, _pos);

        return NotificationListener<UserScrollNotification>(
          onNotification: (notification) {
            _lastUserInteraction = DateTime.now();
            return false;
          },
          child: ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.white,
                Colors.white,
                Colors.transparent,
              ],
              stops: [0.0, 0.12, 0.88, 1.0],
            ).createShader(rect),
            blendMode: BlendMode.dstIn,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 140, horizontal: 24),
              itemCount: lines.length,
              itemBuilder: (context, index) {
                final line = lines[index];
                final isActive = index == activeIdx;
                final isPassed = index < activeIdx;

                return GestureDetector(
                  onTap: () {
                    ref.read(playbackControllerProvider).seek(line.time);
                    _lastUserInteraction = DateTime.now();
                    _scrollToIndex(index);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: isActive
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.transparent,
                    ),
                    child: Text(
                      line.text.isEmpty ? '♪' : line.text,
                      style: TextStyle(
                        color: isActive
                            ? Colors.white
                            : (isPassed
                                ? Colors.white.withValues(alpha: 0.38)
                                : Colors.white.withValues(alpha: 0.62)),
                        fontSize: isActive ? 23 : 18,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        height: 1.35,
                        letterSpacing: -0.2,
                        shadows: isActive
                            ? [
                                Shadow(
                                  color: ThemeColors.primary.withValues(alpha: 0.5),
                                  blurRadius: 18,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusMessage({
    required IconData icon,
    required String title,
    required String subtitle,
    bool showProgress = false,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showProgress)
              const CircularProgressIndicator(
                color: ThemeColors.primaryLight,
                strokeWidth: 2.5,
              )
            else
              Icon(
                icon,
                size: 48,
                color: ThemeColors.luminescenceSubtle.withValues(alpha: 0.4),
              ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ThemeColors.luminescencePure,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ThemeColors.luminescenceSubtle,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
