import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:media_overlay/l10n/app_localizations.dart';
import 'package:media_overlay/models/playlist.dart';
import 'package:media_overlay/models/saved_playlist.dart';
import 'package:media_overlay/models/sona_player_view_model.dart';
import 'package:media_overlay/providers/app_providers.dart';
import 'package:media_overlay/theme/sona_tokens.dart';
import 'package:media_overlay/viewmodels/playlist_library_view_model.dart';
import 'package:media_overlay/widgets/playlist_card.dart';
import 'package:media_overlay/widgets/playlist_cover.dart';
import 'package:media_overlay/widgets/sona_player_bar.dart' show kPlayerBarReserve;
import 'package:media_overlay/widgets/sona_ui.dart';

class PlaylistLibraryPage extends ConsumerStatefulWidget {
  const PlaylistLibraryPage({super.key, required this.items});
  final List<SavedPlaylist> items;

  @override
  ConsumerState<PlaylistLibraryPage> createState() => _PlaylistLibraryPageState();
}

class _PlaylistLibraryPageState extends ConsumerState<PlaylistLibraryPage> {
  final _input = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _add([String? value]) async {
    final link = (value ?? _input.text).trim();
    if (link.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(playlistLibraryProvider.notifier).add(link);
      _input.clear();
    } catch (e) {
      if (mounted) setState(() => _error = playlistErrorText(AppLocalizations.of(context)!, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _paste() async {
    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text?.trim();
    if (text == null || text.isEmpty) return;
    _input.text = text;
    await _add(text);
  }

  void _focusInput() {
    _scroll.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    _focus.requestFocus();
  }

  SavedPlaylist? _hero(List<SavedPlaylist> items, SonaPlayerState s) {
    if (items.isEmpty) return null;
    final current = s.playlist;
    if (current != null) {
      for (final p in items) {
        if (p.matches(current)) return p;
      }
    }
    return items.first;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final accent = ref.watch(accentColorProvider);
    final filter = ref.watch(libraryFilterProvider);
    final items = widget.items;
    final visible = items.where(filter.accepts).toList();
    final hero = _hero(items, ref.watch(sonaPlayerProvider));

    return Stack(children: [
      Positioned(top: -140, right: 120, child: _Glow(color: accent, size: 440)),
      Positioned(top: 300, left: -140, child: _Glow(color: SonaColors.light(accent), size: 360)),
      Positioned.fill(
        child: CustomScrollView(controller: _scroll, slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            sliver: SliverList.list(children: [
              _LinkInput(
                controller: _input,
                focus: _focus,
                busy: _busy,
                accent: accent,
                onSubmit: _add,
                onPaste: _paste,
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Text(_error!, style: SonaText.bodySm.copyWith(color: SonaColors.error)),
                ),
              const SizedBox(height: 20),
              if (items.isNotEmpty) _FilterBar(items: items),
              const SizedBox(height: 20),
              if (hero != null) ...[_HeroCard(saved: hero), const SizedBox(height: 32)],
              Row(children: [
                Text(l.libraryYourPlaylists, style: SonaText.headlineMd),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: SonaColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(l.libraryAvailable(visible.length).toUpperCase(),
                      style: SonaText.labelSm.copyWith(
                          color: SonaColors.light(accent), fontWeight: FontWeight.w600)),
                ),
              ]),
              const SizedBox(height: 12),
            ]),
          ),
          SliverPadding(
            // Room for the floating player bar below the last row.
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24 + kPlayerBarReserve),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 260,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                childAspectRatio: 0.70,
              ),
              itemCount: visible.length + 1,
              itemBuilder: (_, i) => i == visible.length
                  ? AddPlaylistCard(onTap: _focusInput)
                  : PlaylistCard(saved: visible[i]),
            ),
          ),
        ]),
      ),
    ]);
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color.withValues(alpha: 0.14), color.withValues(alpha: 0)],
            ),
          ),
        ),
      );
}

class _LinkInput extends StatelessWidget {
  const _LinkInput({
    required this.controller,
    required this.focus,
    required this.busy,
    required this.accent,
    required this.onSubmit,
    required this.onPaste,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final bool busy;
  final Color accent;
  final Future<void> Function([String?]) onSubmit;
  final VoidCallback onPaste;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final light = SonaColors.light(accent);
    final mono = SonaText.labelLg.copyWith(fontWeight: FontWeight.w400);

    return Row(children: [
      Expanded(
        child: ListenableBuilder(
          listenable: focus,
          builder: (context, child) => AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: SonaColors.surfaceLow.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: focus.hasFocus ? light : SonaColors.specular),
              boxShadow: [
                if (focus.hasFocus) BoxShadow(color: accent.withValues(alpha: 0.25), blurRadius: 20),
              ],
            ),
            child: child,
          ),
          child: Row(children: [
            Icon(Icons.dataset_outlined, size: 20, color: light),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focus,
                enabled: !busy,
                onSubmitted: (_) => onSubmit(),
                style: mono.copyWith(color: SonaColors.text),
                cursorColor: accent,
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: l.libraryInputHint,
                  hintStyle: mono.copyWith(color: SonaColors.textMuted),
                ),
              ),
            ),
            Material(
              color: SonaColors.surfaceHigh,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: busy ? null : onPaste,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.content_paste, size: 16, color: light),
                    const SizedBox(width: 6),
                    Text(l.libraryPaste, style: SonaText.labelSm.copyWith(color: light)),
                  ]),
                ),
              ),
            ),
            ValueListenableBuilder(
              valueListenable: controller,
              builder: (_, v, _) => v.text.isEmpty
                  ? const SizedBox(width: 4)
                  : IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      color: SonaColors.textMuted,
                      onPressed: controller.clear,
                    ),
            ),
          ]),
        ),
      ),
      const SizedBox(width: 12),
      SonaPrimaryButton(icon: Icons.add, label: l.libraryAdd, accent: accent, busy: busy, onTap: onSubmit),
    ]);
  }
}

class _FilterBar extends ConsumerWidget {
  const _FilterBar({required this.items});
  final List<SavedPlaylist> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final accent = ref.watch(accentColorProvider);
    final filter = ref.watch(libraryFilterProvider);
    final n = ref.read(libraryFilterProvider.notifier);

    final counts = <MusicSource, int>{};
    for (final p in items) {
      counts[p.data.source] = (counts[p.data.source] ?? 0) + 1;
    }
    final favs = items.where((p) => p.favorite).length;

    return Wrap(spacing: 6, runSpacing: 6, children: [
      _Chip(
        label: '${l.libraryAll} (${items.length})',
        active: filter.source == null && !filter.favoritesOnly,
        accent: accent,
        onTap: n.all,
      ),
      // Only services present in the library: no "Deezer (0)" chip.
      for (final s in MusicSource.values)
        if (counts[s] != null)
          _Chip(
            label: '${s.label} (${counts[s]})',
            dot: true,
            active: filter.source == s,
            accent: accent,
            onTap: () => n.source(s),
          ),
      _Chip(
        label: favs > 0 ? '${l.libraryFavorites} ($favs)' : l.libraryFavorites,
        icon: Icons.favorite_border,
        active: filter.favoritesOnly,
        accent: accent,
        onTap: n.favorites,
      ),
    ]);
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.active,
    required this.accent,
    required this.onTap,
    this.dot = false,
    this.icon,
  });

  final String label;
  final bool active, dot;
  final Color accent;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final light = SonaColors.light(accent);
    final fg = active ? Colors.white : SonaColors.textMid;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        boxShadow: [if (active) BoxShadow(color: accent.withValues(alpha: 0.5), blurRadius: 12)],
      ),
      child: Material(
        color: active ? accent : SonaColors.surfaceLow,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (dot)
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(color: active ? Colors.white : light, shape: BoxShape.circle),
                ),
              if (icon != null) ...[Icon(icon, size: 14, color: active ? Colors.white : light), const SizedBox(width: 6)],
              Text(label,
                  style: SonaText.labelSm.copyWith(
                      color: fg, fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends ConsumerWidget {
  const _HeroCard({required this.saved});
  final SavedPlaylist saved;

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
    final current = active ? s.track : null;

    final info = Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Wrap(spacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 8)],
          ),
          child: Text(l.librarySourcePlaylist(p.source.label).toUpperCase(),
              style: SonaText.labelSm.copyWith(color: light, fontWeight: FontWeight.w700)),
        ),
        if (playing)
          Row(mainAxisSize: MainAxisSize.min, children: [
            _PulseDot(color: light),
            const SizedBox(width: 6),
            Text(l.libraryNowPlaying.toUpperCase(),
                style: SonaText.labelSm.copyWith(color: light, fontWeight: FontWeight.w600)),
          ]),
      ]),
      const SizedBox(height: 6),
      Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: SonaText.headlineLg),
      const SizedBox(height: 4),
      Text(
        [
          if (p.owner != null) p.owner!,
          l.libraryTracks(p.tracks.length),
          if (saved.totalDuration > Duration.zero) formatTotal(saved.totalDuration),
        ].join('  •  '),
        style: SonaText.labelMd,
      ),
      if (current != null) ...[
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: SonaColors.canvas.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.equalizer, size: 16, color: light),
            const SizedBox(width: 8),
            Text(l.libraryNowPlayingTicker, style: SonaText.labelSm),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '${current.title} — ${current.artist}  (${s.index + 1}/${p.tracks.length})',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SonaText.labelSm.copyWith(color: light, fontWeight: FontWeight.w600),
              ),
            ),
          ]),
        ),
      ],
    ]);

    final actions = Wrap(spacing: 8, runSpacing: 8, children: [
      SonaPrimaryButton(
        icon: playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
        label: playing ? l.libraryPause : l.libraryPlayNow,
        accent: accent,
        large: true,
        onTap: () => active ? vm.togglePlay() : vm.playAt(p, 0),
      ),
      SonaSecondaryButton(
        icon: Icons.sync,
        label: l.librarySync,
        onTap: () => syncWithFeedback(context, ref, saved.key),
      ),
      SonaSecondaryButton(
        icon: Icons.queue_music,
        label: l.libraryTracks(p.tracks.length),
        onTap: () => ref.read(openPlaylistKeyProvider.notifier).open(saved.key),
      ),
    ]);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        // Uniform border: Flutter doesn't allow borderRadius with a top-only border.
        border: Border.all(color: SonaColors.specular),
        gradient: const LinearGradient(
          colors: [SonaColors.surfaceLow, SonaColors.surfaceMid, SonaColors.surfaceLow],
        ),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 24, offset: Offset(0, 8))],
      ),
      child: LayoutBuilder(builder: (context, c) {
        final cover = PlaylistCollage(saved: saved, size: 144);
        if (c.maxWidth < 760) {
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [cover, const SizedBox(width: 20), Expanded(child: info)]),
            const SizedBox(height: 16),
            actions,
          ]);
        }
        return Row(children: [
          cover,
          const SizedBox(width: 20),
          Expanded(child: info),
          const SizedBox(width: 20),
          actions,
        ]);
      }),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color});
  final Color color;
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween(begin: 0.35, end: 1.0).animate(_c),
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: widget.color, blurRadius: 6)],
          ),
        ),
      );
}
