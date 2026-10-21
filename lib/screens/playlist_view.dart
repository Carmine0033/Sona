import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:media_overlay/l10n/app_localizations.dart';
import 'package:media_overlay/models/saved_playlist.dart';
import 'package:media_overlay/screens/playlist_detail_page.dart';
import 'package:media_overlay/screens/playlist_library_page.dart';
import 'package:media_overlay/theme/sona_tokens.dart';
import 'package:media_overlay/viewmodels/playlist_library_view_model.dart';
import 'package:media_overlay/widgets/sona_player_bar.dart';
import 'package:media_overlay/widgets/sona_ui.dart';

class PlaylistView extends ConsumerWidget {
  const PlaylistView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lib = ref.watch(playlistLibraryProvider);
    final openKey = ref.watch(openPlaylistKeyProvider);

    final body = switch (lib) {
      AsyncData(:final value) => _route(value, openKey),
      AsyncError(:final error) => Center(
        child: Text(
          playlistErrorText(AppLocalizations.of(context)!, error),
          style: SonaText.bodyMd,
        ),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };

    return ColoredBox(
      color: SonaColors.surface,
      child: Stack(children: [
        Positioned.fill(child: body),
        // Floating bar over the content; it hides itself when the internal
        // player is idle. Pages reserve kPlayerBarReserve at the bottom so
        // their last rows can scroll out from under it.
        Positioned(
          left: 20,
          right: 20,
          bottom: 16,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: const SonaPlayerBar(),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _route(List<SavedPlaylist> items, String? key) {
    if (key != null) {
      for (final p in items) {
        if (p.key == key) return PlaylistDetailPage(saved: p);
      }
    }
    // Key not found (e.g. playlist just removed): back to the library.
    return PlaylistLibraryPage(items: items);
  }
}
