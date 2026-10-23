import 'package:flutter/material.dart';
import 'package:media_overlay/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../theme/sona_tokens.dart';
import '../viewmodels/whats_new_view_model.dart';

class Sidebar extends ConsumerWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sel = ref.watch(selectedSectionProvider);
    final isSettingsOpen = ref.watch(settingsOpenProvider);
    final accent = Theme.of(context).colorScheme.primary;
    final l10n = AppLocalizations.of(context)!;
    final unread = ref.watch(whatsNewProvider.select((s) => s.asData?.value.unread ?? false));

    return Container(
      width: 160,
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 8, 18),
            child: Text(
              'SONA',
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                fontSize: 13,
              ),
            ),
          ),
          _NavItem(
            icon: Icons.graphic_eq,
            label: l10n.player,
            active: !isSettingsOpen && sel == AppSection.player,
            onTap: () {
              ref.read(settingsOpenProvider.notifier).state = false;
              ref.read(selectedSectionProvider.notifier).state =
                  AppSection.player;
            },
          ),
          const SizedBox(height: 4),
          _NavItem(
            icon: Icons.queue_music,
            label: l10n.playlist,
            active: !isSettingsOpen && sel == AppSection.playlist,
            onTap: () {
              ref.read(settingsOpenProvider.notifier).state = false;
              ref.read(selectedSectionProvider.notifier).state =
                  AppSection.playlist;
            },
          ),
          const SizedBox(height: 4),
          _NavItem(
            icon: Icons.tune,
            label: l10n.options,
            active: isSettingsOpen,
            badge: unread, // unread release notes
            onTap: () =>
                ref.read(settingsOpenProvider.notifier).update((v) => !v),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool badge;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.badge = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: active ? accent.withValues(alpha: 0.18) : Colors.transparent,
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
              if (badge)
                Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                      color: SonaColors.light(accent), shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
