import 'dart:io';
import 'package:flutter/material.dart';
import 'package:media_overlay/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';
import '../core/theme.dart';
import '../providers/app_providers.dart';
import '../services/settings_service.dart';
import '../services/smtc_channel.dart';
import '../widgets/accent_picker.dart';

class OptionsPanel extends ConsumerWidget {
  const OptionsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const repoUrl = 'https://github.com/Carmine0033/Sona';
    const releasesUrl = 'https://github.com/Carmine0033/Sona/releases/latest';
    final isOpaque = ref.watch(opaqueBackgroundProvider);
    final onTop = ref.watch(alwaysOnTopProvider);
    final seekBarStyle = ref.watch(seekBarStyleProvider);
    final appVersion = ref.watch(appVersionProvider).asData?.value ?? '0.1.0';
    final accent = ref.watch(accentColorProvider);
    final l10n = AppLocalizations.of(context)!;

    Widget sectionHeader(String title) => Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              color: accent,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                accent.withValues(alpha: 0.10),
                ThemeColors.surfaceElevated.withValues(alpha: 0.45),
              ),
              borderRadius: BorderRadius.circular(20),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 22,
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.6),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      l10n.settings,
                      style: const TextStyle(
                        color: ThemeColors.luminescencePure,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // --- PERSONALIZATION ---
                sectionHeader(l10n.personalization),
                const AccentPickerRow(),
                const SizedBox(height: 16),
                _OptionTile(
                  title: l10n.opaqueBackground,
                  subtitle: l10n.opaqueBackgroundSubtitle,
                  value: isOpaque,
                  onChanged: (v) {
                    ref.read(opaqueBackgroundProvider.notifier).state = v;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.progressBarStyle,
                            style: const TextStyle(
                              color: ThemeColors.luminescencePure,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.progressBarStyleSubtitle,
                            style: const TextStyle(
                              color: ThemeColors.luminescenceSubtle,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        _StyleChip(
                          label: l10n.line,
                          selected: seekBarStyle == SeekBarStyle.line,
                          onTap: () => ref
                              .read(seekBarStyleProvider.notifier)
                              .state = SeekBarStyle.line,
                        ),
                        const SizedBox(width: 8),
                        _StyleChip(
                          label: l10n.wave,
                          selected: seekBarStyle == SeekBarStyle.wave,
                          onTap: () => ref
                              .read(seekBarStyleProvider.notifier)
                              .state = SeekBarStyle.wave,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        l10n.discImage,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    TextButton.icon(
                      icon: Icon(Icons.image, size: 16, color: accent),
                      label: Text(l10n.choose, style: TextStyle(color: accent)),
                      onPressed: () => _pickMedia(ref),
                    ),
                    if (ref.watch(customMediaPathProvider) != null)
                      TextButton(
                        onPressed: () => _resetMedia(ref),
                        child: Text(
                          l10n.reset,
                          style: TextStyle(
                            color: accent.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        l10n.discStyle,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    _StyleChip(
                      label: l10n.vinyl,
                      selected:
                          ref.watch(discStyleProvider) == DiscStyle.vinyl,
                      onTap: () => ref.read(discStyleProvider.notifier).state =
                          DiscStyle.vinyl,
                    ),
                    const SizedBox(width: 8),
                    _StyleChip(
                      label: l10n.album,
                      selected:
                          ref.watch(discStyleProvider) == DiscStyle.fullAlbum,
                      onTap: () => ref.read(discStyleProvider.notifier).state =
                          DiscStyle.fullAlbum,
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(color: Colors.white12),

                // --- GENERAL ---
                sectionHeader(l10n.general),
                _OptionTile(
                  title: l10n.alwaysOnTop,
                  subtitle: l10n.alwaysOnTopSubtitle,
                  value: onTop,
                  onChanged: (v) {
                    ref.read(alwaysOnTopProvider.notifier).state = v;
                    windowManager.setAlwaysOnTop(v);
                  },
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sona v$appVersion',
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                    Row(
                      children: [
                        TextButton.icon(
                          icon: Icon(Icons.code, size: 16, color: accent),
                          label: Text(l10n.source,
                              style: TextStyle(color: accent)),
                          onPressed: () => _open(repoUrl),
                        ),
                        TextButton.icon(
                          icon: Icon(Icons.download, size: 16, color: accent),
                          label: Text(l10n.releases,
                              style: TextStyle(color: accent)),
                          onPressed: () => _open(releasesUrl),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _pickMedia(WidgetRef ref) async {
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

  void _resetMedia(WidgetRef ref) {
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

class _OptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _OptionTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: ThemeColors.luminescencePure,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: ThemeColors.luminescenceSubtle,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Switch(
          value: value,
          activeThumbColor: Colors.white,
          activeTrackColor: accent,
          inactiveThumbColor: Colors.white60,
          inactiveTrackColor: Colors.white12,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _StyleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _StyleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: selected
              ? accent.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.06),
          border: Border.all(
            color: selected ? accent : Colors.white24,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white60,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
