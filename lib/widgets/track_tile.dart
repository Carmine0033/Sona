import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:media_overlay/models/playlist.dart';
import 'package:media_overlay/providers/app_providers.dart';
import 'package:media_overlay/services/artwork_service.dart';
import 'package:media_overlay/theme/sona_tokens.dart';
import 'package:media_overlay/widgets/playlist_cover.dart';

class TrackTile extends ConsumerWidget {
  const TrackTile({
    super.key,
    required this.index,
    required this.track,
    required this.onPlay,
    this.isPlaying = false,
  });

  final int index;
  final PlaylistTrack track;
  final VoidCallback onPlay;
  final bool isPlaying;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = track;
    final accent = ref.watch(accentColorProvider);
    final light = SonaColors.light(accent);
    final cover = ref.watch(trackArtworkProvider(t)).asData?.value;

    return Material(
      color: isPlaying ? accent.withValues(alpha: 0.10) : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPlay,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(children: [
            SizedBox(
              width: 28,
              child: isPlaying
                  ? Icon(Icons.graphic_eq, size: 16, color: light)
                  : Text('$index', textAlign: TextAlign.right, style: SonaText.labelMd),
            ),
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SonaNetImage(url: cover, size: 40),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Artist on top, title below.
                Text(t.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SonaText.titleMd.copyWith(color: isPlaying ? light : null)),
                Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: SonaText.bodyMd),
              ]),
            ),
            if (t.album != null)
              Expanded(
                flex: 2,
                child: Text(t.album!, maxLines: 1, overflow: TextOverflow.ellipsis, style: SonaText.bodySm),
              ),
            if (t.duration != null) Text(_fmt(t.duration!), style: SonaText.labelMd),
          ]),
        ),
      ),
    );
  }

  static String _fmt(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
}
