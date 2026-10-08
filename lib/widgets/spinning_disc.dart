import 'dart:typed_data';
import 'package:flutter/material.dart';

class SpinningDisc extends StatefulWidget {
  final Uint8List? albumArt;
  final bool spinning;
  final double size;

  const SpinningDisc({
    super.key,
    required this.albumArt,
    required this.spinning,
    this.size = 180,
  });

  @override
  State<SpinningDisc> createState() => _SpinningDiscState();
}

class _SpinningDiscState extends State<SpinningDisc>
  with SingleTickerProviderStateMixin {
    late final AnimationController _ctrl;

    @override
    void initState() {
      super.initState();
      _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 4),
      );
      if (widget.spinning) _ctrl.repeat();
    }

    @override
    void didUpdateWidget(SpinningDisc oldWidget) {
      super.didUpdateWidget(oldWidget);
      // Avvia/ferma la rotazione quando cambia lo stato play/pausa
      if (widget.spinning && !_ctrl.isAnimating) {
        _ctrl.repeat();
      } else if (!widget.spinning && _ctrl.isAnimating) {
        _ctrl.stop();
      }
    }

    @override
    void dispose() {
      _ctrl.dispose();
      super.dispose();
    }

    @override
    Widget build(BuildContext context) {
      final art= widget.albumArt;
      final hasArt= art != null && art.isNotEmpty;

      return RotationTransition(
        turns: _ctrl,
        child: Container(
          width: widget.size,
          height: widget.size,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black,
            border: Border.all(color: Colors.white24, width: 3),
          ),
          child: hasArt
            ? Image.memory(art, fit: BoxFit.cover)
            : const Icon(Icons.music_note, color: Colors.white54, size: 48,),
        ),
      );
    }

}