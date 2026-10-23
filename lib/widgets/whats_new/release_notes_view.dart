import 'package:flutter/material.dart';

import 'package:media_overlay/l10n/app_localizations.dart';
import 'package:media_overlay/models/release_notes.dart';
import 'package:media_overlay/theme/sona_tokens.dart';

class ReleaseNotesView extends StatelessWidget {
  const ReleaseNotesView({super.key, required this.release, this.installed = false});
  final ReleaseNotes release;
  final bool installed;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final date = release.date == null
        ? null
        : MaterialLocalizations.of(context).formatMediumDate(release.date!);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
        Text('Sona ${release.version}', style: SonaText.titleMd),
        const Spacer(),
        Text(
          [?date, if (installed) l.whatsNewInstalled].join(' · ').toUpperCase(),
          style: SonaText.labelSm,
        ),
      ]),
      const SizedBox(height: 12),
      _Group(title: l.whatsNewAdded, items: release.added, mark: '+', lang: lang),
      _Group(title: l.whatsNewChanged, items: release.changed, mark: '~', lang: lang),
      _Group(title: l.whatsNewFixed, items: release.fixed, mark: '✓', lang: lang, markColor: const Color(0xFF7FD6A8)),
    ]);
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.items, required this.mark, required this.lang, this.markColor});
  final String title, mark, lang;
  final List<LocalizedText> items;
  final Color? markColor;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title.toUpperCase(), style: SonaText.labelSm.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        for (final it in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                width: 16,
                child: Text(mark,
                    style: SonaText.labelMd.copyWith(color: markColor ?? SonaColors.light(const Color(0xFF9D4EDD)))),
              ),
              Expanded(child: Text(pickLang(it, lang), style: SonaText.bodyMd)),
            ]),
          ),
      ]),
    );
  }
}