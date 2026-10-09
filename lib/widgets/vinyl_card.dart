import 'package:flutter/material.dart';
import 'package:media_overlay/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../models/now_playing.dart';
import '../providers/app_providers.dart';
import '../services/smtc_channel.dart';
import 'marquee_text.dart';
import 'seek_bar.dart';
import 'spinning_disc.dart';

class VinylCard extends ConsumerStatefulWidget {
  final NowPlaying info;
  final bool isDetached;
  final VoidCallback? onToggleDetach;

  const VinylCard({
    super.key,
    required this.info,
    this.isDetached = false,
    this.onToggleDetach,
  });

  @override
  ConsumerState<VinylCard> createState() => _VinylCardState();
}

class _VinylCardState extends ConsumerState<VinylCard> {
  double _volume = 0.8;

  @override
  void initState() {
    super.initState();
    SmtcChannel.getVolume().then((v) {
      if (v >= 0 && mounted) setState(() => _volume = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final controller = ref.read(playbackControllerProvider);
    final seekStyle = ref.watch(seekBarStyleProvider);
    final discStyle = ref.watch(discStyleProvider);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      constraints: const BoxConstraints(maxWidth: 440),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          accent.withValues(alpha: 0.10),
          ThemeColors.surfaceElevated.withValues(alpha: 0.45),
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: accent.withValues(alpha: 0.28),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.14),
            blurRadius: 36,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
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
          // Top Header Bar con controlli (Stile SeekBar, Stile Disco, Detach)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent,
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.6),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'SONA',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pulsante per cambiare lo stile della barra di progresso (Wave / Line)
                  Tooltip(
                    message: seekStyle == SeekBarStyle.wave
                        ? l10n.seekbarStyleWave
                        : l10n.seekbarStyleLine,
                    child: IconButton(
                      padding: const EdgeInsets.all(4),
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                      icon: Icon(
                        seekStyle == SeekBarStyle.wave
                            ? Icons.waves
                            : Icons.linear_scale,
                        size: 18,
                        color: accent,
                      ),
                      onPressed: () {
                        ref.read(seekBarStyleProvider.notifier).state =
                            seekStyle == SeekBarStyle.wave
                                ? SeekBarStyle.line
                                : SeekBarStyle.wave;
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Pulsante per cambiare lo stile del disco (Vinyl / Album)
                  Tooltip(
                    message: discStyle == DiscStyle.vinyl
                        ? l10n.discStyleVinyl
                        : l10n.discStyleAlbum,
                    child: IconButton(
                      padding: const EdgeInsets.all(4),
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                      icon: Icon(
                        discStyle == DiscStyle.vinyl
                            ? Icons.album
                            : Icons.disc_full,
                        size: 18,
                        color: accent,
                      ),
                      onPressed: () {
                        ref.read(discStyleProvider.notifier).state =
                            discStyle == DiscStyle.vinyl
                                ? DiscStyle.fullAlbum
                                : DiscStyle.vinyl;
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Pulsante per Staccare / Riagganciare la Card
                  if (widget.onToggleDetach != null)
                    Tooltip(
                      message: widget.isDetached
                          ? l10n.reattachCard
                          : l10n.detachCard,
                      child: IconButton(
                        padding: const EdgeInsets.all(4),
                        constraints:
                            const BoxConstraints(minWidth: 32, minHeight: 32),
                        icon: Icon(
                          widget.isDetached
                              ? Icons.push_pin
                              : Icons.push_pin_outlined,
                          size: 18,
                        ),
                        color: widget.isDetached ? accent : Colors.white60,
                        onPressed: widget.onToggleDetach,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

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
            width: double.infinity,
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

          // Pulsanti di controllo riproduzione (Prev, Play/Pause, Next)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CtrlButton(
                icon: Icons.skip_previous_rounded,
                onTap: controller.previous,
              ),
              const SizedBox(width: 20),
              _CtrlButton(
                icon: widget.info.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                hero: true,
                onTap: controller.playPause,
              ),
              const SizedBox(width: 20),
              _CtrlButton(
                icon: Icons.skip_next_rounded,
                onTap: controller.next,
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
                color: accent.withValues(alpha: 0.7),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 4),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 8),
                    activeTrackColor: accent,
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                    thumbColor: accent,
                  ),
                  child: Slider(
                    value: _volume,
                    onChanged: (v) {
                      setState(() => _volume = v);
                      SmtcChannel.setVolume(v);
                    },
                  ),
                ),
              ),
              Icon(
                Icons.volume_up,
                size: 16,
                color: accent.withValues(alpha: 0.7),
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
    final accent = Theme.of(context).colorScheme.primary;
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
            color: hero ? Colors.white : Colors.white.withValues(alpha: 0.10),
            border: Border.all(
              color: hero ? Colors.white : Colors.white.withValues(alpha: 0.18),
              width: 1,
            ),
            boxShadow: hero
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.45),
                      blurRadius: 16,
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
