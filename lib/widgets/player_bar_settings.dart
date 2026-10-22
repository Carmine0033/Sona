import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:media_overlay/l10n/app_localizations.dart';
import 'package:media_overlay/providers/app_providers.dart';
import 'package:media_overlay/services/bar_media.dart';
import 'package:media_overlay/theme/sona_tokens.dart';
import 'package:media_overlay/widgets/bar_icons.dart';

class PlayerBarSettings extends ConsumerWidget {
  const PlayerBarSettings({super.key});

  Future<void> _pick(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context)!;
    final r = await pickBarMedia(ref);
    if (!context.mounted) return;
    final msg = switch (r) {
      BarMediaResult.tooLarge => l.settingsBarTooLarge,
      BarMediaResult.failed => l.settingsBarFailed,
      _ => null,
    };
    if (msg != null) ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final accent = ref.watch(accentColorProvider);
    final bg = ref.watch(barBackgroundProvider);
    final media = ref.watch(barMediaPathProvider);
    final dim = ref.watch(barDimProvider);
    final iconStyle = ref.watch(barIconStyleProvider);

    String bgLabel(BarBackground b) => switch (b) {
          BarBackground.glass => l.barBgGlass,
          BarBackground.albumBlur => l.barBgAlbum,
          BarBackground.custom => l.barBgCustom,
        };
    String styleLabel(BarIconStyle s) => switch (s) {
          BarIconStyle.filled => l.iconStyleFilled,
          BarIconStyle.outlined => l.iconStyleOutlined,
          BarIconStyle.rounded => l.iconStyleRounded,
          BarIconStyle.sharp => l.iconStyleSharp,
        };

    // The section title is already shown by the settings card header.
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l.settingsBarBackground.toUpperCase(), style: SonaText.labelMd),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final b in BarBackground.values)
          ChoiceChip(
            label: Text(bgLabel(b)),
            selected: bg == b,
            selectedColor: accent,
            onSelected: (_) {
              // "Custom" without a file yet: open the picker right away.
              if (b == BarBackground.custom && media == null) {
                _pick(context, ref);
              } else {
                ref.read(barBackgroundProvider.notifier).state = b;
              }
            },
          ),
      ]),

      if (bg == BarBackground.custom) ...[
        const SizedBox(height: 8),
        Row(children: [
          OutlinedButton.icon(
            onPressed: () => _pick(context, ref),
            icon: const Icon(Icons.gif_box_outlined, size: 18),
            label: Text(media == null ? l.settingsBarPick : l.settingsBarChange),
          ),
          if (media != null) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(media.split(RegExp(r'[\\/]')).last,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: SonaText.bodySm),
            ),
            IconButton(
              tooltip: l.libraryRemove,
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: () => clearBarMedia(ref),
            ),
          ],
        ]),
      ],

      const SizedBox(height: 16),
      Text('${l.settingsBarDim.toUpperCase()}  $dim%', style: SonaText.labelMd),
      Slider(
        min: 0,
        max: 90,
        divisions: 18,
        value: dim.toDouble(),
        activeColor: accent,
        onChanged: (v) => ref.read(barDimProvider.notifier).state = v.round(),
      ),

      const SizedBox(height: 8),
      Text(l.settingsBarIcons.toUpperCase(), style: SonaText.labelMd),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final s in BarIconStyle.values)
          ChoiceChip(
            // Style preview right in the chip.
            avatar: Icon(BarIconSet.of(s).play, size: 18),
            label: Text(styleLabel(s)),
            selected: iconStyle == s,
            selectedColor: accent,
            onSelected: (_) => ref.read(barIconStyleProvider.notifier).state = s,
          ),
      ]),
    ]);
  }
}