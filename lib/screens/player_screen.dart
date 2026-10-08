import 'dart:ui'; // ImageFilter.blur
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_overlay/models/now_playing.dart';
import '../core/theme.dart';
import '../providers/app_providers.dart';
import '../widgets/spinning_disc.dart';
import '../widgets/seek_bar.dart';
import '../widgets/full_lyrics_view.dart';
import '../widgets/marquee_text.dart';

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nowPlaying = ref.watch(nowPlayingProvider);
    return Scaffold(
      backgroundColor: ThemeColors.canvasAbyss,
      body: nowPlaying.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: ThemeColors.primary),
        ),
        error: (e, _) => Center(
          child: Text(
            'Errore: $e',
            style: const TextStyle(color: ThemeColors.onSurface),
          ),
        ),
        data: (info) => info == null
            ? const Center(
                child: Text(
                  'Nessun brano in riproduzione',
                  style: TextStyle(
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
  bool _isShuffle = false;
  bool _isRepeat = false;
  double _volume = 0.8;

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(playbackControllerProvider);
    final isOpaque = ref.watch(opaqueBackgroundProvider);
    final seekStyle = ref.watch(seekBarStyleProvider);
    final alwaysOnTop = ref.watch(alwaysOnTopProvider);

    final art = widget.info.artwork;
    final hasArt = art != null && art.isNotEmpty;

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
                tooltip: 'Seekbar Style',
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
                tooltip: isOpaque ? 'Transparent Background' : 'Opaque Background',
                onTap: () {
                  ref.read(opaqueBackgroundProvider.notifier).state = !isOpaque;
                },
              ),
              const SizedBox(width: 8),
              _HeaderIconButton(
                icon: alwaysOnTop
                    ? Icons.push_pin
                    : Icons.push_pin_outlined,
                tooltip: 'Always on Top',
                active: alwaysOnTop,
                onTap: () {
                  ref.read(alwaysOnTopProvider.notifier).state = !alwaysOnTop;
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
                      // Sinistra: Card del Player (spostata a sinistra come richiesto)
                      Padding(
                        padding: const EdgeInsets.only(left: 32, right: 16, bottom: 24, top: 12),
                        child: Center(
                          child: SingleChildScrollView(
                            child: _buildPlayerCard(controller),
                          ),
                        ),
                      ),
                      // Destra: Sezione dei Lyrics sincronizzati (simile allo screen)
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      children: [
                        _buildPlayerCard(controller),
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

  // Costruzione della Card del Player (spostata a sinistra, stile screenshot)
  Widget _buildPlayerCard(dynamic controller) {
    return Container(
      width: 420,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: ThemeColors.surfaceElevated.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: ThemeColors.luminescenceSubtle.withValues(alpha: 0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 28,
            spreadRadius: 4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Disco rotante con copertina
          SpinningDisc(
            albumArt: widget.info.artwork,
            spinning: widget.info.isPlaying,
            size: 185,
          ),
          const SizedBox(height: 22),

          // Titolo brano
          SizedBox(
            height: 28,
            child: MarqueeText(
              widget.info.title.isEmpty ? '—' : widget.info.title,
              style: const TextStyle(
                color: ThemeColors.luminescencePure,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Artista
          Text(
            widget.info.artist.isEmpty ? '—' : widget.info.artist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ThemeColors.luminescenceSubtle,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 22),

          // Barra di progresso / seek bar
          const SeekBar(),
          const SizedBox(height: 18),

          // Pulsanti di controllo riproduzione (Shuffle, Prev, Play/Pause, Next, Repeat)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(
                  Icons.shuffle_rounded,
                  size: 20,
                  color: _isShuffle
                      ? ThemeColors.primaryLight
                      : Colors.white.withValues(alpha: 0.45),
                ),
                tooltip: 'Shuffle',
                onPressed: () => setState(() => _isShuffle = !_isShuffle),
              ),
              _CtrlButton(
                icon: Icons.skip_previous_rounded,
                onTap: controller.previous,
              ),
              _CtrlButton(
                icon: widget.info.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                hero: true,
                onTap: controller.playPause,
              ),
              _CtrlButton(
                icon: Icons.skip_next_rounded,
                onTap: controller.next,
              ),
              IconButton(
                icon: Icon(
                  Icons.repeat_rounded,
                  size: 20,
                  color: _isRepeat
                      ? ThemeColors.primaryLight
                      : Colors.white.withValues(alpha: 0.45),
                ),
                tooltip: 'Repeat',
                onPressed: () => setState(() => _isRepeat = !_isRepeat),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Slider per il Volume / Barra di controllo bottom
          Row(
            children: [
              Icon(
                _volume == 0 ? Icons.volume_off : Icons.volume_down,
                size: 16,
                color: Colors.white.withValues(alpha: 0.5),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
                    activeTrackColor: Colors.white.withValues(alpha: 0.8),
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                    thumbColor: Colors.white,
                  ),
                  child: Slider(
                    value: _volume,
                    onChanged: (v) => setState(() => _volume = v),
                  ),
                ),
              ),
              Icon(
                Icons.volume_up,
                size: 16,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CtrlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool hero;
  const _CtrlButton({
    required this.icon,
    required this.onTap,
    this.hero = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = hero ? 52.0 : 40.0;
    final iconSize = hero ? 30.0 : 22.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: hero
                ? Colors.white
                : Colors.white.withValues(alpha: 0.10),
            border: Border.all(
              color: hero
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.18),
              width: 1,
            ),
            boxShadow: hero
                ? [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.35),
                      blurRadius: 14,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
          child: Icon(
            icon,
            color: hero ? Colors.black : Colors.white,
            size: iconSize,
          ),
        ),
      ),
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
                  ? ThemeColors.primary.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.25),
              border: Border.all(
                color: active
                    ? ThemeColors.primaryLight.withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Icon(
              icon,
              size: 18,
              color: active ? ThemeColors.primaryLight : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}