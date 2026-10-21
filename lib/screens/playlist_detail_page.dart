import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:media_overlay/l10n/app_localizations.dart';
import 'package:media_overlay/models/playlist.dart';
import 'package:media_overlay/models/saved_playlist.dart';
import 'package:media_overlay/models/sona_player_view_model.dart';
import 'package:media_overlay/providers/app_providers.dart';
import 'package:media_overlay/theme/sona_tokens.dart';
import 'package:media_overlay/viewmodels/playlist_library_view_model.dart';
import 'package:media_overlay/widgets/playlist_cover.dart';
import 'package:media_overlay/widgets/sona_player_bar.dart' show kPlayerBarReserve;
import 'package:media_overlay/widgets/sona_ui.dart';
import 'package:media_overlay/widgets/track_tile.dart';

class PlaylistDetailPage extends ConsumerWidget {
  const PlaylistDetailPage({super.key, required this.saved});
  final SavedPlaylist saved;

  Future<void> _confirmRemove(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: SonaColors.surfaceHigh,
        content: Text(l.libraryRemoveConfirm(saved.data.title), style: SonaText.bodyMd),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.libraryCancel)),
          TextButton(onPressed: () => Navigator.pop(c, true), child: Text(l.libraryRemove)),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    ref.read(openPlaylistKeyProvider.notifier).close();
    ref.read(playlistLibraryProvider.notifier).remove(saved.key);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final accent = ref.watch(accentColorProvider);
    final light = SonaColors.light(accent);
    final s = ref.watch(sonaPlayerProvider);
    final vm = ref.read(sonaPlayerProvider.notifier);
    final p = saved.data;

    final active = s.playlist != null && saved.matches(s.playlist!);
    final playing = active && s.phase == PlayerPhase.playing;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16 + kPlayerBarReserve),
      itemCount: p.tracks.length + 1,
      itemBuilder: (context, i) {
        if (i > 0) {
          return TrackTile(
            index: i,
            track: p.tracks[i - 1],
            isPlaying: active && s.index == i - 1,
            onPlay: () => vm.playAt(p, i - 1),
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
                Wrap(spacing: 8, runSpacing: 8, children: [
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
                    onTap: () => _confirmRemove(context, ref),
                  ),
                ]),
              ]),
            ),
          ]),
          const SizedBox(height: 24),
        ]);
      },
    );
  }
}
