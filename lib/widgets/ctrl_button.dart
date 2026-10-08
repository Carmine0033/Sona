import 'package:flutter/material.dart';
import '../core/theme.dart';

class CtrlButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool hero;
  const CtrlButton(
      {super.key, required this.icon, required this.onTap, this.hero = false});

  @override
  State<CtrlButton> createState() => _CtrlButtonState();
}

class _CtrlButtonState extends State<CtrlButton> {
  bool _pressed = false;
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final size = widget.hero ? 44.0 : 34.0;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.85 : (_hover ? 1.1 : 1.0),
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.hero
                  ? ThemeColors.primary
                  : Colors.white.withValues(alpha: _hover ? 0.20 : 0.12),
              boxShadow: widget.hero
                  ? [
                      BoxShadow(
                        color: ThemeColors.primary
                            .withValues(alpha: _hover ? 0.6 : 0.35),
                        blurRadius: _hover ? 18 : 10,
                      )
                    ]
                  : null,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, anim) => ScaleTransition(
                  scale: anim,
                  child: FadeTransition(opacity: anim, child: child)),
              child: Icon(widget.icon,
                  key: ValueKey(widget.icon), 
                  color: Colors.white,
                  size: widget.hero ? 24 : 18),
            ),
          ),
        ),
      ),
    );
  }
}