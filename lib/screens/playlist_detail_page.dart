import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:media_overlay/l10n/app_localizations.dart';
import 'package:media_overlay/models/playlist.dart';
import 'package:media_overlay/models/saved_playlist.dart';
import 'package:media_overlay/models/sona_player_view_model.dart';
import 'package:media_overlay/providers/app_providers.dart';
import 'package:media_overlay/theme/sona_tokens.dart';
import 'package:media_overlay/utils/search.dart';
import 'package:media_overlay/viewmodels/playlist_library_view_model.dart';
import 'package:media_overlay/widgets/expandable_search.dart';
import 'package:media_overlay/widgets/playlist_cover.dart';
import 'package:media_overlay/widgets/sona_player_bar.dart' show kPlayerBarReserve;
import 'package:media_overlay/widgets/sona_ui.dart';
import 'package:media_overlay/widgets/track_tile.dart';

class PlaylistDetailPage extends ConsumerStatefulWidget {
  const PlaylistDetailPage({super.key, required this.saved});
  final SavedPlaylist saved;

  @override
  ConsumerState<PlaylistDetailPage> createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends ConsumerState<PlaylistDetailPage> {
  final _searchKey = GlobalKey<ExpandableSearchState>();
  String _query = '';

  Future<void> _confirmRemove() async {
    final l = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: SonaColors.surfaceHigh,
        content: Text(l.libraryRemoveConfirm(widget.saved.data.title), style: SonaText.bodyMd),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.libraryCancel)),
          TextButton(onPressed: () => Navigator.pop(c, true), child: Text(l.libraryRemove)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    ref.read(openPlaylistKeyProvider.notifier).close();
    ref.read(playlistLibraryProvider.notifier).remove(widget.saved.key);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final accent = ref.watch(accentColorProvider);
    final light = SonaColors.light(accent);
    final s = ref.watch(sonaPlayerProvider);
    final vm = ref.read(sonaPlayerProvider.notifier);
    final saved = widget.saved;
    final p = saved.data;

    final active = s.playlist != null && saved.matches(s.playlist!);
    final playing = active && s.phase == PlayerPhase.playing;

    // ORIGINAL indexes of the matching tracks: used for numbering,
    // highlighting and to start playback from the right track.
    final q = normalizeSearch(_query);
    final List<int>? matches = q.isEmpty
        ? null
        : [
            for (var i = 0; i < p.tracks.length; i++)
              if (saved.titleKeys[i].contains(q) || saved.artistKeys[i].contains(q)) i,
          ];
    final count = matches?.length ?? p.tracks.length;

    final list = ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16 + kPlayerBarReserve),
      itemCount: count + 1,
      itemBuilder: (context, i) {
        if (i > 0) {
          final ti = matches?[i - 1] ?? i - 1;
          return TrackTile(
            index: ti + 1, // real position in the playlist, even when filtered
            track: p.tracks[ti],
            isPlaying: active && s.index == ti,
            onPlay: () => vm.playAt(p, ti),
          );
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextButton.icon(
            onPressed: () => ref.read(openPlaylistKeyProvider.notifier).close(),
            icon: const Icon(Icons.arrow_back, size: 16),
            label: Text(l.libraryBack.toUpperCase(), style: SonaText.labelMd),
            style: TextButton.styleFrom(foregroundColor: SonaColors.textMid),
          ),
          const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            PlaylistCoverImage(saved: saved, size: 160, radius: 12),
            const SizedBox(width: 20),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.librarySourcePlaylist(p.source.label).toUpperCase(),
                    style: SonaText.labelSm.copyWith(color: light, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(p.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: SonaText.headlineLg),
                const SizedBox(height: 4),
                Text(
                  [
                    if (p.owner != null) p.owner!,
                    l.libraryTracks(p.tracks.length),
                    if (saved.totalDuration > Duration.zero) formatTotal(saved.totalDuration),
                    updatedLabel(l, saved.syncedAt),
                  ].join('  •  '),
                  style: SonaText.labelMd,
                ),
                if (p.truncated) ...[
                  const SizedBox(height: 4),
                  Text(l.playlistTruncated, style: SonaText.bodySm.copyWith(color: SonaColors.error)),
                ],
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SonaPrimaryButton(
                      icon: playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      tooltip: playing ? l.libraryPause : l.libraryPlayNow,
                      accent: accent,
                      large: true,
                      onTap: () => active ? vm.togglePlay() : vm.playAt(p, 0),
                    ),
                    // Not playing yet: start from a random track in shuffle
                    // mode. Already playing: just toggle shuffle.
                    SonaSecondaryButton(
                      icon: Icons.shuffle,
                      tooltip: l.shuffle,
                      iconColor: active && s.shuffle ? light : null,
                      onTap: () => active ? vm.toggleShuffle() : vm.shufflePlay(p),
                    ),
                    SonaSecondaryButton(
                      icon: Icons.sync,
                      tooltip: l.librarySync,
                      onTap: () => syncWithFeedback(context, ref, saved.key),
                    ),
                    SonaSecondaryButton(
                      icon: saved.favorite ? Icons.favorite : Icons.favorite_border,
                      tooltip: l.libraryFavorites,
                      iconColor: saved.favorite ? light : null,
                      onTap: () => ref.read(playlistLibraryProvider.notifier).toggleFavorite(saved.key),
                    ),
                    SonaSecondaryButton(
                      icon: Icons.delete_outline,
                      tooltip: l.libraryRemove,
                      onTap: _confirmRemove,
                    ),
                    // Search next to the buttons, same height (48).
                    ExpandableSearch(
                      key: _searchKey,
                      accent: accent,
                      height: 48,
                      hint: l.searchInPlaylistHint,
                      openTooltip: l.searchOpen,
                      closeTooltip: l.searchClose,
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ],
                ),
              ]),
            ),
          ]),
          const SizedBox(height: 24),
          if (matches != null && matches.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text(l.searchNoResults, style: SonaText.bodyMd)),
            ),
        ]);
      },
    );

    // Ctrl+F opens the search here too, as the tooltip promises.
    return SearchShortcut(
      onTrigger: () => _searchKey.currentState?.open(),
      child: list,
    );
  }
}
