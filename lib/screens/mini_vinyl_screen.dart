import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import '../core/theme.dart';
import '../providers/app_providers.dart';
import '../widgets/vinyl_card.dart';

import 'package:media_overlay/l10n/app_localizations.dart';

class MiniVinylScreen extends ConsumerWidget {
  const MiniVinylScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(accentColorProvider);
    final nowPlaying = ref.watch(nowPlayingProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: nowPlaying.when(
          loading: () => Center(
            child: CircularProgressIndicator(color: accent),
          ),
          error: (e, _) => Center(
            child: Text(
              l10n.error(e.toString()),
              style: const TextStyle(color: ThemeColors.onSurface),
            ),
          ),
          data: (info) {
            if (info == null) {
              return Center(
                child: Text(
                  l10n.nothingPlaying,
                  style: const TextStyle(
                    color: ThemeColors.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              );
            }

            return WindowResizeFrame(
              borderThickness: 8.0,
              child: DragToMoveArea(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: VinylCard(
                      info: info,
                      isDetached: true,
                      onToggleDetach: () => windowManager.close(),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
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

  const _ResizeBorder({
    required this.cursor,
    required this.edge,
  });

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
