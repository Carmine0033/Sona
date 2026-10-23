import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:media_overlay/l10n/app_localizations.dart';
import 'package:media_overlay/models/release_notes.dart';
import 'package:media_overlay/providers/app_providers.dart';
import 'package:media_overlay/theme/sona_tokens.dart';
import 'package:media_overlay/viewmodels/whats_new_view_model.dart';
import 'package:media_overlay/widgets/sona_ui.dart';
import 'package:media_overlay/widgets/whats_new/whats_new_sheet.dart';

class WhatsNewToast extends ConsumerStatefulWidget {
  const WhatsNewToast({super.key});
  @override
  ConsumerState<WhatsNewToast> createState() => _WhatsNewToastState();
}

class _WhatsNewToastState extends ConsumerState<WhatsNewToast> {
  bool _ready = false;
  late final Timer _delay;

  @override
  void initState() {
    super.initState();
    // Small delay so the banner doesn't land together with the startup.
    _delay = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    _delay.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(whatsNewProvider).asData?.value;
    final latest = (s == null || s.unseen.isEmpty) ? null : s.unseen.first;
    final show = _ready && s != null && s.showToast && latest != null;

    return IgnorePointer(
      ignoring: !show,
      child: AnimatedSlide(
        offset: show ? Offset.zero : const Offset(0, 0.15),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: show ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: latest == null ? const SizedBox.shrink() : _ToastCard(release: latest),
        ),
      ),
    );
  }
}

class _ToastCard extends ConsumerWidget {
  const _ToastCard({required this.release});
  final ReleaseNotes release;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final accent = ref.watch(accentColorProvider);
    final summary = pickLang(release.summary, lang);

    return Material(
      color: SonaColors.surfaceHigh,
      borderRadius: BorderRadius.circular(12),
      elevation: 0,
      child: Container(
        width: 320,
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: SonaColors.outline),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 32, offset: Offset(0, 12))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(
                    text: l.whatsNewToastTitle(release.version),
                    style: SonaText.bodyMd.copyWith(color: SonaColors.text, fontWeight: FontWeight.w600),
                  ),
                  if (summary.isNotEmpty) TextSpan(text: ' $summary'),
                ]),
                style: SonaText.bodyMd,
              ),
            ),
            IconButton(
              tooltip: l.searchClose,
              icon: const Icon(Icons.close, size: 16),
              color: SonaColors.textMuted,
              visualDensity: VisualDensity.compact,
              onPressed: () => ref.read(whatsNewProvider.notifier).dismissToast(),
            ),
          ]),
          const SizedBox(height: 10),
          SonaPrimaryButton(
            icon: Icons.auto_awesome_outlined,
            label: l.whatsNewSeeAll,
            accent: accent,
            onTap: () => openWhatsNewSheet(context, ref),
          ),
        ]),
      ),
    );
  }
}