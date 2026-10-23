import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:media_overlay/l10n/app_localizations.dart';
import 'package:media_overlay/models/playlist.dart';
import 'package:media_overlay/models/saved_playlist.dart';
import 'package:media_overlay/models/sona_player_view_model.dart';
import 'package:media_overlay/providers/app_providers.dart';
import 'package:media_overlay/services/artwork_service.dart';
import 'package:media_overlay/theme/sona_tokens.dart';
import 'package:media_overlay/utils/search.dart';
import 'package:media_overlay/widgets/playlist_cover.dart';
import 'package:url_launcher/url_launcher.dart';

// Fixed widths shared by header and rows, so the columns stay aligned.
const _numW = 36.0;
const _durW = 56.0;
const _moreW = 36.0;
const _rowH = 56.0;
const _rowPad = 12.0; // horizontal padding inside each row
const _gap = 12.0;

// No card around the table: rows stand out only by their hover/active wash.
const _hairline = Color(0x14FFFFFF); // white 8%
const _hoverWash = Color(0x0DFFFFFF); // white 5%

enum TrackSortColumn { title, album, duration }

/// [indices] sorted by [column] (null = playlist order). Text compares
/// ignoring case and accents; missing values always go last; ties keep the
/// playlist order so the result is stable.
List<int> sortTrackIndices(
  List<int> indices,
  List<PlaylistTrack> tracks, {
  required TrackSortColumn? column,
  required bool ascending,
  String? Function(PlaylistTrack t)? albumOf,
}) {
  if (column == null) return indices;
  Comparable<dynamic>? keyOf(PlaylistTrack t) {
    switch (column) {
      case TrackSortColumn.title:
        return normalizeSearch(t.title);
      case TrackSortColumn.album:
        final a = (albumOf ?? (t) => t.album)(t);
        return a == null || a.trim().isEmpty ? null : normalizeSearch(a);
      case TrackSortColumn.duration:
        return t.duration?.inMilliseconds;
    }
  }

  final keys = {for (final i in indices) i: keyOf(tracks[i])};
  return [...indices]..sort((a, b) {
      final ka = keys[a], kb = keys[b];
      if (ka == null || kb == null) {
        if (ka == null && kb == null) return a.compareTo(b);
        return ka == null ? 1 : -1; // missing values last, both directions
      }
      final c = ka.compareTo(kb);
      if (c != 0) return ascending ? c : -c;
      return a.compareTo(b);
    });
}

/// Track list: flat rows with cover, title and artist, duration and a "…"
/// menu, under a pinned sortable header.
class TrackTable extends ConsumerWidget {
  const TrackTable({
    super.key,
    required this.saved,
    required this.indices,
    required this.query,
    required this.onPlay,
    this.sortColumn,
    this.ascending = true,
    this.onSort,
  });

  final SavedPlaylist saved;
  final List<int> indices; // ORIGINAL indexes to show (all or filtered), in display order
  final String query;
  final ValueChanged<int> onPlay;

  /// Current sort (null = playlist order) and the header tap handler.
  final TrackSortColumn? sortColumn;
  final bool ascending;
  final ValueChanged<TrackSortColumn?>? onSort;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final accent = ref.watch(accentColorProvider);

    // select(): rebuild only when the active track or play/pause changes,
    // not on volume, shuffle or other player fields.
    final activeIndex = ref.watch(sonaPlayerProvider.select(
      (s) => s.playlist != null && saved.matches(s.playlist!) ? s.index : -1,
    ));
    final isPlaying = ref.watch(sonaPlayerProvider.select((s) => s.phase == PlayerPhase.playing));

    return LayoutBuilder(builder: (context, c) {
      // Wide: the album gets its own sortable column. Narrow: it moves into
      // the subtitle ("Artist — Album").
      final showAlbum = c.maxWidth >= 680;
      return Column(children: [
        _HeaderRow(
          showAlbum: showAlbum,
          sortColumn: sortColumn,
          ascending: ascending,
          accent: accent,
          onSort: onSort,
        ),
        const Divider(height: 1, thickness: 1, color: _hairline),
        Expanded(
          child: indices.isEmpty
              ? Center(child: Text(l.searchNoResults, style: SonaText.bodyMd))
              : _TrackList(
                  itemCount: indices.length,
                  itemBuilder: (_, i) {
                    final ti = indices[i];
                    return _TrackRow(
                      key: ValueKey(ti),
                      number: ti + 1,
                      track: saved.data.tracks[ti],
                      sourceLabel: saved.data.source.label,
                      active: ti == activeIndex,
                      playing: ti == activeIndex && isPlaying,
                      showAlbum: showAlbum,
                      query: query,
                      accent: accent,
                      onTap: () => onPlay(ti),
                    );
                  },
                ),
        ),
      ]);
    });
  }
}

/// Scrolling rows with their own controller: on desktop the ListView is not
/// the primary scroll view, so a Scrollbar without one has no position to
/// paint and throws on every wheel scroll.
class _TrackList extends StatefulWidget {
  const _TrackList({required this.itemCount, required this.itemBuilder});
  final int itemCount;
  final NullableIndexedWidgetBuilder itemBuilder;

  @override
  State<_TrackList> createState() => _TrackListState();
}

class _TrackListState extends State<_TrackList> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _controller,
      child: ListView.builder(
        controller: _controller,
        padding: const EdgeInsets.only(top: 8, bottom: 8, right: 4),
        // Fixed height: Flutter doesn't measure every row,
        // so scrolling stays smooth even with 1000 tracks.
        itemExtent: _rowH,
        itemCount: widget.itemCount,
        itemBuilder: widget.itemBuilder,
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.showAlbum,
    required this.sortColumn,
    required this.ascending,
    required this.accent,
    required this.onSort,
  });
  final bool showAlbum, ascending;
  final TrackSortColumn? sortColumn;
  final Color accent;
  final ValueChanged<TrackSortColumn?>? onSort;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    Widget cell(String label, TrackSortColumn? col, MainAxisAlignment align, {IconData? icon}) =>
        _HeaderCell(
          label: label,
          icon: icon,
          align: align,
          sorted: col != null && col == sortColumn,
          ascending: ascending,
          accent: accent,
          tooltip: col == null ? l.sortOriginal : l.sortBy(label),
          onTap: onSort == null ? null : () => onSort!(col),
        );

    return Padding(
      // Same insets as the rows (+4 for the list's scrollbar gutter),
      // so every label sits over its column.
      padding: const EdgeInsets.fromLTRB(_rowPad, 0, _rowPad + 4, 4),
      child: Row(children: [
        SizedBox(width: _numW, child: cell('#', null, MainAxisAlignment.center)),
        const SizedBox(width: _gap),
        Expanded(
          flex: 5,
          child: cell(l.colTrack.toUpperCase(), TrackSortColumn.title, MainAxisAlignment.start),
        ),
        if (showAlbum)
          Expanded(
            flex: 3,
            child: cell(l.colAlbum.toUpperCase(), TrackSortColumn.album, MainAxisAlignment.start),
          ),
        SizedBox(
          width: _durW,
          // Clock icon only: the tooltip names the column.
          child: cell(l.colDuration, TrackSortColumn.duration, MainAxisAlignment.end,
              icon: Icons.schedule_rounded),
        ),
        const SizedBox(width: _moreW),
      ]),
    );
  }
}

/// Clickable column title: tap to sort ascending, again for descending,
/// a third time to go back to the playlist order. "#" resets right away.
class _HeaderCell extends StatefulWidget {
  const _HeaderCell({
    required this.label,
    required this.align,
    required this.sorted,
    required this.ascending,
    required this.accent,
    required this.tooltip,
    required this.onTap,
    this.icon,
  });

  final String label, tooltip;
  final IconData? icon;
  final MainAxisAlignment align;
  final bool sorted, ascending;
  final Color accent;
  final VoidCallback? onTap;

  @override
  State<_HeaderCell> createState() => _HeaderCellState();
}

class _HeaderCellState extends State<_HeaderCell> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final color = w.sorted
        ? SonaColors.light(w.accent)
        : _hover
            ? SonaColors.text
            : SonaColors.textMuted;
    final style = SonaText.labelMd.copyWith(color: color, fontWeight: w.sorted ? FontWeight.w600 : null);
    final arrow = Icon(
      w.ascending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
      size: 12,
      color: color,
    );
    // Right-aligned column: the arrow goes before the label, so the label
    // keeps its right edge on the column edge.
    final arrowFirst = w.align == MainAxisAlignment.end;

    return Tooltip(
      message: w.tooltip,
      child: MouseRegion(
        cursor: w.onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: w.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(mainAxisAlignment: w.align, children: [
              if (w.sorted && arrowFirst) ...[arrow, const SizedBox(width: 4)],
              if (w.icon != null)
                Icon(w.icon, size: 14, color: color)
              else
                Flexible(
                  child: Text(w.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
                ),
              if (w.sorted && !arrowFirst) ...[const SizedBox(width: 4), arrow],
            ]),
          ),
        ),
      ),
    );
  }
}

class _TrackRow extends ConsumerStatefulWidget {
  const _TrackRow({
    super.key,
    required this.number,
    required this.track,
    required this.sourceLabel,
    required this.active,
    required this.playing,
    required this.showAlbum,
    required this.query,
    required this.accent,
    required this.onTap,
  });

  final int number;
  final PlaylistTrack track;
  final String sourceLabel;
  final bool active, playing, showAlbum;
  final String query;
  final Color accent;
  final VoidCallback onTap;

  @override
  ConsumerState<_TrackRow> createState() => _TrackRowState();
}

enum _TrackAction { play, copy, open }

class _TrackRowState extends ConsumerState<_TrackRow> {
  bool _hover = false;
  bool _menuOpen = false; // keeps the row lit while its menu is open

  static String _fmt(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  // Same menu from the "…" button and from a right click on the row.
  Future<void> _showMenu(Offset globalPos) async {
    final l = AppLocalizations.of(context)!;
    final w = widget;
    final t = w.track;
    final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
    final local = overlay.globalToLocal(globalPos);

    PopupMenuItem<_TrackAction> item(_TrackAction v, IconData icon, String label) => PopupMenuItem(
          value: v,
          height: 40,
          child: Row(children: [
            Icon(icon, size: 18, color: SonaColors.textMid),
            const SizedBox(width: 12),
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SonaText.bodyMd.copyWith(color: SonaColors.text)),
            ),
          ]),
        );

    setState(() => _menuOpen = true);
    final choice = await showMenu<_TrackAction>(
      context: context,
      position: RelativeRect.fromSize(local & Size.zero, overlay.size),
      color: SonaColors.surfaceHigh,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: _hairline),
      ),
      items: [
        item(
          _TrackAction.play,
          w.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
          w.playing ? l.libraryPause : l.libraryPlayNow,
        ),
        item(_TrackAction.copy, Icons.content_copy_rounded, l.trackCopy),
        if (t.openUrl != null)
          item(_TrackAction.open, Icons.open_in_new_rounded, l.trackOpenIn(w.sourceLabel)),
      ],
    );
    if (!mounted) return;
    setState(() => _menuOpen = false);

    switch (choice) {
      case _TrackAction.play:
        w.onTap();
      case _TrackAction.copy:
        final messenger = ScaffoldMessenger.maybeOf(context);
        await Clipboard.setData(ClipboardData(text: '${t.title} – ${t.artist}'));
        messenger?.showSnackBar(SnackBar(content: Text(l.trackCopied)));
      case _TrackAction.open:
        final uri = Uri.tryParse(t.openUrl!);
        if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final w = widget;
    final t = w.track;
    final light = SonaColors.light(w.accent);
    final meta = ref.watch(trackMetaProvider(t)).asData?.value;
    final cover = t.artworkUrl ?? meta?.cover;
    final album = t.album ?? meta?.album;
    final hasAlbum = album != null && album.trim().isNotEmpty;
    final match = TextStyle(color: light, fontWeight: FontWeight.w700);
    final lit = _hover || _menuOpen;

    // Background: active (accent tint) > hover (white wash) > nothing.
    final bg = w.active
        ? w.accent.withValues(alpha: lit ? 0.16 : 0.10)
        : lit
            ? _hoverWash
            : Colors.transparent;

    // "#" column: number, play/pause on hover, or equalizer while playing.
    final Widget numCell = _hover
        ? Icon(w.playing ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 20, color: SonaColors.text)
        : w.playing
            ? Icon(Icons.graphic_eq_rounded, size: 18, color: light)
            : Text('${w.number}',
                textAlign: TextAlign.center,
                style: SonaText.labelMd.copyWith(
                  fontSize: 11,
                  color: w.active ? light : SonaColors.textMuted,
                ));

    final subtitleStyle = SonaText.bodySm.copyWith(fontSize: 12);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: w.onTap,
        onSecondaryTapUp: (d) => _showMenu(d.globalPosition),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: _rowPad),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            SizedBox(width: _numW, child: Center(child: numCell)),
            const SizedBox(width: _gap),

            // TRACK: cover + title + artist (— album when narrow)
            Expanded(
              flex: 5,
              child: Row(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SonaNetImage(url: cover, size: 40),
                ),
                const SizedBox(width: _gap),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        highlightMatch(
                          t.title,
                          w.query,
                          SonaText.titleMd.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: w.active ? light : SonaColors.text,
                          ),
                          match,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text.rich(
                        TextSpan(children: [
                          highlightMatch(t.artist, w.query, subtitleStyle, match),
                          if (!w.showAlbum && hasAlbum) TextSpan(text: '  —  $album', style: subtitleStyle),
                        ]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: _gap),
              ]),
            ),

            // ALBUM
            if (w.showAlbum)
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.only(right: _gap),
                  child: Text(
                    hasAlbum ? album : '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SonaText.bodyMd.copyWith(
                      color: hasAlbum ? SonaColors.textMuted : SonaColors.outline,
                    ),
                  ),
                ),
              ),

            // DURATION: right-aligned, monospace digits so they don't jitter
            SizedBox(
              width: _durW,
              child: Text(
                t.duration == null ? '' : _fmt(t.duration!),
                textAlign: TextAlign.right,
                style: SonaText.labelMd.copyWith(
                  fontSize: 11,
                  color: w.active ? light : SonaColors.textMuted,
                ),
              ),
            ),

            // "…" more actions
            SizedBox(
              width: _moreW,
              child: Align(
                alignment: Alignment.centerRight,
                child: _MoreButton(tooltip: l.trackMore, emphasized: lit, onOpen: _showMenu),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Small round "…" button, quiet until its row is hovered.
class _MoreButton extends StatelessWidget {
  const _MoreButton({required this.tooltip, required this.emphasized, required this.onOpen});
  final String tooltip;
  final bool emphasized;
  final ValueChanged<Offset> onOpen;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        type: MaterialType.transparency,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          // Open the menu under the button, not under the cursor.
          onTap: () {
            final box = context.findRenderObject()! as RenderBox;
            onOpen(box.localToGlobal(Offset(0, box.size.height)));
          },
          child: SizedBox(
            width: 28,
            height: 28,
            child: Icon(
              Icons.more_horiz_rounded,
              size: 18,
              color: emphasized ? SonaColors.text : SonaColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
