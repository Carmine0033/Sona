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
import 'package:media_overlay/widgets/sona_ui.dart';

class PlaylistCard extends ConsumerStatefulWidget {
  const PlaylistCard({super.key, required this.saved});
  final SavedPlaylist saved;

  @override
  ConsumerState<PlaylistCard> createState() => _PlaylistCardState();
}

class _PlaylistCardState extends ConsumerState<PlaylistCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final accent = ref.watch(accentColorProvider);
    final light = SonaColors.light(accent);
    final s = ref.watch(sonaPlayerProvider);
    final saved = widget.saved;
    final p = saved.data;

    final active = s.playlist != null && saved.matches(s.playlist!);
    final playing = active && s.phase == PlayerPhase.playing;
    final showPlay = _hover || playing;

    void play() {
      final vm = ref.read(sonaPlayerProvider.notifier);
      active ? vm.togglePlay() : vm.playAt(p, 0);
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => ref.read(openPlaylistKeyProvider.notifier).open(saved.key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.translationValues(0, _hover ? -4 : 0, 0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _hover ? SonaColors.surfaceMid : SonaColors.surfaceLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? accent.withValues(alpha: 0.5) : SonaColors.specular),
            boxShadow: [
              _hover
                  ? BoxShadow(color: accent.withValues(alpha: 0.25), blurRadius: 30, offset: const Offset(0, 8))
                  : const BoxShadow(color: Colors.black45, blurRadius: 16, offset: Offset(0, 6)),
            ],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(fit: StackFit.expand, children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedScale(
                    scale: _hover ? 1.05 : 1,
                    duration: const Duration(milliseconds: 500),
                    child: PlaylistCoverImage(saved: saved, radius: 0),
                  ),
                ),
                IgnorePointer(
                  ignoring: !showPlay,
                  child: AnimatedOpacity(
                    opacity: showPlay ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      decoration: BoxDecoration(
                        color: SonaColors.canvas.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: _RoundPlay(playing: playing, accent: accent, onTap: play),
                    ),
                  ),
                ),
                Positioned(top: 8, left: 8, child: _SourceTag(source: p.source, color: light)),
                Positioned(
                  top: 4,
                  right: 4,
                  child: _FavButton(
                    active: saved.favorite,
                    color: light,
                    onTap: () => ref.read(playlistLibraryProvider.notifier).toggleFavorite(saved.key),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            Text(p.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SonaText.titleMd.copyWith(color: _hover ? light : SonaColors.text)),
            const SizedBox(height: 2),
            Text(saved.topArtists.join(', '),
                maxLines: 1, overflow: TextOverflow.ellipsis, style: SonaText.bodySm),
            const Spacer(),
            Row(children: [
              Expanded(
                child: Text(
                  [
                    l.libraryTracks(p.tracks.length),
                    if (saved.totalDuration > Duration.zero) formatTotal(saved.totalDuration),
                  ].join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SonaText.labelSm.copyWith(color: SonaColors.textMid),
                ),
              ),
              const SizedBox(width: 6),
              // Flexible: "UPDATED 16 DAYS AGO" must not overflow narrow cards.
              Flexible(
                child: Text(
                  active ? l.libraryNowPlaying.toUpperCase() : updatedLabel(l, saved.syncedAt),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: SonaText.labelSm.copyWith(
                    color: active ? light : SonaColors.textMuted,
                    fontWeight: active ? FontWeight.w600 : null,
                  ),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _SourceTag extends StatelessWidget {
  const _SourceTag({required this.source, required this.color});
  final MusicSource source;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: SonaColors.canvas.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(source.icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(source.label, style: SonaText.labelSm.copyWith(color: color, fontWeight: FontWeight.w600)),
        ]),
      );
}

class _FavButton extends StatelessWidget {
  const _FavButton({required this.active, required this.color, required this.onTap});
  final bool active;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: SonaColors.canvas.withValues(alpha: 0.7),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(active ? Icons.favorite : Icons.favorite_border,
                size: 16, color: active ? color : SonaColors.textMid),
          ),
        ),
      );
}

class _RoundPlay extends StatelessWidget {
  const _RoundPlay({required this.playing, required this.accent, required this.onTap});
  final bool playing;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.8), blurRadius: 18)],
        ),
        child: Material(
          color: accent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox.square(
              dimension: 48,
              child: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 26, color: Colors.white),
            ),
          ),
        ),
      );
}

class AddPlaylistCard extends ConsumerWidget {
  const AddPlaylistCard({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final light = SonaColors.light(ref.watch(accentColorProvider));
    final radius = BorderRadius.circular(12);
    return Material(
      color: SonaColors.canvas.withValues(alpha: 0.6),
      shape: RoundedRectangleBorder(borderRadius: radius, side: const BorderSide(color: SonaColors.specular)),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(color: SonaColors.surfaceHigh, shape: BoxShape.circle),
              child: const Icon(Icons.library_add_outlined, size: 30, color: SonaColors.textMid),
            ),
            const SizedBox(height: 12),
            Text(l.libraryAddCardTitle, style: SonaText.titleMd, textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(l.libraryAddCardBody, style: SonaText.bodySm, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Text(l.libraryAddCardAction.toUpperCase(),
                  style: SonaText.labelSm.copyWith(color: light, fontWeight: FontWeight.w600)),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward, size: 14, color: light),
            ]),
          ]),
        ),
      ),
    );
  }
}
