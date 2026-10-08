///Coammndd to control the playback of media.
/// This class provides methods to play, pause, stop, and seek media playback.
library;

abstract class PlaybackController {
  Future<void> playPause();
  Future<void> next();
  Future<void> previous();

  Future<bool> seek(Duration position);
}