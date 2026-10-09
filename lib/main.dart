import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_overlay/screens/home_shell.dart';
import 'package:media_overlay/services/settings_observer.dart';
import 'package:window_manager/window_manager.dart';
import 'core/theme.dart';
import 'services/settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SettingsService.init();
  await windowManager.ensureInitialized();

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
    //load preferences
    await windowManager.setAlwaysOnTop(SettingsService.getBool('alwaysOnTop', true));
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(ProviderScope(observers:[SettingsObserver()], child: const SonaApp()));
}

class SonaApp extends StatelessWidget {
  const SonaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const HomeShell(),
    );
  }
}
