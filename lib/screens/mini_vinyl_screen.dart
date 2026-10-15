import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../core/theme.dart';
import '../providers/app_providers.dart';
import '../widgets/vinyl_card.dart';
import 'player_screen.dart' show NothingPlaying;

import 'package:media_overlay/l10n/app_localizations.dart';

class MiniVinylScreen extends ConsumerWidget {
  const MiniVinylScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(accentColorProvider);
    final nowPlaying = ref.watch(nowPlayingProvider);
    final l10n = AppLocalizations.of(context)!;

    // Frameless window: every state must stay draggable,
    // resizable and closable.
    final content = nowPlaying.when(
      loading: () => Center(child: CircularProgressIndicator(color: accent)),
      error: (e, _) => _MiniPanel(
        child: Text(
          l10n.error(e.toString()),
          textAlign: TextAlign.center,
          style: const TextStyle(color: ThemeColors.onSurface),
        ),
      ),
      data: (info) {
        if (info == null) {
          return _MiniPanel(
            child: NothingPlaying(
              action: OutlinedButton.icon(
                icon: const Icon(Icons.push_pin, size: 16),
                label: Text(l10n.reattachCard),
                style: OutlinedButton.styleFrom(
                  foregroundColor: accent,
                  side: BorderSide(color: accent.withValues(alpha: 0.5)),
                ),
                onPressed: _close,
              ),
            ),
          );
        }
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: VinylCard(
            info: info,
            isDetached: true,
            onToggleDetach: _close,
          ),
        );
      },
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: WindowResizeFrame(
          borderThickness: 8.0,
          child: DragToMoveArea(child: Center(child: content)),
        ),
      ),
    );
  }

  static Future<void> _close() async {
    await windowManager.destroy();
    exit(0);
  }
}

/// Readable backdrop for card-less states over a transparent window.
class _MiniPanel extends StatelessWidget {
  final Widget child;
  const _MiniPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          accent.withValues(alpha: 0.08),
          ThemeColors.surfaceElevated.withValues(alpha: 0.92),
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.28), width: 1.5),
      ),
      padding: const EdgeInsets.all(8),
      child: child,
    );
  }
}

class WindowResizeFrame extends StatelessWidget {
  final Widget child;
  final double borderThickness;

  const WindowResizeFrame({
    super.key,
    required this.child,
    this.borderThickness = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Content in the center
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.all(borderThickness),
            child: child,
          ),
        ),
        // Top edge
        Positioned(
          top: 0,
          left: borderThickness,
          right: borderThickness,
          height: borderThickness,
          child: const _ResizeBorder(
            cursor: SystemMouseCursors.resizeUpDown,
            edge: ResizeEdge.top,
          ),
        ),
        // Bottom edge
        Positioned(
          bottom: 0,
          left: borderThickness,
          right: borderThickness,
          height: borderThickness,
          child: const _ResizeBorder(
            cursor: SystemMouseCursors.resizeUpDown,
            edge: ResizeEdge.bottom,
          ),
        ),
        // Left edge
        Positioned(
          top: borderThickness,
          bottom: borderThickness,
          left: 0,
          width: borderThickness,
          child: const _ResizeBorder(
            cursor: SystemMouseCursors.resizeLeftRight,
            edge: ResizeEdge.left,
          ),
        ),
        // Right edge
        Positioned(
          top: borderThickness,
          bottom: borderThickness,
          right: 0,
          width: borderThickness,
          child: const _ResizeBorder(
            cursor: SystemMouseCursors.resizeLeftRight,
            edge: ResizeEdge.right,
          ),
        ),
        // Top-Left corner
        Positioned(
          top: 0,
          left: 0,
          width: borderThickness,
          height: borderThickness,
          child: const _ResizeBorder(
            cursor: SystemMouseCursors.resizeUpLeftDownRight,
            edge: ResizeEdge.topLeft,
          ),
        ),
        // Top-Right corner
        Positioned(
          top: 0,
          right: 0,
          width: borderThickness,
          height: borderThickness,
          child: const _ResizeBorder(
            cursor: SystemMouseCursors.resizeUpRightDownLeft,
            edge: ResizeEdge.topRight,
          ),
        ),
        // Bottom-Left corner
        Positioned(
          bottom: 0,
          left: 0,
          width: borderThickness,
          height: borderThickness,
          child: const _ResizeBorder(
            cursor: SystemMouseCursors.resizeUpRightDownLeft,
            edge: ResizeEdge.bottomLeft,
          ),
        ),
        // Bottom-Right corner
        Positioned(
          bottom: 0,
          right: 0,
          width: borderThickness,
          height: borderThickness,
          child: const _ResizeBorder(
            cursor: SystemMouseCursors.resizeUpLeftDownRight,
            edge: ResizeEdge.bottomRight,
          ),
        ),
      ],
    );
  }
}

class _ResizeBorder extends StatelessWidget {
  final MouseCursor cursor;
  final ResizeEdge edge;

  const _ResizeBorder({required this.cursor, required this.edge});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: cursor,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: (_) => windowManager.startResizing(edge),
        child: const SizedBox.expand(),
      ),
    );
  }
}
