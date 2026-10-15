import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:media_overlay/core/theme.dart';
import 'package:media_overlay/l10n/app_localizations.dart';
import 'package:media_overlay/models/playlist.dart';
import 'package:media_overlay/models/sona_player_view_model.dart';
import 'package:media_overlay/providers/app_providers.dart';
import 'package:media_overlay/services/artwork_service.dart';
import 'package:media_overlay/services/playlist/playlist_core.dart';
import 'package:media_overlay/viewmodels/playlist_view_model.dart';
import 'package:media_overlay/widgets/now_playing_bar.dart';
import 'package:media_overlay/widgets/sona_player_bar.dart';

class PlaylistView extends ConsumerWidget {
  const PlaylistView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playlistViewModelProvider);
    final internalActive =
        ref.watch(sonaPlayerProvider.select((s) => s.phase)) !=
        PlayerPhase.idle;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        const _LinkBar(),
        Expanded(
          child: switch (state) {
            AsyncData(value: final p?) => _PlaylistBody(playlist: p),
            AsyncError(:final error) => _Message(
              icon: Icons.error_outline,
              title: playlistErrorText(l10n, error),
              tone: ThemeColors.error,
            ),
            AsyncLoading() => const Center(child: CircularProgressIndicator()),
            _ => _Message(
              icon: Icons.queue_music,
              title: l10n.playlistEmptyTitle,
              subtitle: l10n.playlistEmptySubtitle,
            ),
          },
        ),
        // While Sona plays, its bar replaces the system player's:
        // two bars with different controls would be confusing.
        if (internalActive)
          const SonaPlayerBar()
        else
          const NowPlayingBar(),
      ],
    );
  }
}

String playlistErrorText(AppLocalizations l10n, Object error) {
  if (error is! PlaylistException) {
    return l10n.playlistErrorUnexpected('$error');
  }
  return switch (error.kind) {
    PlaylistErrorKind.invalidLink => l10n.playlistErrorInvalidLink,
    PlaylistErrorKind.unsupportedLink =>
      error.detail == 'mix automatico'
          ? l10n.playlistErrorAutoMix
          : l10n.playlistErrorUnsupported,
    PlaylistErrorKind.notFound => l10n.playlistErrorNotFound,
    PlaylistErrorKind.forbidden => l10n.playlistErrorForbidden,
    PlaylistErrorKind.rateLimited => l10n.playlistErrorRateLimited,
    PlaylistErrorKind.network => l10n.playlistErrorNetwork,
    PlaylistErrorKind.parse => l10n.playlistErrorParse,
    PlaylistErrorKind.missingKey => l10n.playlistErrorMissingKey(
      error.detail ?? l10n.thisService,
    ),
  };
}

class _LinkBar extends ConsumerStatefulWidget {
  const _LinkBar();
  @override
  ConsumerState<_LinkBar> createState() => _LinkBarState();
}

class _LinkBarState extends ConsumerState<_LinkBar> {
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final p = ref.read(playlistViewModelProvider).asData?.value;
    if (p != null) {
      _ctrl.text = p.sourceUrl;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit([String? value]) {
    final link = (value ?? _ctrl.text).trim();
    if (link.isNotEmpty) {
      ref.read(playlistViewModelProvider.notifier).load(link);
    }
  }

  Future<void> _pasteAndLoad() async {
    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text?.trim();
    if (text == null || text.isEmpty) return;
    _ctrl.text = text;
    _submit(text);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(playlistViewModelProvider, (prev, next) {
      final p = next.asData?.value;
      if (p != null && _ctrl.text.isEmpty) {
        _ctrl.text = p.sourceUrl;
      } else if (p == null && prev?.asData?.value != null) {
        _ctrl.clear();
      }
    });

    final loading = ref.watch(playlistViewModelProvider).isLoading;
    final accent = ref.watch(accentColorProvider);
    final l10n = AppLocalizations.of(context)!;
    OutlineInputBorder border(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: c),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _ctrl,
        onSubmitted: _submit,
        // readOnly, not disabled: the link stays readable while loading.
        readOnly: loading,
        style: const TextStyle(fontSize: 13, color: ThemeColors.onSurface),
        decoration: InputDecoration(
          isDense: true,
          hintText: l10n.playlistLinkHint,
          hintStyle: const TextStyle(color: ThemeColors.onSurfaceVariant),
          prefixIcon: const Icon(Icons.link, size: 18),
          prefixIconColor: ThemeColors.onSurfaceVariant,
          suffixIcon: loading
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: accent,
                    ),
                  ),
                )
              : IconButton(
                  tooltip: l10n.pasteAndLoad,
                  icon: const Icon(Icons.content_paste_go, size: 18),
                  color: accent,
                  onPressed: _pasteAndLoad,
                ),
          filled: true,
          fillColor: ThemeColors.surfaceElevated.withValues(alpha: 0.8),
          border: border(Colors.white.withValues(alpha: 0.08)),
          enabledBorder: border(Colors.white.withValues(alpha: 0.08)),
          focusedBorder: border(accent.withValues(alpha: 0.8)),
        ),
      ),
    );
  }
}

class _PlaylistBody extends ConsumerWidget {
  const _PlaylistBody({required this.playlist});
  final PlaylistData playlist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = playlist;
    final accent = ref.watch(accentColorProvider);
    final l10n = AppLocalizations.of(context)!;
    // select: rebuild only when the active track changes.
    final playingIndex = ref.watch(
      sonaPlayerProvider.select(
        (s) => identical(s.playlist, p) ? s.index : -1,
      ),
    );
    const dim = TextStyle(fontSize: 12, color: Colors.white60);

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: p.tracks.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _NetImage(url: p.coverUrl, size: 96),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.source.label.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.2,
                          color: accent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        p.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (p.owner != null) p.owner!,
                          l10n.trackCount(p.tracks.length),
                        ].join(' · '),
                        style: dim,
                      ),
                      if (p.truncated)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            l10n.playlistTruncated,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.orangeAccent,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: l10n.removePlaylist,
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () =>
                      ref.read(playlistViewModelProvider.notifier).clear(),
                ),
              ],
            ),
          );
        }
        return _TrackTile(
          index: i,
          track: p.tracks[i - 1],
          isPlaying: playingIndex == i - 1,
          onPlay: () => ref.read(sonaPlayerProvider.notifier).playAt(p, i - 1),
        );
      },
    );
  }
}

class _TrackTile extends ConsumerWidget {
  const _TrackTile({required this.index, required this.track, required this.onPlay, this.isPlaying = false});
  final int index;
  final PlaylistTrack track;
  final VoidCallback onPlay;
  final bool isPlaying;

  static const _dim = TextStyle(fontSize: 12, color: Colors.white60);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = track;
    final accent = ref.watch(accentColorProvider);
    final cover = ref.watch(trackArtworkProvider(t)).asData?.value;

    return InkWell(
      onTap: onPlay,
      child: Container(
        color: isPlaying ? accent.withValues(alpha: 0.08) : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(children: [
          SizedBox(
            width: 28,
            child: isPlaying
                ? Icon(Icons.graphic_eq, size: 16, color: accent)
                : Text('$index', textAlign: TextAlign.right, style: _dim),
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: _NetImage(url: cover, size: 40),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Artist on top, title below.
              Text(t.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isPlaying ? accent : null,
                  )),
              Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: _dim),
            ]),
          ),
          if (t.album != null)
            Expanded(flex: 2, child: Text(t.album!, maxLines: 1, overflow: TextOverflow.ellipsis, style: _dim)),
          if (t.duration != null) Text(_fmt(t.duration!), style: _dim),
        ]),
      ),
    );
  }

  static String _fmt(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
}

class _NetImage extends StatelessWidget {
  const _NetImage({required this.url, required this.size});
  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: size,
      color: Colors.white10,
      child: Icon(Icons.music_note, size: size * 0.4, color: Colors.white38),
    );
    if (url == null) return placeholder;
    return Image.network(
      url!,
      width: size,
      height: size,
      fit: BoxFit.cover,
      // Decode at display size: 500 full-res covers would take hundreds of MB.
      cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    this.subtitle,
    this.tone,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? tone;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 44,
              color: (tone ?? Colors.white).withValues(alpha: 0.45),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ThemeColors.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: ThemeColors.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
