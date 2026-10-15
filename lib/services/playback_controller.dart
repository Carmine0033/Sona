/// Playback commands for the current media source.
library;

abstract class PlaybackController {
  Future<void> playPause();
  Future<void> next();
  Future<void> previous();

  Future<bool> seek(Duration position);
  Future<bool> setPlayerVolume(double level);
  Future<bool> setVolume(double level);

  /// Current volume 0..1 of the controlled player, or -1 if unavailable.
  Future<double> getVolume();
}