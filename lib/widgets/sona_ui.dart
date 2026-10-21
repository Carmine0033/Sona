import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:media_overlay/l10n/app_localizations.dart';
import 'package:media_overlay/models/playlist.dart';
import 'package:media_overlay/services/playlist/playlist_core.dart';
import 'package:media_overlay/theme/sona_tokens.dart';
import 'package:media_overlay/viewmodels/playlist_library_view_model.dart';

String playlistErrorText(AppLocalizations l10n, Object error) {
  if (error is! PlaylistException) {
    return l10n.playlistErrorUnexpected('$error');
  }
  return switch (error.kind) {
    PlaylistErrorKind.invalidLink => l10n.playlistErrorInvalidLink,
    PlaylistErrorKind.unsupportedLink =>
      error.detail == 'mix automatico'
          ? l10n.playlistErrorAutoMix
          : l10n.playlistErrorUnsupported,
    PlaylistErrorKind.notFound => l10n.playlistErrorNotFound,
    PlaylistErrorKind.forbidden => l10n.playlistErrorForbidden,
    PlaylistErrorKind.rateLimited => l10n.playlistErrorRateLimited,
    PlaylistErrorKind.network => l10n.playlistErrorNetwork,
    PlaylistErrorKind.parse => l10n.playlistErrorParse,
    PlaylistErrorKind.missingKey => l10n.playlistErrorMissingKey(
      error.detail ?? l10n.thisService,
    ),
  };
}

String formatTotal(Duration d) {
  final h = d.inHours, m = d.inMinutes % 60;
  return h > 0 ? '$h h ${m.toString().padLeft(2, '0')} min' : '$m min';
}

String updatedLabel(AppLocalizations l, DateTime? at) {
  if (at == null) return '';
  final days = DateUtils.dateOnly(DateTime.now()).difference(DateUtils.dateOnly(at)).inDays;
  return switch (days) {
    <= 0 => l.libraryUpdatedToday,
    1 => l.libraryUpdatedYesterday,
    _ => l.libraryUpdatedDaysAgo(days),
  }.toUpperCase();
}

extension MusicSourceIcon on MusicSource {
  IconData get icon => switch (this) {
        MusicSource.spotify => Icons.graphic_eq,
        MusicSource.youtube => Icons.smart_display_outlined,
        MusicSource.appleMusic => Icons.music_note,
        MusicSource.deezer => Icons.equalizer,
      };
}

Future<void> syncWithFeedback(BuildContext context, WidgetRef ref, String key) async {
  final l = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    await ref.read(playlistLibraryProvider.notifier).sync(key);
    messenger?.showSnackBar(SnackBar(content: Text(l.librarySynced)));
  } catch (e) {
    messenger?.showSnackBar(SnackBar(content: Text(playlistErrorText(l, e))));
  }
}

class SonaPrimaryButton extends StatelessWidget {
  const SonaPrimaryButton({
    super.key,
    required this.icon,
    this.label,
    required this.accent,
    required this.onTap,
    this.tooltip,
    this.busy = false,
    this.large = false,
  });

  final IconData icon;
  final String? label;
  final String? tooltip;
  final Color accent;
  final VoidCallback? onTap;
  final bool busy, large;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    final iconOnly = label == null;
    final button = Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(colors: [accent, Color.lerp(accent, Colors.black, 0.3)!]),
          boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.45), blurRadius: 18)],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: busy ? null : onTap,
            child: SizedBox(
              height: large ? 48 : 40,
              width: iconOnly ? (large ? 48 : 40) : null,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: iconOnly ? 0 : (large ? 20 : 14)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  if (busy)
                    const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  else
                    Icon(icon, size: large ? 22 : 18, color: Colors.white),
                  if (!iconOnly) ...[
                    const SizedBox(width: 8),
                    Text(label!, style: (large ? SonaText.titleMd : SonaText.labelLg).copyWith(color: Colors.white)),
                  ],
                ]),
              ),
            ),
          ),
        ),
      ),
    );
    final tip = tooltip ?? (iconOnly ? null : label);
    return tip == null ? button : Tooltip(message: tip, child: button);
  }
}

class SonaSecondaryButton extends StatelessWidget {
  const SonaSecondaryButton({
    super.key,
    required this.icon,
    this.label,
    required this.onTap,
    this.tooltip,
    this.iconColor,
  });
  final IconData icon;
  final String? label;
  final String? tooltip;
  final VoidCallback? onTap;

  /// Highlights a toggled-on state (e.g. shuffle active).
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    final iconOnly = label == null;
    final button = Material(
      color: SonaColors.surfaceHigh,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: SizedBox(
          height: 48,
          width: iconOnly ? 48 : null,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: iconOnly ? 0 : 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: iconOnly ? 20 : 18, color: iconColor ?? SonaColors.textMid),
                if (!iconOnly) ...[
                  const SizedBox(width: 6),
                  Text(label!, style: SonaText.labelMd.copyWith(color: SonaColors.text)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    final tip = tooltip ?? (iconOnly ? null : label);
    return tip == null ? button : Tooltip(message: tip, child: button);
  }
}
