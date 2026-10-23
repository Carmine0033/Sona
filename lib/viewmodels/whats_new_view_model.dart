import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:media_overlay/models/release_notes.dart';
import 'package:media_overlay/services/settings_service.dart';
import 'package:media_overlay/providers/app_providers.dart';

class WhatsNewState {
  const WhatsNewState({
    this.all = const [],
    this.unseen = const [],
    this.showToast = false,
    this.unread = false,
    this.current = '',
  });

  final List<ReleaseNotes> all;    // newest first
  final List<ReleaseNotes> unseen; // released after the last ones read
  final bool showToast;
  final bool unread;               // dot on "Options"
  final String current;            // installed version

  bool isInstalled(ReleaseNotes r) => compareVersions(r.version, current) == 0;

  /// Unread releases, or else the latest one.
  List<ReleaseNotes> get toShow => unseen.isNotEmpty ? unseen : all.take(1).toList();

  WhatsNewState copyWith({bool? showToast, bool? unread}) => WhatsNewState(
        all: all,
        unseen: unseen,
        showToast: showToast ?? this.showToast,
        unread: unread ?? this.unread,
        current: current,
      );
}

final whatsNewProvider =
    AsyncNotifierProvider<WhatsNewViewModel, WhatsNewState>(WhatsNewViewModel.new);

class WhatsNewViewModel extends AsyncNotifier<WhatsNewState> {
  static const _seenKey = 'whatsNewSeen';   // last version whose notes were read
  static const _toastKey = 'whatsNewToast'; // last version whose banner was closed

  @override
  Future<WhatsNewState> build() async {
    final all = await _load();
    final String current;
    try {
      current = await ref.watch(appVersionProvider.future);
    } catch (_) {
      return WhatsNewState(all: all); // unknown version: no banner
    }
    var seen = SettingsService.getString(_seenKey);

    if (seen == null) {
      if (!SettingsService.existedBeforeLaunch || all.length < 2) {
        // First install: nothing is "new" yet.
        _remember(current);
        return WhatsNewState(all: all, current: current);
      }
      // Updating from a version without this feature: show only the installed
      // release. Not all[1]: the file may already hold a future version.
      seen = all
          .firstWhere((r) => compareVersions(r.version, current) < 0,
              orElse: () => all.last)
          .version;
    }

    final unseen = all
        .where((r) =>
            compareVersions(r.version, seen!) > 0 &&
            compareVersions(r.version, current) <= 0) // never future versions
        .toList();

    if (unseen.isEmpty) {
      if (compareVersions(current, seen) > 0) _remember(current);
      return WhatsNewState(all: all, current: current);
    }

    final toastDone = SettingsService.getString(_toastKey);
    return WhatsNewState(
      all: all,
      unseen: unseen,
      showToast: toastDone == null || compareVersions(current, toastDone) > 0,
      unread: true,
      current: current,
    );
  }

  WhatsNewState get _s => state.asData?.value ?? const WhatsNewState();

  /// Banner closed: it stays closed for this version, the dot remains.
  void dismissToast() {
    SettingsService.setString(_toastKey, _s.current);
    state = AsyncData(_s.copyWith(showToast: false));
  }

  /// Notes opened (panel or About): everything read.
  void markRead() {
    if (!_s.unread && !_s.showToast) return;
    _remember(_s.current);
    state = AsyncData(_s.copyWith(unread: false, showToast: false));
  }

  void _remember(String v) {
    SettingsService.setString(_seenKey, v);
    SettingsService.setString(_toastKey, v);
  }

  Future<List<ReleaseNotes>> _load() async {
    try {
      final raw = jsonDecode(await rootBundle.loadString('assets/whats_new.json'));
      final list = (raw is Map ? raw['releases'] : null) as List? ?? const [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(ReleaseNotes.tryParse)
          .whereType<ReleaseNotes>()
          .toList()
        ..sort((a, b) => compareVersions(b.version, a.version));
    } catch (_) {
      return const []; // unreadable notes: just no banner
    }
  }
}