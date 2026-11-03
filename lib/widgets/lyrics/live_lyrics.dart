import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:media_overlay/l10n/app_localizations.dart';
import 'package:media_overlay/providers/app_providers.dart';
import 'package:media_overlay/providers/lyrics_providers.dart';
import 'package:media_overlay/theme/sona_tokens.dart';
import 'package:media_overlay/widgets/lyrics/lyrics_view.dart';

/// Synced lyrics of whatever is playing (built-in player or SMTC).
class LiveLyrics extends ConsumerStatefulWidget {
  const LiveLyrics({super.key, required this.style, required this.baseFontSize});
  final LyricsStyle style;
  final double baseFontSize;

  @override
  ConsumerState<LiveLyrics> createState() => _LiveLyricsState();
}

class _LiveLyricsState extends ConsumerState<LiveLyrics> {
  late PlaybackClock _clock = ref.read(playbackClockProvider);

  @override
  Widget build(BuildContext context) {
    ref.listen(playbackClockProvider, (_, c) => _clock = c);

    final l = AppLocalizations.of(context)!;
    final lyrics = ref.watch(activeLyricsProvider);
    final hasTrack = ref.watch(activeTrackProvider.select((t) => t != null));

    if (widget.style == LyricsStyle.hidden) return const SizedBox.shrink();
    if (!hasTrack) return _Message(l.lyricsNothingPlaying);

    return switch (lyrics) {
      AsyncData(value: final lines?) when lines.isNotEmpty => LyricsView(
          lines: lines,
          clock: () => _clock,
          style: widget.style,
          size: ref.watch(lyricsSizeProvider),
          baseFontSize: widget.baseFontSize,
          offset: Duration(milliseconds: ref.watch(lyricsOffsetProvider)),
          accent: ref.watch(accentColorProvider),
          resumeLabel: l.lyricsResume,
          onSeek: (d) => seekLyrics(ref, d),
        ),
      AsyncLoading() => _Message(l.lyricsSearching),
      _ => _Message(l.lyricsUnavailable),
    };
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(text, textAlign: TextAlign.center, style: SonaText.bodyMd.copyWith(color: SonaColors.textMuted)),
        ),
      );
}
