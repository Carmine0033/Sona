import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_overlay/l10n/app_localizations.dart';
import 'package:media_overlay/services/update_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';
import '../providers/app_providers.dart';

class UpdateBanner extends ConsumerWidget {
  const UpdateBanner({super.key});

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> startUpdate(BuildContext context, UpdateInfo info) async {
    final l10n = AppLocalizations.of(context)!;

    if (info.downloadUrl == null || info.downloadUrl!.isEmpty) {
      await _open(info.pageUrl);
      return;
    }

    final progress = ValueNotifier<double>(0);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A0B2E),
        title: Text(
          l10n.downloadingUpdate,
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
        content: ValueListenableBuilder<double>(
          valueListenable: progress,
          builder: (ctx, p, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(
                value: p == 0 ? null : p,
                color: Theme.of(ctx).colorScheme.primary,
              ),
              const SizedBox(height: 10),
              Text(
                '${(p * 100).toStringAsFixed(0)}%',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      await UpdateService.downloadAndRun(
        info.downloadUrl!,
        onProgress: (p) => progress.value = p,
      );
    } catch (_) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.updateFailed)),
        );
      }
    } finally {
      progress.dispose();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final update = ref.watch(updateProvider).asData?.value;
    if (update == null) return const SizedBox.shrink();

    final accent = Theme.of(context).colorScheme.primary;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.22),
        border: Border(
          bottom: BorderSide(
            color: accent.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.system_update_rounded, size: 16, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.newVersionAvailable(update.version),
              style: const TextStyle(
                color: ThemeColors.luminescencePure,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            onPressed: () => startUpdate(context, update),
            child: Text(
              l10n.update,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}