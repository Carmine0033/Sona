import 'playback_controller.dart';
import 'smtc_channel.dart';

class SmtcPlaybackController implements PlaybackController {
  
  @override
  Future<void> playPause() async => await SmtcChannel.playPause();

  @override
  Future<void> next() async => await SmtcChannel.next();

  @override
  Future<void> previous() async => await SmtcChannel.previous();

  @override
  Future<bool> seek(Duration position) => SmtcChannel.seek(position);
}