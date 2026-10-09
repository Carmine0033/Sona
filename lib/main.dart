import 'dart:io';
import 'package:flutter/material.dart';
import 'package:media_overlay/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_overlay/screens/home_shell.dart';
import 'package:media_overlay/screens/mini_vinyl_screen.dart';
import 'package:media_overlay/services/settings_observer.dart';
import 'package:window_manager/window_manager.dart';
import 'core/theme.dart';
import 'providers/app_providers.dart';
import 'services/settings_service.dart';

Future<Process> openFramelessVinylWindow() async {
  return await Process.start(Platform.resolvedExecutable, ['--mini']);
}

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  await SettingsService.init();
  await windowManager.ensureInitialized();

  final isMini = args.contains('--mini');

  if (isMini) {
    const options = WindowOptions(
      size: Size(440, 580),
      minimumSize: Size(280, 360),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      title: 'Sona Vinyl Card',
    );

    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.setAsFrameless();
      await windowManager.setResizable(true);
      await windowManager.setBackgroundColor(Colors.transparent);
      await windowManager.setAlwaysOnTop(true);
      await windowManager.show();
      await windowManager.focus();
    });

    runApp(
      ProviderScope(
        observers: [SettingsObserver()],
        child: const MiniFramelessApp(),
      ),
    );
  } else {
    const options = WindowOptions(
      size: Size(1280, 780),
      minimumSize: Size(920, 580),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      title: 'Sona',
    );

    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager
          .setAlwaysOnTop(SettingsService.getBool('alwaysOnTop', true));
      await windowManager.show();
      await windowManager.focus();
    });

    runApp(
      ProviderScope(
        observers: [SettingsObserver()],
        child: const SonaApp(),
      ),
    );
  }
}

class SonaApp extends ConsumerWidget {
  const SonaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(accentColorProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTheme(accent),
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HomeShell(),
    );
  }
}

class MiniFramelessApp extends ConsumerWidget {
  const MiniFramelessApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(accentColorProvider);
    final theme = buildTheme(accent);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme.copyWith(
        scaffoldBackgroundColor: Colors.transparent,
        canvasColor: Colors.transparent,
        colorScheme: theme.colorScheme.copyWith(
          surface: Colors.transparent,
        ),
      ),
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const MiniVinylScreen(),
    );
  }
}
