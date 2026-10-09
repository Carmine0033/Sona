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
    //preferences
    ref.listen(
        alwaysOnTopProvider, (_, n) => SettingsService.setBool("alwaysOnTop", n));

    final accent = Theme.of(context).colorScheme.primary;
    final nowPlaying = ref.watch(nowPlayingProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: ThemeColors.canvasAbyss,
      body: nowPlaying.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: accent),
        ),
        error: (e, _) => Center(
          child: Text(
            l10n.error(e.toString()),
            style: const TextStyle(color: ThemeColors.onSurface),
          ),
        ),
        data: (info) => info == null
            ? Center(
                child: Text(
                  l10n.nothingPlaying,
                  style: const TextStyle(
                    color: ThemeColors.onSurfaceVariant,
                    fontSize: 16,
                  ),
                ),
              )
            : _PlayerView(info: info),
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
  @override
  Widget build(BuildContext context) {
    final isOpaque = ref.watch(opaqueBackgroundProvider);
    final seekStyle = ref.watch(seekBarStyleProvider);
    final discStyle = ref.watch(discStyleProvider);
    final detached = ref.watch(detachedProvider);
    final l10n = AppLocalizations.of(context)!;

    final art = widget.info.artwork;
    final hasArt = art != null && art.isNotEmpty;

    final leftWidget =
        detached ? _buildDetachedPlaceholder(l10n) : _buildPlayerCard();

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Sfondo a tutta area: album sfocato se disponibile ed opzione disattivata
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

        // 2. Velo scuro trasparente in stile Glassmorphism
        if (!isOpaque)
          Container(
            color: ThemeColors.canvasAbyss.withValues(alpha: 0.65),
          ),

        // 3. Header in alto a destra con controlli utili
        Positioned(
          top: 14,
          right: 20,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _HeaderIconButton(
                icon: seekStyle == SeekBarStyle.wave
                    ? Icons.waves
                    : Icons.linear_scale,
                tooltip: seekStyle == SeekBarStyle.wave
                    ? l10n.seekbarStyleWave
                    : l10n.seekbarStyleLine,
                onTap: () {
                  ref.read(seekBarStyleProvider.notifier).state =
                      seekStyle == SeekBarStyle.wave
                          ? SeekBarStyle.line
                          : SeekBarStyle.wave;
                },
              ),
              const SizedBox(width: 8),
              _HeaderIconButton(
                icon: isOpaque ? Icons.dark_mode : Icons.blur_on,
                tooltip: isOpaque
                    ? l10n.transparentBackground
                    : l10n.opaqueBackground,
                onTap: () {
                  ref.read(opaqueBackgroundProvider.notifier).state = !isOpaque;
                },
              ),
              const SizedBox(width: 8),
              _HeaderIconButton(
                icon: discStyle == DiscStyle.vinyl
                    ? Icons.album
                    : Icons.disc_full,
                tooltip: discStyle == DiscStyle.vinyl
                    ? l10n.discStyleVinyl
                    : l10n.discStyleAlbum,
                active: discStyle == DiscStyle.vinyl,
                onTap: () {
                  ref.read(discStyleProvider.notifier).state =
                      discStyle == DiscStyle.vinyl
                          ? DiscStyle.fullAlbum
                          : DiscStyle.vinyl;
                },
              ),
            ],
          ),
        ),

        // 4. Layout Principale: Card del Player a sinistra + Sezione Lyrics a destra
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 48.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 780;

                if (isWide) {
                  return Row(
                    children: [
                      // Sinistra: Card del Player
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 32, right: 16, bottom: 24, top: 12),
                        child: Center(
                          child: SingleChildScrollView(
                            child: leftWidget,
                          ),
                        ),
                      ),
                      // Destra: Sezione dei Lyrics sincronizzati
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: 24, bottom: 12),
                          child: FullLyricsView(),
                        ),
                      ),
                    ],
                  );
                } else {
                  // Layout compatto/verticale per schermi stretti
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    child: Column(
                      children: [
                        leftWidget,
                        const SizedBox(height: 24),
                        const SizedBox(
                          height: 420,
                          child: FullLyricsView(),
                        ),
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
        border: Border.all(
          color: accent.withValues(alpha: 0.20),
          width: 1.5,
        ),
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
            onPressed: () {
              ref.read(detachedProvider.notifier).state = false;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard() {
    return VinylCard(
      info: widget.info,
      isDetached: false,
      onToggleDetach: () async {
        ref.read(detachedProvider.notifier).state = true;
        final proc = await openFramelessVinylWindow();
        proc.exitCode.then((_) {
          if (context.mounted) {
            ref.read(detachedProvider.notifier).state = false;
          }
        });
      },
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool active;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: active
                  ? accent.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.25),
              border: Border.all(
                color: active
                    ? accent.withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Icon(
              icon,
              size: 18,
              color: active ? accent : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}