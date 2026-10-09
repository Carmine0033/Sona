import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import 'settings_service.dart';

final class SettingsObserver extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    switch (context.provider.name) {
      case 'opaque':
        SettingsService.setBool('opaque', newValue as bool);
        break;
      case 'alwaysOnTop':
        SettingsService.setBool('alwaysOnTop', newValue as bool);
        break;
      case 'seekStyle':
        SettingsService.setInt('seekStyle', (newValue as SeekBarStyle).index);
        break;
      case 'discStyle':
        SettingsService.setInt('discStyle', (newValue as DiscStyle).index);
        break;
      case 'customMedia':
        final p = newValue as String?;
        p == null
            ? SettingsService.remove('customMedia')
            : SettingsService.setString('customMedia', p);
        break;
    }
  }
}