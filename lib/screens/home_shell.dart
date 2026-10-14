import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../providers/app_providers.dart';
import '../widgets/sidebar.dart';
import '../widgets/settings_card.dart';
import 'player_screen.dart';
import 'playlist_view.dart';
import '../widgets/update_banner.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSettingsOpen = ref.watch(settingsOpenProvider);
    final section = ref.watch(selectedSectionProvider);

    return Scaffold(
      backgroundColor: ThemeColors.canvasAbyss,
      body: Stack(
        children: [
          Row(
            children: [
              const Sidebar(),
              Expanded(
                child: Column(
                  children: [
                    const UpdateBanner(),
                    Expanded(
                      child: switch (section) {
                        AppSection.player => const PlayerScreen(),
                        AppSection.playlist => const PlaylistView(),
                        AppSection.options => const PlayerScreen(),
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isSettingsOpen)
            const Positioned.fill(
              child: SettingsOverlay(),
            ),
        ],
      ),
    );
  }
}
