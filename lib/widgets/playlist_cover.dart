import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:media_overlay/models/playlist.dart';
import 'package:media_overlay/models/saved_playlist.dart';
import 'package:media_overlay/services/artwork_service.dart';
import 'package:media_overlay/theme/sona_tokens.dart';

class SonaNetImage extends StatelessWidget {
  const SonaNetImage({super.key, required this.url, this.size});
  final String? url;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final ph = Container(
      width: size,
      height: size,
      color: SonaColors.surfaceHigh,
      child: const Icon(Icons.music_note, color: SonaColors.textMuted),
    );
    if (url == null) return ph;
    return LayoutBuilder(builder: (context, c) {
      final w = size ?? c.maxWidth;
      return Image.network(
        url!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: w.isFinite ? (w * MediaQuery.devicePixelRatioOf(context)).round() : null,
        errorBuilder: (_, _, _) => ph,
      );
    });
  }
}

class PlaylistCoverImage extends ConsumerWidget {
  const PlaylistCoverImage({super.key, required this.saved, this.size, this.radius = 8});
  final SavedPlaylist saved;
  final double? size;
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var url = saved.data.coverUrl;
    if (url == null && saved.data.tracks.isNotEmpty) {
      url = ref.watch(trackArtworkProvider(saved.data.tracks.first)).asData?.value;
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SonaNetImage(url: url, size: size),
    );
  }
}

class PlaylistCollage extends StatelessWidget {
  const PlaylistCollage({super.key, required this.saved, required this.size});
  final SavedPlaylist saved;
  final double size;

  @override
  Widget build(BuildContext context) {
    final seen = <String>{};
    final picks = <PlaylistTrack>[];
    for (final t in saved.data.tracks) {
      if (seen.add(t.artist.split(',').first.trim().toLowerCase())) picks.add(t);
      if (picks.length == 4) break;
    }
    if (picks.length < 4) return PlaylistCoverImage(saved: saved, size: size, radius: 12);

    final cell = size / 2;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 24, offset: Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox.square(
          dimension: size,
          child: Column(children: [
            Row(children: [_Cell(picks[0], cell), _Cell(picks[1], cell)]),
            Row(children: [_Cell(picks[2], cell), _Cell(picks[3], cell)]),
          ]),
        ),
      ),
    );
  }
}

class _Cell extends ConsumerWidget {
  const _Cell(this.track, this.size);
  final PlaylistTrack track;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      SonaNetImage(url: ref.watch(trackArtworkProvider(track)).asData?.value, size: size);
}
