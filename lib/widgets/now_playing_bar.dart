import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_overlay/core/theme.dart';
import 'package:media_overlay/l10n/app_localizations.dart';
import 'package:media_overlay/models/now_playing.dart';
import 'package:media_overlay/providers/app_providers.dart';
import 'package:media_overlay/widgets/marquee_text.dart';

class NowPlayingBar extends ConsumerWidget {
  const NowPlayingBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nowPlayingAsync = ref.watch(nowPlayingProvider);
    final nowPlaying = nowPlayingAsync.asData?.value;
    final controller = ref.watch(playbackControllerProvider);
    final accent = ref.watch(accentColorProvider);
    final l10n = AppLocalizations.of(context)!;

    if (nowPlaying == null ||
        (nowPlaying.title.isEmpty && nowPlaying.artist.isEmpty)) {
      return Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: ThemeColors.surfaceBase.withValues(alpha: 0.95),
          border: const Border(
            top: BorderSide(color: Colors.white10, width: 1),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.music_note, size: 20, color: Colors.white38),
            const SizedBox(width: 12),
            Text(
              l10n.nothingPlaying,
              style: const TextStyle(fontSize: 12, color: Colors.white60),
            ),
          ],
        ),
      );
    }

    final hasArt = nowPlaying.artwork != null && nowPlaying.artwork!.isNotEmpty;

    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: ThemeColors.surfaceElevated.withValues(alpha: 0.95),
        border: const Border(top: BorderSide(color: Colors.white12, width: 1)),
      ),
      child: Row(
        children: [
          // Left: Artwork + Title/Artist
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              ref.read(selectedSectionProvider.notifier).state =
                  AppSection.player;
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: hasArt
                        ? Image.memory(
                            nowPlaying.artwork!,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 44,
                            height: 44,
                            color: Colors.white12,
                            child: const Icon(
                              Icons.music_note,
                              color: Colors.white38,
                              size: 22,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 200,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MarqueeText(
                          nowPlaying.title.isEmpty ? '—' : nowPlaying.title,
                          alignment: Alignment.centerLeft,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          nowPlaying.artist.isEmpty ? '—' : nowPlaying.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Center: Playback Controls
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: l10n.previousTrack,
                icon: const Icon(Icons.skip_previous_rounded, size: 22),
                color: Colors.white70,
                onPressed: controller.previous,
              ),
              const SizedBox(width: 4),
              Tooltip(
                message: nowPlaying.isPlaying ? l10n.pause : l10n.play,
                child: Material(
                  color: accent,
                  shape: const CircleBorder(),
                  elevation: 4,
                  shadowColor: accent.withValues(alpha: 0.5),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: controller.playPause,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        nowPlaying.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 22,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: l10n.nextTrack,
                icon: const Icon(Icons.skip_next_rounded, size: 22),
                color: Colors.white70,
                onPressed: controller.next,
              ),
            ],
          ),

          const Spacer(),

          // Right: Duration & Go to Player
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (nowPlaying.duration > Duration.zero)
                _ElapsedLabel(info: nowPlaying),
              const SizedBox(width: 12),
              IconButton(
                tooltip: l10n.player,
                icon: const Icon(Icons.open_in_full_rounded, size: 18),
                color: Colors.white60,
                onPressed: () {
                  ref.read(selectedSectionProvider.notifier).state =
                      AppSection.player;
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// SMTC notifica la posizione solo quando cambia qualcosa: tra un evento e
/// l'altro la stima avanza da sola, come nella SeekBar del player.
class _ElapsedLabel extends StatefulWidget {
  final NowPlaying info;
  const _ElapsedLabel({required this.info});

  @override
  State<_ElapsedLabel> createState() => _ElapsedLabelState();
}

class _ElapsedLabelState extends State<_ElapsedLabel> {
  late DateTime _anchor;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _anchor = DateTime.now();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (widget.info.isPlaying) setState(() {});
    });
  }

  @override
  void didUpdateWidget(_ElapsedLabel old) {
    super.didUpdateWidget(old);
    if (old.info != widget.info) _anchor = DateTime.now();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i = widget.info;
    var pos = i.isPlaying
        ? i.position + DateTime.now().difference(_anchor)
        : i.position;
    if (pos > i.duration) pos = i.duration;
    return Text(
      '${formatDuration(pos)} / ${formatDuration(i.duration)}',
      style: const TextStyle(
        fontSize: 11,
        color: Colors.white60,
        fontFeatures: tabularFigures,
      ),
    );
  }
}
