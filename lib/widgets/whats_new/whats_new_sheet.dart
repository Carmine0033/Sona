import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:media_overlay/l10n/app_localizations.dart';
import 'package:media_overlay/services/external_link.dart';
import 'package:media_overlay/theme/sona_tokens.dart';
import 'package:media_overlay/viewmodels/whats_new_view_model.dart';
import 'package:media_overlay/widgets/whats_new/release_notes_view.dart';

const _releasesUrl = 'https://github.com/Carmine0033/Sona/releases';

Future<void> openWhatsNewSheet(BuildContext context, WidgetRef ref) {
  ref.read(whatsNewProvider.notifier).markRead(); // opened = read
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: SonaColors.abyss.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (_, _, _) => const Align(alignment: Alignment.centerRight, child: _Sheet()),
    transitionBuilder: (_, anim, _, child) => SlideTransition(
      position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(
        CurvedAnimation(parent: anim, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic),
      ),
      child: child,
    ),
  );
}

class _Sheet extends ConsumerWidget {
  const _Sheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final s = ref.watch(whatsNewProvider).asData?.value;
    final releases = s?.toShow ?? const [];

    return Material(
      color: SonaColors.surfaceHigh,
      child: Container(
        width: 380,
        height: double.infinity,
        decoration: const BoxDecoration(border: Border(left: BorderSide(color: SonaColors.outline))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 8, 8),
            child: Row(children: [
              Expanded(child: Text(l.whatsNewTitle, style: SonaText.headlineMd)),
              IconButton(
                tooltip: l.searchClose,
                icon: const Icon(Icons.close, size: 18),
                color: SonaColors.textMid,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ]),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              itemCount: releases.length,
              separatorBuilder: (_, _) => const Divider(height: 28, color: SonaColors.outline),
              itemBuilder: (_, i) => ReleaseNotesView(
                release: releases[i],
                installed: s?.isInstalled(releases[i]) ?? false,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
            child: TextButton.icon(
              onPressed: () => openExternal(_releasesUrl),
              icon: const Icon(Icons.open_in_new, size: 14),
              label: Text(l.whatsNewAllReleases),
            ),
          ),
        ]),
      ),
    );
  }
}