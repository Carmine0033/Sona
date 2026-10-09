import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import '../core/theme.dart';
import '../providers/app_providers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../services/smtc_channel.dart';
import '../services/settings_service.dart';

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

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: ThemeColors.surfaceElevated.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: ThemeColors.luminescenceSubtle.withValues(alpha: 0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SETTINGS',
                  style: TextStyle(
                    color: ThemeColors.luminescencePure,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                _OptionTile(
                  title: 'Opaque background',
                  subtitle: 'Use solid background instead of glass effect',
                  value: isOpaque,
                  onChanged: (v) {
                    ref.read(opaqueBackgroundProvider.notifier).state = v;
                  },
                ),
                const Divider(color: Colors.white12, height: 32),
                _OptionTile(
                  title: 'Always on top',
                  subtitle: 'Keep window above other applications',
                  value: onTop,
                  onChanged: (v) {
                    ref.read(alwaysOnTopProvider.notifier).state = v;
                    windowManager.setAlwaysOnTop(v);
                  },
                ),
                const Divider(color: Colors.white12, height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Progress bar style',
                            style: TextStyle(
                              color: ThemeColors.luminescencePure,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Choose between standard line or animated wave',
                            style: TextStyle(
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
                          label: 'Line',
                          selected: seekBarStyle == SeekBarStyle.line,
                          onTap: () => ref
                              .read(seekBarStyleProvider.notifier)
                              .state = SeekBarStyle.line,
                        ),
                        const SizedBox(width: 8),
                        _StyleChip(
                          label: 'Wave',
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
                const Divider(color: Colors.white12),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const SizedBox(
                        width: 120,
                        child: Text('Disc image',
                            style: TextStyle(color: Colors.white70))),
                    TextButton.icon(
                      icon: const Icon(Icons.image, size: 16),
                      label: const Text('Choose'),
                      onPressed: () => _pickMedia(ref),
                    ),
                    if (ref.watch(customMediaPathProvider) != null)
                      TextButton(
                        onPressed: () => _resetMedia(ref),
                        child: const Text('Reset'),
                      ),
                  ],
                ),
                 const SizedBox(height: 8),
                 Row(
                  children: [
                    const SizedBox(
                        width: 120,
                        child: Text('Disc style',
                            style: TextStyle(color: Colors.white70))),
                    _StyleChip(
                      label: 'Vinyl',
                      selected: ref.watch(discStyleProvider) == DiscStyle.vinyl,
                      onTap: () => ref.read(discStyleProvider.notifier).state =
                          DiscStyle.vinyl,
                    ),
                    const SizedBox(width: 8),
                    _StyleChip(
                      label: 'Album',
                      selected: ref.watch(discStyleProvider) == DiscStyle.fullAlbum,
                      onTap: () => ref.read(discStyleProvider.notifier).state =
                          DiscStyle.fullAlbum,
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sona v$appVersion',
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                    Row(
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.code, size: 16),
                          label: const Text('Source'),
                          onPressed: () => _open(repoUrl),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.download, size: 16),
                          label: const Text('Releases'),
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
      try { await File(old).delete(); } catch (_) {}
    }
  }

  void _resetMedia(WidgetRef ref) {
    final old = ref.read(customMediaPathProvider);
    ref.read(customMediaPathProvider.notifier).state = null;
    SettingsService.remove('customMedia');
    if (old != null) {
      try { File(old).delete(); } catch (_) {}
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
          activeThumbColor: ThemeColors.luminescencePure,
          activeTrackColor: ThemeColors.primary,
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
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: selected
              ? ThemeColors.primary.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.06),
          border: Border.all(
            color: selected ? ThemeColors.primaryLight : Colors.white24,
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

