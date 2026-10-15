import 'dart:io';
import 'dart:ui'; // ImageFilter.blur

import 'package:flutter/material.dart';
import 'package:media_overlay/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_overlay/models/now_playing.dart';
import 'package:media_overlay/services/settings_service.dart';

import '../core/theme.dart';
import '../main.dart';
import '../providers/app_providers.dart';
import '../widgets/full_lyrics_view.dart';
import '../widgets/vinyl_card.dart';

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Preferences
    ref.listen(
      alwaysOnTopProvider,
      (_, n) => SettingsService.setBool("alwaysOnTop", n),
    );

    final accent = Theme.of(context).colorScheme.primary;
    final nowPlaying = ref.watch(nowPlayingProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: ThemeColors.canvasAbyss,
      body: nowPlaying.when(
        loading: () => Center(child: CircularProgressIndicator(color: accent)),
        error: (e, _) => Center(
          child: Text(
            l10n.error(e.toString()),
            style: const TextStyle(color: ThemeColors.onSurface),
          ),
        ),
        data: (info) =>
            info == null ? const NothingPlaying() : _PlayerView(info: info),
      ),
    );
  }
}

/// Empty state shared by the main window and the mini player:
/// what's missing and how to fix it.
class NothingPlaying extends StatelessWidget {
  final Widget? action;
  const NothingPlaying({super.key, this.action});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.album_outlined,
                size: 56,
                color: accent.withValues(alpha: 0.55),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.nothingPlaying,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: ThemeColors.luminescencePure,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.nothingPlayingHint,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: ThemeColors.onSurfaceVariant,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              if (action != null) ...[const SizedBox(height: 20), action!],
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerView extends ConsumerStatefulWidget {
  final NowPlaying info;
  const _PlayerView({required this.info});

  @override
  ConsumerState<_PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends ConsumerState<_PlayerView> {
  Process? _miniProcess;

  @override
  void dispose() {
    _miniProcess?.kill();
    _miniProcess = null;
    super.dispose();
  }

  void _reattach() {
    _miniProcess?.kill();
    _miniProcess = null;
    ref.read(detachedProvider.notifier).state = false;
  }

  Future<void> _detach() async {
    ref.read(detachedProvider.notifier).state = true;
    _miniProcess?.kill();
    final proc = await openFramelessVinylWindow();
    _miniProcess = proc;
    proc.exitCode.then((_) {
      if (mounted && _miniProcess == proc) {
        _miniProcess = null;
        ref.read(detachedProvider.notifier).state = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isOpaque = ref.watch(opaqueBackgroundProvider);
    final detached = ref.watch(detachedProvider);
    final l10n = AppLocalizations.of(context)!;

    final art = widget.info.artwork;
    final hasArt = art != null && art.isNotEmpty;

    final leftWidget = detached
        ? _buildDetachedPlaceholder(l10n)
        : _buildPlayerCard();

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Full-bleed background: blurred artwork if available
        if (hasArt && !isOpaque)
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 65, sigmaY: 65),
            child: Image.memory(
              art,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          )
        else
          Container(color: ThemeColors.canvasAbyss),

        // 2. Dark glass overlay
        if (!isOpaque)
          Container(color: ThemeColors.canvasAbyss.withValues(alpha: 0.65)),

        // 3. Top-right header: window controls only. Bar and disc style
        //    live on the card, so they follow it when detached.
        Positioned(
          top: 14,
          right: 20,
          child: _HeaderIconButton(
            icon: isOpaque ? Icons.blur_on : Icons.dark_mode_outlined,
            tooltip: isOpaque
                ? l10n.transparentBackground
                : l10n.opaqueBackground,
            onTap: () {
              ref.read(opaqueBackgroundProvider.notifier).state = !isOpaque;
            },
          ),
        ),

        // 4. Main layout: player card left, lyrics right
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 48.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 780;

                if (isWide) {
                  return Row(
                    children: [
                      // Left: player card
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 32,
                          right: 16,
                          bottom: 24,
                          top: 12,
                        ),
                        child: Center(
                          child: SingleChildScrollView(child: leftWidget),
                        ),
                      ),
                      // Right: synced lyrics
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: 24, bottom: 12),
                          child: FullLyricsView(),
                        ),
                      ),
                    ],
                  );
                } else {
                  // Compact vertical layout for narrow windows
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Column(
                      children: [
                        leftWidget,
                        const SizedBox(height: 24),
                        const SizedBox(height: 420, child: FullLyricsView()),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetachedPlaceholder(AppLocalizations l10n) {
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      width: 420,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          accent.withValues(alpha: 0.06),
          ThemeColors.surfaceElevated.withValues(alpha: 0.35),
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.20), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.push_pin_outlined,
            size: 42,
            color: accent.withValues(alpha: 0.8),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.detachedCardTitle,
            style: const TextStyle(
              color: ThemeColors.luminescencePure,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.detachedCardSubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ThemeColors.luminescenceSubtle,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            icon: const Icon(Icons.push_pin, size: 16),
            label: Text(l10n.reattachCard),
            style: OutlinedButton.styleFrom(
              foregroundColor: accent,
              side: BorderSide(color: accent.withValues(alpha: 0.5)),
            ),
            onPressed: _reattach,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard() {
    return VinylCard(
      info: widget.info,
      isDetached: false,
      onToggleDetach: _detach,
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black.withValues(alpha: 0.25),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          hoverColor: Colors.white.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 18, color: Colors.white70),
          ),
        ),
      ),
    );
  }
}
