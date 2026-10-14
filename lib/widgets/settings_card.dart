import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:media_overlay/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';

import '../core/theme.dart';
import '../providers/app_providers.dart';
import '../services/settings_service.dart';
import '../services/smtc_channel.dart';
import '../services/update_service.dart';
import 'accent_picker.dart';

/// Colonna etichette comune a tutte le righe delle impostazioni,
/// così i controlli partono tutti dalla stessa x.
const settingsLabelWidth = 168.0;
const settingsLabelStyle = TextStyle(
  color: Colors.white70,
  fontSize: 14,
  fontWeight: FontWeight.w500,
);

class SettingsOverlay extends ConsumerWidget {
  const SettingsOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          ref.read(settingsOpenProvider.notifier).state = false;
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () =>
                  ref.read(settingsOpenProvider.notifier).state = false,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(color: Colors.black.withValues(alpha: 0.55)),
              ),
            ),
          ),
          const Center(child: SettingsCard()),
        ],
      ),
    );
  }
}

class SettingsCard extends ConsumerWidget {
  const SettingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final section = ref.watch(settingsSectionProvider);
    final accent = ref.watch(accentColorProvider);
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 660,
        height: 440,
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 480),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Color.alphaBlend(
            accent.withValues(alpha: 0.08),
            ThemeColors.surfaceElevated,
          ),
          border: Border.all(color: accent.withValues(alpha: 0.3), width: 1.2),
          // Ombra neutra: l'alone d'accento è riservato alla card del player
          // (The Single Halo Rule, DESIGN.md).
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.65),
              blurRadius: 40,
              spreadRadius: 4,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            // Left navigation
            Container(
              width: 180,
              color: Color.alphaBlend(
                accent.withValues(alpha: 0.04),
                ThemeColors.surfaceBase,
              ),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 4, 10, 14),
                    child: Row(
                      children: [
                        Container(
                          width: 3,
                          height: 16,
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: accent.withValues(alpha: 0.6),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.settings,
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _NavItem(
                    icon: Icons.palette_outlined,
                    label: l10n.appearance,
                    active: section == SettingsSection.appearance,
                    accent: accent,
                    onTap: () =>
                        ref.read(settingsSectionProvider.notifier).state =
                            SettingsSection.appearance,
                  ),
                  _NavItem(
                    icon: Icons.wallpaper_rounded,
                    label: l10n.background,
                    active: section == SettingsSection.background,
                    accent: accent,
                    onTap: () =>
                        ref.read(settingsSectionProvider.notifier).state =
                            SettingsSection.background,
                  ),
                  _NavItem(
                    icon: Icons.volume_up_outlined,
                    label: l10n.audio,
                    active: section == SettingsSection.audio,
                    accent: accent,
                    onTap: () =>
                        ref.read(settingsSectionProvider.notifier).state =
                            SettingsSection.audio,
                  ),
                  _NavItem(
                    icon: Icons.open_in_full_rounded,
                    label: l10n.window,
                    active: section == SettingsSection.window,
                    accent: accent,
                    onTap: () =>
                        ref.read(settingsSectionProvider.notifier).state =
                            SettingsSection.window,
                  ),
                  const Spacer(),
                  _NavItem(
                    icon: Icons.info_outline,
                    label: l10n.about,
                    active: section == SettingsSection.about,
                    accent: accent,
                    onTap: () =>
                        ref.read(settingsSectionProvider.notifier).state =
                            SettingsSection.about,
                  ),
                ],
              ),
            ),
            // Right content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 14, 14, 12),
                    child: Row(
                      children: [
                        Text(
                          _title(section, l10n),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: l10n.close,
                          icon: const Icon(Icons.close_rounded, size: 20),
                          color: Colors.white60,
                          splashRadius: 18,
                          onPressed: () =>
                              ref.read(settingsOpenProvider.notifier).state =
                                  false,
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white12, height: 1),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(22),
                      child: _content(section, ref, context, l10n, accent),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _title(SettingsSection s, AppLocalizations l10n) => switch (s) {
    SettingsSection.appearance => l10n.appearance,
    SettingsSection.background => l10n.background,
    SettingsSection.audio => l10n.audio,
    SettingsSection.window => l10n.window,
    SettingsSection.about => l10n.about,
  };

  Widget _content(
    SettingsSection s,
    WidgetRef ref,
    BuildContext ctx,
    AppLocalizations l10n,
    Color accent,
  ) => switch (s) {
    SettingsSection.appearance => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AccentPickerRow(),
        const SizedBox(height: 20),
        _chipRow(
          label: l10n.discStyle,
          accent: accent,
          chips: [
            _Chip(
              label: l10n.vinyl,
              selected: ref.watch(discStyleProvider) == DiscStyle.vinyl,
              accent: accent,
              onTap: () =>
                  ref.read(discStyleProvider.notifier).state = DiscStyle.vinyl,
            ),
            _Chip(
              label: l10n.album,
              selected: ref.watch(discStyleProvider) == DiscStyle.fullAlbum,
              accent: accent,
              onTap: () => ref.read(discStyleProvider.notifier).state =
                  DiscStyle.fullAlbum,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _chipRow(
          label: l10n.progressBarStyle,
          accent: accent,
          chips: [
            _Chip(
              label: l10n.line,
              selected: ref.watch(seekBarStyleProvider) == SeekBarStyle.line,
              accent: accent,
              onTap: () => ref.read(seekBarStyleProvider.notifier).state =
                  SeekBarStyle.line,
            ),
            _Chip(
              label: l10n.wave,
              selected: ref.watch(seekBarStyleProvider) == SeekBarStyle.wave,
              accent: accent,
              onTap: () => ref.read(seekBarStyleProvider.notifier).state =
                  SeekBarStyle.wave,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _discImageRow(ref, l10n, accent),
      ],
    ),
    SettingsSection.background => _switchRow(
      ref: ref,
      title: l10n.opaqueBackground,
      sub: l10n.opaqueBackgroundSubtitle,
      provider: opaqueBackgroundProvider,
      accent: accent,
    ),
    SettingsSection.audio => const _VolumeRow(),
    SettingsSection.window => _switchRow(
      ref: ref,
      title: l10n.alwaysOnTop,
      sub: l10n.alwaysOnTopSubtitle,
      provider: alwaysOnTopProvider,
      accent: accent,
      onChanged: (v) => windowManager.setAlwaysOnTop(v),
    ),
    SettingsSection.about => const _AboutContent(),
  };

  Widget _chipRow({
    required String label,
    required Color accent,
    required List<Widget> chips,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: settingsLabelWidth,
          child: Text(label, style: settingsLabelStyle),
        ),
        Wrap(spacing: 8, children: chips),
      ],
    );
  }

  Widget _switchRow({
    required WidgetRef ref,
    required String title,
    required String sub,
    required StateProvider<bool> provider,
    required Color accent,
    void Function(bool)? onChanged,
  }) {
    final v = ref.watch(provider);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                sub,
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
        Switch(
          value: v,
          activeTrackColor: accent,
          activeThumbColor: Colors.white,
          inactiveThumbColor: Colors.white60,
          inactiveTrackColor: Colors.white12,
          onChanged: (nv) {
            ref.read(provider.notifier).state = nv;
            onChanged?.call(nv);
          },
        ),
      ],
    );
  }

  Widget _discImageRow(WidgetRef ref, AppLocalizations l10n, Color accent) {
    final customMedia = ref.watch(customMediaPathProvider);
    final hasCustom = customMedia != null;

    return Row(
      children: [
        SizedBox(
          width: settingsLabelWidth,
          child: Text(l10n.discImage, style: settingsLabelStyle),
        ),
        TextButton.icon(
          icon: Icon(Icons.image_outlined, size: 16, color: accent),
          label: Text(l10n.choose, style: TextStyle(color: accent)),
          style: TextButton.styleFrom(
            backgroundColor: accent.withValues(alpha: 0.12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () => _pickMedia(ref),
        ),
        if (hasCustom) ...[
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => _resetMedia(ref),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text(l10n.reset),
          ),
        ],
      ],
    );
  }

  static Future<void> _pickMedia(WidgetRef ref) async {
    final src = await SmtcChannel.pickMedia();
    if (src == null) return;

    final dir = SettingsService.mediaDir();
    final ext = src.split('.').last;
    final dest =
        '${dir.path}\\custom_${DateTime.now().millisecondsSinceEpoch}.$ext';
    await File(src).copy(dest);

    final old = ref.read(customMediaPathProvider);
    ref.read(customMediaPathProvider.notifier).state = dest;
    await SettingsService.setString('customMedia', dest);
    if (old != null) {
      try {
        await File(old).delete();
      } catch (_) {}
    }
  }

  static void _resetMedia(WidgetRef ref) {
    final old = ref.read(customMediaPathProvider);
    ref.read(customMediaPathProvider.notifier).state = null;
    SettingsService.remove('customMedia');
    if (old != null) {
      try {
        File(old).delete();
      } catch (_) {}
    }
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color accent;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: active ? accent.withValues(alpha: 0.20) : Colors.transparent,
            border: Border.all(
              color: active
                  ? accent.withValues(alpha: 0.35)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: active ? accent : Colors.white60),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: active ? Colors.white : Colors.white60,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: selected
                ? accent.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.05),
            border: Border.all(
              color: selected ? accent : Colors.white24,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white60,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _VolumeRow extends ConsumerStatefulWidget {
  const _VolumeRow();

  @override
  ConsumerState<_VolumeRow> createState() => _VolumeRowState();
}

class _VolumeRowState extends ConsumerState<_VolumeRow> {
  double _volume = 0.8;
  double _previousVolume = 0.8;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVolume();
  }

  Future<void> _loadVolume() async {
    final v = await SmtcChannel.getVolume();
    if (mounted && v >= 0) {
      setState(() {
        _volume = v.clamp(0.0, 1.0);
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _onVolumeChanged(double val) {
    final clamped = val.clamp(0.0, 1.0);
    setState(() => _volume = clamped);
    SmtcChannel.setVolume(clamped);
  }

  void _toggleMute() {
    if (_volume > 0.01) {
      _previousVolume = _volume;
      _onVolumeChanged(0.0);
    } else {
      _onVolumeChanged(_previousVolume > 0.01 ? _previousVolume : 0.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = ref.watch(accentColorProvider);
    final l10n = AppLocalizations.of(context)!;
    final isMuted = _volume < 0.01;
    final icon = isMuted
        ? Icons.volume_off_rounded
        : (_volume < 0.5 ? Icons.volume_down_rounded : Icons.volume_up_rounded);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.systemVolume,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.systemVolumeSubtitle,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: accent.withValues(alpha: 0.3)),
              ),
              child: Text(
                '${(_volume * 100).round()}%',
                style: TextStyle(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            IconButton(
              icon: Icon(icon, size: 20),
              color: isMuted ? Colors.white38 : accent,
              onPressed: _toggleMute,
              tooltip: isMuted ? l10n.unmute : l10n.mute,
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: accent,
                  inactiveTrackColor: Colors.white12,
                  thumbColor: Colors.white,
                  overlayColor: accent.withValues(alpha: 0.2),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: _volume.clamp(0.0, 1.0),
                  min: 0.0,
                  max: 1.0,
                  onChanged: _isLoading ? null : _onVolumeChanged,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AboutContent extends ConsumerStatefulWidget {
  const _AboutContent();

  @override
  ConsumerState<_AboutContent> createState() => _AboutContentState();
}

class _AboutContentState extends ConsumerState<_AboutContent> {
  bool _checking = false;
  String? _statusMessage;

  Future<void> _open(String u) async {
    final uri = Uri.parse(u);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _checkUpdate(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _checking = true;
      _statusMessage = null;
    });

    try {
      final u = await UpdateService.check();
      if (!mounted) return;
      ref.invalidate(updateProvider);
      setState(() {
        _statusMessage = u == null
            ? l10n.upToDate
            : l10n.updateAvailable(u.version);
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _statusMessage = l10n.updateCheckFailed;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _checking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = ref.watch(accentColorProvider);
    final appVersion = ref.watch(appVersionProvider).asData?.value;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withValues(alpha: 0.3)),
              ),
              child: Icon(Icons.music_note_rounded, color: accent, size: 28),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sona',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  appVersion == null ? ' ' : 'v$appVersion',
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Divider(color: Colors.white10),
        const SizedBox(height: 14),
        Row(
          children: [
            OutlinedButton.icon(
              icon: _checking
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: accent,
                      ),
                    )
                  : Icon(Icons.system_update_rounded, size: 16, color: accent),
              label: Text(
                _checking ? l10n.checkingUpdates : l10n.checkForUpdates,
                style: TextStyle(color: accent),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: accent.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _checking ? null : () => _checkUpdate(context),
            ),
            if (_statusMessage != null) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _statusMessage!,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            TextButton.icon(
              icon: Icon(Icons.code_rounded, size: 16, color: accent),
              label: Text(l10n.source, style: TextStyle(color: accent)),
              onPressed: () => _open('https://github.com/Carmine0033/Sona'),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              icon: Icon(Icons.download_rounded, size: 16, color: accent),
              label: Text(l10n.releases, style: TextStyle(color: accent)),
              onPressed: () =>
                  _open('https://github.com/Carmine0033/Sona/releases/latest'),
            ),
          ],
        ),
      ],
    );
  }
}
