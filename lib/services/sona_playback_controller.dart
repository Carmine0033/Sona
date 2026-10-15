import '../models/sona_player_view_model.dart';
import 'playback_controller.dart';

/// Commands for Sona's internal player, with the same interface as SMTC:
/// screens don't need to know who is playing.
class SonaPlaybackController implements PlaybackController {
  SonaPlaybackController(this._vm);
  final SonaPlayerViewModel _vm;

  @override
  Future<void> playPause() => _vm.togglePlay();

  @override
  Future<void> next() => _vm.next();

  @override
  Future<void> previous() => _vm.previous();

  @override
  Future<bool> seek(Duration position) async {
    await _vm.seek(position);
    return true;
  }

  // The internal player has a single volume: its own.
  @override
  Future<bool> setPlayerVolume(double level) async {
    await _vm.setVolume(level);
    return true;
  }

  @override
  Future<bool> setVolume(double level) => setPlayerVolume(level);

  @override
  Future<double> getVolume() async =>
      (_vm.player.state.volume / 100).clamp(0.0, 1.0); // media_kit: 0..100
}
