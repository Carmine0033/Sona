import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/now_playing.dart';
import '../services/playback_controller.dart';
import '../services/smtc_channel.dart';
import '../services/smtc_playback_controller.dart';
import '../models/lyrics.dart';
import '../services/lyrics_service.dart';
import '../services/update_service.dart';

final playbackControllerProvider= Provider<PlaybackController>((ref) {
  return SmtcPlaybackController();
});

final nowPlayingProvider= StreamProvider<NowPlaying?>((ref) {
  return SmtcChannel.updates.map((map) {
    if (map == null) return null;
    return NowPlaying.fromMap(map);
  });
});


//check for updates
final updateProvider = FutureProvider<UpdateInfo?>((ref) async {
  return UpdateService.check();
});

final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return info.version;
});

enum AppSection { player, options }
enum SeekBarStyle { line, wave }

final selectedSectionProvider =StateProvider<AppSection>((ref) => AppSection.player);

final opaqueBackgroundProvider = StateProvider<bool>((ref) => false);
final alwaysOnTopProvider = StateProvider<bool>((ref) => false);
final seekBarStyleProvider = StateProvider<SeekBarStyle>((ref) => SeekBarStyle.line);


class TrackRef {
  final String title, artist, album;
  final int durationSec;
  const TrackRef(this.title, this.artist, this.album, this.durationSec);

  @override
  bool operator ==(Object other) =>
      other is TrackRef &&
      other.title == title &&
      other.artist == artist &&
      other.album == album;

  @override
  int get hashCode => Object.hash(title, artist, album);
}

final trackRefProvider = Provider<TrackRef?>((ref) {
  final np = ref.watch(nowPlayingProvider).asData?.value;
  if (np == null || np.title.isEmpty) return null;
  return TrackRef(np.title, np.artist, np.album, np.duration.inSeconds);
});

final lyricsProvider = FutureProvider<List<LyricLine>>((ref) async {
  final t = ref.watch(trackRefProvider);
  if (t == null) return [];
  return LyricsService.fetchSynced(t.artist, t.title, t.album, t.durationSec);
});