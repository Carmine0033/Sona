import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'package:media_overlay/l10n/app_localizations.dart';

import 'package:media_overlay/providers/app_providers.dart';
import 'package:media_overlay/providers/lyrics_providers.dart';
import 'package:media_overlay/theme/sona_tokens.dart';
import 'package:media_overlay/widgets/lyrics/lyrics_view.dart';

// Original sample lyrics for the preview, timed over 30 seconds.
const _demo = [
  SyncedLine(Duration(milliseconds: 0), 'Accendo la notte con un giro di vinile'),
  SyncedLine(Duration(milliseconds: 3800), 'le luci della stanza diventano viola'),
  SyncedLine(Duration(milliseconds: 7600), 'il volume sale piano, non serve parlare'),
  SyncedLine(Duration(milliseconds: 11400), "basta una canzone per cambiare l'aria"),
  SyncedLine(Duration(milliseconds: 15200), 'Gira, gira ancora'),
  SyncedLine(Duration(milliseconds: 18200), 'fino a quando il giorno non torna'),
  SyncedLine(Duration(milliseconds: 22000), 'gira, gira ancora'),
  SyncedLine(Duration(milliseconds: 25000), 'e il resto lo spegniamo dopo'),
];
const _demoLoop = 29000;

enum _Place { player, playlist, mini }

class LyricsSettings extends ConsumerStatefulWidget {
  const LyricsSettings({super.key});
  @override
  ConsumerState<LyricsSettings> createState() => _LyricsSettingsState();
}

class _LyricsSettingsState extends ConsumerState<LyricsSettings> {
  final _start = DateTime.now();
  _Place _preview = _Place.player; // the preview shows the last place edited

  /// Fake clock that loops every 29 s.
  PlaybackClock _demoClock() {
    final ms = DateTime.now().difference(_start).inMilliseconds % _demoLoop;
    return PlaybackClock(anchor: Duration(milliseconds: ms), at: DateTime.now(), playing: false);
  }

  StateProvider<LyricsStyle> _provider(_Place p) => switch (p) {
        _Place.player => lyricsStylePlayerProvider,
        _Place.playlist => lyricsStylePlaylistProvider,
        _Place.mini => lyricsStyleMiniProvider,
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final accent = ref.watch(accentColorProvider);
    final offset = ref.watch(lyricsOffsetProvider);
    final size = ref.watch(lyricsSizeProvider);
    final previewStyle = ref.watch(_provider(_preview));

    String styleLabel(LyricsStyle s) => switch (s) {
          LyricsStyle.karaoke => l.lyricsStyleKaraoke,
          LyricsStyle.focus => l.lyricsStyleFocus,
          LyricsStyle.compact => l.lyricsStyleCompact,
          LyricsStyle.twoLines => l.lyricsStyleTwoLines,
          LyricsStyle.hidden => l.lyricsStyleHidden,
        };

    Widget row(String label, _Place place) {
      final current = ref.watch(_provider(place));
      final options = place == _Place.mini
          ? [LyricsStyle.twoLines, LyricsStyle.karaoke, LyricsStyle.hidden]
          : [LyricsStyle.karaoke, LyricsStyle.focus, LyricsStyle.compact, LyricsStyle.twoLines];
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label.toUpperCase(), style: SonaText.labelMd),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final s in options)
              ChoiceChip(
                label: Text(styleLabel(s)),
                selected: current == s,
                selectedColor: accent,
                onSelected: (_) {
                  ref.read(_provider(place).notifier).state = s;
                  setState(() => _preview = place);
                },
              ),
          ]),
        ]),
      );
    }

    final offsetText = offset == 0
        ? l.lyricsInSync
        : (offset > 0 ? l.lyricsEarlier : l.lyricsLater)((offset.abs() / 1000).toStringAsFixed(1));

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Live preview of the style picked for the last place edited
      Container(
        height: 190,
        decoration: BoxDecoration(
          color: SonaColors.canvas,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: SonaColors.outline),
        ),
        child: previewStyle == LyricsStyle.hidden
            ? Center(child: Text(l.lyricsStyleHidden, style: SonaText.bodyMd))
            : LyricsView(
                lines: _demo,
                clock: _demoClock,
                style: previewStyle,
                size: size,
                baseFontSize: _preview == _Place.mini ? 15 : 20,
                offset: Duration(milliseconds: offset),
                accent: accent,
                resumeLabel: l.lyricsResume,
              ),
      ),
      const SizedBox(height: 16),

      row(l.lyricsWherePlayer, _Place.player),
      row(l.lyricsWherePlaylist, _Place.playlist),
      row(l.lyricsWhereMini, _Place.mini),

      Text(l.lyricsSize.toUpperCase(), style: SonaText.labelMd),
      const SizedBox(height: 6),
      Wrap(spacing: 6, children: [
        for (final s in LyricsSize.values)
          ChoiceChip(
            label: Text(switch (s) {
              LyricsSize.small => l.lyricsSizeSmall,
              LyricsSize.medium => l.lyricsSizeMedium,
              LyricsSize.large => l.lyricsSizeLarge,
            }),
            selected: size == s,
            selectedColor: accent,
            onSelected: (_) => ref.read(lyricsSizeProvider.notifier).state = s,
          ),
      ]),
      const SizedBox(height: 16),

      // Offset described in words; the number itself stays secondary
      Row(children: [
        Expanded(child: Text(l.lyricsTiming.toUpperCase(), style: SonaText.labelMd)),
        if (offset != 0)
          TextButton(
            onPressed: () => ref.read(lyricsOffsetProvider.notifier).state = 0,
            child: Text(l.lyricsReset),
          ),
      ]),
      Slider(
        min: -1000,
        max: 1000,
        divisions: 40, // 50 ms steps
        value: offset.toDouble(),
        activeColor: accent,
        onChanged: (v) => ref.read(lyricsOffsetProvider.notifier).state = v.round(),
      ),
      Text(offsetText, style: SonaText.bodySm),
    ]);
  }
}
