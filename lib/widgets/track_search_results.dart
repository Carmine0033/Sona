import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:media_overlay/models/playlist.dart';
import 'package:media_overlay/models/saved_playlist.dart';
import 'package:media_overlay/models/sona_player_view_model.dart';
import 'package:media_overlay/providers/app_providers.dart';
import 'package:media_overlay/services/artwork_service.dart';
import 'package:media_overlay/theme/sona_tokens.dart';
import 'package:media_overlay/utils/search.dart';
import 'package:media_overlay/widgets/playlist_cover.dart';
import 'package:media_overlay/widgets/sona_ui.dart';

class TrackHit {
  const TrackHit(this.playlist, this.index);
  final SavedPlaylist playlist;
  final int index;
  PlaylistTrack get track => playlist.data.tracks[index];
}

const kMaxSearchHits = 200;

/// Tracks matching [query] across [playlists]: title matches first, then
/// artist matches, capped at [kMaxSearchHits] to keep the list responsive.
List<TrackHit> searchTracks(Iterable<SavedPlaylist> playlists, String query) {
  final q = normalizeSearch(query.trim());
  if (q.isEmpty) return const [];
  final byTitle = <TrackHit>[], byArtist = <TrackHit>[];
  for (final p in playlists) {
    for (var i = 0; i < p.titleKeys.length; i++) {
      if (p.titleKeys[i].contains(q)) {
        byTitle.add(TrackHit(p, i));
      } else if (p.artistKeys[i].contains(q)) {
        byArtist.add(TrackHit(p, i));
      }
    }
  }
  return[...byTitle, ...byArtist].take(kMaxSearchHits).toList();
}

class TrackHitTile extends ConsumerWidget {
  const TrackHitTile({super.key, required this.hit, required this.query});
  final TrackHit hit;
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(accentColorProvider);
    final light = SonaColors.light(accent);
    final t = hit.track;
    final p = hit.playlist;
    final cover = ref.watch(trackArtworkProvider(t)).asData?.value;
    final isPlaying = ref.watch(sonaPlayerProvider.select(
      (s) => s.playlist != null && p.matches(s.playlist!) && s.index == hit.index,
    ));
    final match = TextStyle(color: light, fontWeight: FontWeight.w700);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => ref.read(sonaPlayerProvider.notifier).playAt(p.data, hit.index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isPlaying ? accent.withValues(alpha: 0.08) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          // Accent strip for the playing track. Not a Border(left:): Flutter
          // can't paint a one-sided border together with a borderRadius.
          Container(
            width: 3,
            height: 32,
            margin: const EdgeInsets.only(right: 9),
            decoration: BoxDecoration(
              color: isPlaying ? light : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SonaNetImage(url: cover, size: 40),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text.rich(
                highlightMatch(t.title, query, SonaText.titleMd.copyWith(fontSize: 14), match),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text.rich(
                highlightMatch(t.artist, query, SonaText.bodySm, match),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ]),
          ),
          const SizedBox(width: 12),
          Flexible(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: SonaColors.surfaceLow,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: SonaColors.specular),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(p.data.source.icon, size: 12, color: light),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(p.data.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SonaText.labelSm.copyWith(color: SonaColors.textMid)),
                ),
              ]),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 40,
            child:  t.duration == null
              ? null
              : Text(
                 '${t.duration!.inMinutes}:${(t.duration!.inSeconds % 60).toString().padLeft(2, '0')}',
                  textAlign: TextAlign.right,
                  style: SonaText.labelSm,
              ),
          ),
        ]),
      ),
    );
  }
}