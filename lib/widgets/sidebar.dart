import 'package:flutter/material.dart';
import 'package:media_overlay/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';

class Sidebar extends ConsumerWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sel = ref.watch(selectedSectionProvider);
    final accent = Theme.of(context).colorScheme.primary;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: 160,
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 14),
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
            active: sel == AppSection.player,
            onTap: () => ref.read(selectedSectionProvider.notifier).state =
                AppSection.player,
          ),
          const SizedBox(height: 4),
          _NavItem(
            icon: Icons.tune,
            label: l10n.options,
            active: sel == AppSection.options,
            onTap: () => ref.read(selectedSectionProvider.notifier).state =
                AppSection.options,
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
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
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
            ],
          ),
        ),
      ),
    );
  }
}