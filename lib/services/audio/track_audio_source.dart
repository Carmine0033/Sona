import 'package:media_overlay/models/playlist.dart';

class ResolvedAudio {
  const ResolvedAudio({required this.url, this.headers = const {}, this.matchedTitle});
  final Uri url;
  final Map<String, String> headers;
  final String? matchedTitle; // debug only: what was actually matched
}

/// Why a track can't be played. The UI picks the localized message.
enum AudioErrorKind {
  blocked, // the service blocks playback (e.g. bot check)
  noMatch, // no result matches the track
  unavailable, // found, but without an audio stream
  network,
  playback, // player error during playback
}

final class AudioResolveException implements Exception {
  const AudioResolveException(this.kind, [this.detail]);
  final AudioErrorKind kind;
  final String? detail; // debug only
  @override
  String toString() => 'AudioResolveException(${kind.name}${detail == null ? '' : ': $detail'})';
}

/// Resolves a track (title/artist/duration) to a playable audio stream.
abstract interface class TrackAudioSource {
  Future<ResolvedAudio> resolve(PlaylistTrack track);
  void dispose();
}