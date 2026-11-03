import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:media_overlay/l10n/app_localizations.dart';
import 'package:media_overlay/providers/lyrics_providers.dart';
import 'package:media_overlay/theme/sona_tokens.dart';
import 'package:media_overlay/widgets/lyrics/live_lyrics.dart';
import 'package:media_overlay/widgets/sona_player_bar.dart';

const kLyricsPanelWidth = 320.0;

class LyricsSidePanel extends ConsumerWidget {
  const LyricsSidePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final open = ref.watch(lyricsPanelOpenProvider);
    final style = ref.watch(lyricsStylePlaylistProvider);

    // Width animates 0 ↔ 320; OverflowBox keeps the content 320 wide meanwhile
    // so the text doesn't rewrap on every frame. TickerMode stops the lyrics
    // clock while the panel is closed.
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      width: open ? kLyricsPanelWidth : 0,
      child: TickerMode(
        enabled: open,
        child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.centerLeft,
          minWidth: kLyricsPanelWidth,
          maxWidth: kLyricsPanelWidth,
          child: Container(
            decoration: const BoxDecoration(
              color: SonaColors.surfaceLow,
              border: Border(left: BorderSide(color: SonaColors.outline)),
            ),
            padding: const EdgeInsets.only(bottom: kPlayerBarReserve),
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 8, 4),
                child: Row(children: [
                  Text(l.lyricsTitle, style: SonaText.titleMd),
                  const Spacer(),
                  IconButton(
                    tooltip: l.close,
                    icon: const Icon(Icons.close, size: 16),
                    color: SonaColors.textMuted,
                    onPressed: () => ref.read(lyricsPanelOpenProvider.notifier).state = false,
                  ),
                ]),
              ),
              Expanded(child: LiveLyrics(style: style, baseFontSize: 18)),
            ]),
          ),
        ),
      ),
      ),
    );
  }
}
