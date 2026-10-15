import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:media_overlay/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../providers/app_providers.dart';
import 'settings_card.dart' show settingsLabelWidth, settingsLabelStyle;

class AccentPickerRow extends ConsumerStatefulWidget {
  const AccentPickerRow({super.key});
  @override
  ConsumerState<AccentPickerRow> createState() => _AccentPickerRowState();
}

class _AccentPickerRowState extends ConsumerState<AccentPickerRow> {
  late final TextEditingController _hex;
  bool _hexError = false;

  @override
  void initState() {
    super.initState();
    _hex = TextEditingController(text: _toHex(ref.read(accentColorProvider)));
  }

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  String _toHex(Color c) =>
      '#${c.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';

  Color? _parseHex(String s) {
    var h = s.trim().replaceAll('#', '');
    if (h.length == 6) h = 'FF$h';
    if (h.length != 8) return null;
    final v = int.tryParse(h, radix: 16);
    return v == null ? null : Color(v);
  }

  void _apply(Color c) {
    ref.read(accentColorProvider.notifier).state = c;
    _hex.text = _toHex(c);
    setState(() => _hexError = false);
  }

  void _openWheel() {
    Color temp = ref.read(accentColorProvider);
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n.accentColor,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: temp,
            onColorChanged: (c) => temp = c,
            enableAlpha: true,
            hexInputBar: true,
            paletteType: PaletteType.hueWheel,
            labelTypes: const [],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              _apply(temp);
              Navigator.pop(ctx);
            },
            child: Text(l10n.apply),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = ref.watch(accentColorProvider);
    final l10n = AppLocalizations.of(context)!;
    OutlineInputBorder border(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: c),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: settingsLabelWidth,
          height: 34,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(l10n.accentColor, style: settingsLabelStyle),
          ),
        ),
        // clickable swatch -> opens wheel + opacity
        Tooltip(
          message: l10n.accentColor,
          child: Material(
            color: accent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Colors.white24),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _openWheel,
              hoverColor: Colors.white.withValues(alpha: 0.15),
              child: const SizedBox.square(dimension: 34),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // hex field
        SizedBox(
          width: 132,
          child: TextField(
            controller: _hex,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontFeatures: tabularFigures,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 9,
              ),
              hintText: '#AARRGGBB',
              hintStyle: const TextStyle(color: Colors.white54),
              errorText: _hexError ? l10n.invalidHex : null,
              errorStyle: const TextStyle(fontSize: 11),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              enabledBorder: border(Colors.white24),
              focusedBorder: border(accent),
            ),
            onChanged: (_) {
              if (_hexError) setState(() => _hexError = false);
            },
            onSubmitted: (s) {
              final c = _parseHex(s);
              if (c != null) {
                _apply(c);
              } else {
                setState(() => _hexError = true);
              }
            },
          ),
        ),
      ],
    );
  }
}
