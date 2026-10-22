import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:media_overlay/theme/sona_tokens.dart';

/// Ctrl+F → [onTrigger] while this widget is mounted, wherever the keyboard
/// focus is (sidebar, link field, nothing at all). A focus-based shortcut
/// only fires when focus is inside the page, which in the app it rarely is.
class SearchShortcut extends StatefulWidget {
  const SearchShortcut({super.key, required this.onTrigger, required this.child});
  final VoidCallback onTrigger;
  final Widget child;

  @override
  State<SearchShortcut> createState() => _SearchShortcutState();
}

class _SearchShortcutState extends State<SearchShortcut> {
  bool _onKey(KeyEvent e) {
    final kb = HardwareKeyboard.instance;
    if (e is! KeyDownEvent || e.logicalKey != LogicalKeyboardKey.keyF) return false;
    if (!kb.isControlPressed || kb.isAltPressed || kb.isShiftPressed || kb.isMetaPressed) {
      return false;
    }
    // Hidden behind a route or dialog (e.g. settings): leave the key alone.
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return false;
    widget.onTrigger();
    return true; // handled: nobody else should act on Ctrl+F
  }

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Search icon that expands into a text field. Esc or the close button
/// clears and collapses it; [onChanged] is debounced by 150 ms.
class ExpandableSearch extends StatefulWidget {
  const ExpandableSearch({
    super.key,
    required this.onChanged,
    required this.accent,
    required this.hint,
    required this.openTooltip,
    required this.closeTooltip,
    this.expandedWidth = 280,
    this.height = 40,
  });

  final ValueChanged<String> onChanged;
  final Color accent;
  final String hint, openTooltip, closeTooltip;
  final double expandedWidth, height;

  @override
  State<ExpandableSearch> createState() => ExpandableSearchState();
}

class ExpandableSearchState extends State<ExpandableSearch> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    // An empty field that loses focus closes itself; otherwise just repaint
    // the focus border.
    _focus.addListener(() {
      setState(() {
        if (!_focus.hasFocus && _ctrl.text.isEmpty) _open = false;
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void open() {
    setState(() => _open = true);
    // The TextField only exists from the next frame: request focus after it.
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  void close() {
    _debounce?.cancel();
    _ctrl.clear();
    widget.onChanged('');
    _focus.unfocus();
    setState(() => _open = false);
  }

  void _changed(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), () => widget.onChanged(v.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final light = SonaColors.light(widget.accent);
    final h = widget.height;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: _open ? widget.expandedWidth : h,
      height: h,
      decoration: BoxDecoration(
        color: _open ? SonaColors.surfaceLow : SonaColors.surfaceLow.withValues(alpha: 0),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: !_open
            ? Colors.transparent
            : _focus.hasFocus
              ? light
              : SonaColors.specular,
        ),
      ),
      child: !_open
        ? IconButton(
            tooltip: widget.openTooltip,
            icon: const Icon(Icons.search, size: 20),
            color: SonaColors.textMid,
            onPressed: open,
        )
        : ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: OverflowBox(
            alignment: Alignment.centerLeft,
            minWidth: widget.expandedWidth,
            maxWidth: widget.expandedWidth,
            child: Row(children: [
              const SizedBox(width: 12),
              Icon(Icons.search, size: 18, color: light),
              const SizedBox(width: 8),
              Expanded(
                child: CallbackShortcuts(
                  bindings: {const SingleActivator(LogicalKeyboardKey.escape): close},
                  child: TextField(
                    controller: _ctrl,
                    focusNode: _focus,
                    onChanged: _changed,
                    style: SonaText.bodyMd.copyWith(color: SonaColors.text),
                    cursorColor: widget.accent,
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: widget.hint,
                      hintStyle: SonaText.bodyMd.copyWith(color: SonaColors.textMuted),
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: widget.closeTooltip,
                icon: const Icon(Icons.close, size: 16),
                color: SonaColors.textMuted,
                onPressed: close,
              ),
            ]),
          ),
        ),
    );
  }
}