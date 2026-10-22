import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:media_overlay/providers/app_providers.dart';
import 'package:media_overlay/services/settings_service.dart';
import 'package:media_overlay/services/smtc_channel.dart';

const _maxBytes = 15 * 1024 * 1024;

enum BarMediaResult { ok, cancelled, tooLarge, failed }

/// Lets the user pick an image/GIF for the player bar background and copies
/// it into Sona's media folder, so moving the original doesn't break it.
Future<BarMediaResult> pickBarMedia(WidgetRef ref) async {
  // Same native file picker used for the vinyl card image.
  final picked = await SmtcChannel.pickMedia();
  if (picked == null) return BarMediaResult.cancelled;

  try {
    final src = File(picked);
    if (await src.length() > _maxBytes) return BarMediaResult.tooLarge;

    final dir = SettingsService.mediaDir();
    final ext = picked.split('.').last.toLowerCase();
    // Always a new name: Flutter caches images by PATH, so reusing the same
    // name would keep showing the old GIF until restart.
    final dest =
        '${dir.path}${Platform.pathSeparator}bar_bg_${DateTime.now().millisecondsSinceEpoch}.$ext';
    await src.copy(dest);

    final old = ref.read(barMediaPathProvider);
    ref.read(barMediaPathProvider.notifier).state = dest;
    ref.read(barBackgroundProvider.notifier).state = BarBackground.custom;

    if (old != null && old != dest) {
      try {
        await File(old).delete(); // no orphan files piling up
      } catch (_) {}
    }
    return BarMediaResult.ok;
  } catch (_) {
    return BarMediaResult.failed;
  }
}

/// Removes the custom background and goes back to the glass look.
void clearBarMedia(WidgetRef ref) {
  final old = ref.read(barMediaPathProvider);
  ref.read(barMediaPathProvider.notifier).state = null;
  ref.read(barBackgroundProvider.notifier).state = BarBackground.glass;
  if (old != null) File(old).delete().ignore();
}
