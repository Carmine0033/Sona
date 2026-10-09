import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:media_overlay/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';

class AccentPickerRow extends ConsumerStatefulWidget {
  const AccentPickerRow({super.key});
  @override
  ConsumerState<AccentPickerRow> createState() => _AccentPickerRowState();
}

class _AccentPickerRowState extends ConsumerState<AccentPickerRow> {
  late final TextEditingController _hex;

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
  }

  void _openWheel() {
    Color temp = ref.read(accentColorProvider);
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A0B2E),
        title: Text(l10n.accentColor,
            style: const TextStyle(color: Colors.white, fontSize: 16)),
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
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            l10n.accentColor,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        // swatch cliccabile -> apre ruota + opacità
        GestureDetector(
          onTap: _openWheel,
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white24),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // campo hex
        SizedBox(
          width: 120,
          child: TextField(
            controller: _hex,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: const InputDecoration(
              isDense: true,
              hintText: '#AARRGGBB',
              hintStyle: TextStyle(color: Colors.white30),
            ),
            onSubmitted: (s) {
              final c = _parseHex(s);
              if (c != null) _apply(c);
            },
          ),
        ),
      ],
    );
  }
}