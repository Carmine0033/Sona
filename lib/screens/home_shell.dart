import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../providers/app_providers.dart';
import '../widgets/sidebar.dart';
import 'player_screen.dart';
import 'options_panel.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final section = ref.watch(selectedSectionProvider);

    return Scaffold(
      backgroundColor: ThemeColors.canvasAbyss,
      body: Row(
        children: [
          const Sidebar(),
          Expanded(
            child: switch (section) {
              AppSection.player => const PlayerScreen(),
              AppSection.options => const OptionsPanel(),
            },
          ),
        ],
      ),
    );
  }
}
