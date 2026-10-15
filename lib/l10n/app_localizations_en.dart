// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get options => 'Options';

  @override
  String get player => 'Player';

  @override
  String get playlist => 'Playlist';

  @override
  String get nothingPlaying => 'No track playing';

  @override
  String error(Object error) {
    return 'Error: $error';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get apply => 'Apply';

  @override
  String get detachCard => 'Detach Vinyl Card';

  @override
  String get reattachCard => 'Re-attach to main window';

  @override
  String get detachedCardTitle => 'Vinyl Card Detached';

  @override
  String get detachedCardSubtitle =>
      'The vinyl card is currently in a separate transparent window.';

  @override
  String get seekbarStyleWave => 'Seekbar Style (Wave)';

  @override
  String get seekbarStyleLine => 'Seekbar Style (Line)';

  @override
  String get discStyleVinyl => 'Disc Style (Vinyl)';

  @override
  String get discStyleAlbum => 'Disc Style (Album)';

  @override
  String get settings => 'SETTINGS';

  @override
  String get personalization => 'Personalization';

  @override
  String get accentColor => 'Accent color';

  @override
  String get opaqueBackground => 'Opaque background';

  @override
  String get opaqueBackgroundSubtitle =>
      'Use solid background instead of glass effect';

  @override
  String get progressBarStyle => 'Progress bar style';

  @override
  String get progressBarStyleSubtitle =>
      'Choose between standard line or animated wave';

  @override
  String get line => 'Line';

  @override
  String get wave => 'Wave';

  @override
  String get discImage => 'Disc image';

  @override
  String get choose => 'Choose';

  @override
  String get reset => 'Reset';

  @override
  String get discStyle => 'Disc style';

  @override
  String get vinyl => 'Vinyl';

  @override
  String get album => 'Album';

  @override
  String get general => 'General';

  @override
  String get alwaysOnTop => 'Always on top';

  @override
  String get alwaysOnTopSubtitle => 'Keep window above other applications';

  @override
  String get discordPresence => 'Discord status';

  @override
  String get discordPresenceSubtitle =>
      'Show the track you are listening to on Discord';

  @override
  String get discordPaused => 'Paused';

  @override
  String get discordDownload => 'Get Sona';

  @override
  String get source => 'Source';

  @override
  String get releases => 'Releases';

  @override
  String get transparentBackground => 'Transparent background';

  @override
  String get searchingLyrics => 'Searching lyrics...';

  @override
  String get syncingLyrics => 'Syncing verses via LRCLIB';

  @override
  String get lyricsUnavailable => 'Lyrics unavailable';

  @override
  String get serverTimeout => 'Server timeout (lrclib.net unreachable)';

  @override
  String get noSyncedLyrics => 'No synced lyrics';

  @override
  String get noSyncedLyricsSubtitle =>
      'This track does not have synced lyrics available';

  @override
  String newVersionAvailable(Object version) {
    return 'New version available (v$version)';
  }

  @override
  String get update => 'Update';

  @override
  String get downloadingUpdate => 'Downloading update…';

  @override
  String get updateFailed => 'Update failed';

  @override
  String get appearance => 'Appearance';

  @override
  String get background => 'Background';

  @override
  String get audio => 'Audio';

  @override
  String get window => 'Window';

  @override
  String get about => 'About';

  @override
  String get systemVolume => 'System volume';

  @override
  String get systemVolumeSubtitle => 'Control playback volume';

  @override
  String get checkForUpdates => 'Check for updates';

  @override
  String get upToDate => 'You are up to date';

  @override
  String get checkingUpdates => 'Checking for updates...';

  @override
  String updateAvailable(Object version) {
    return 'Update available: v$version';
  }

  @override
  String get updateCheckFailed =>
      'Couldn\'t check for updates. Check your connection and try again.';

  @override
  String get nothingPlayingHint =>
      'Start playing music in Spotify, YouTube or any app that shows up in the Windows media controls.';

  @override
  String get previousTrack => 'Previous';

  @override
  String get nextTrack => 'Next';

  @override
  String get play => 'Play';

  @override
  String get pause => 'Pause';

  @override
  String get mute => 'Mute';

  @override
  String get unmute => 'Unmute';

  @override
  String get close => 'Close';

  @override
  String get invalidHex => 'Use #RRGGBB or #AARRGGBB';

  @override
  String get playlistLinkHint => 'Paste a playlist link…';

  @override
  String get pasteAndLoad => 'Paste and load';

  @override
  String get removePlaylist => 'Remove playlist';

  @override
  String get playlistEmptyTitle => 'Paste the link of a public playlist';

  @override
  String get playlistEmptySubtitle =>
      'Spotify · YouTube Music · Apple Music · Deezer';

  @override
  String trackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks',
      one: '1 track',
    );
    return '$_temp0';
  }

  @override
  String get playlistTruncated =>
      'Partial list: the service returned only some of the tracks.';

  @override
  String openTrack(Object service) {
    return 'Open in $service';
  }

  @override
  String playlistErrorUnexpected(Object error) {
    return 'Unexpected error: $error';
  }

  @override
  String get playlistErrorInvalidLink => 'The pasted text isn\'t a valid link.';

  @override
  String get playlistErrorAutoMix =>
      'YouTube auto-mixes aren\'t real playlists: save it as a playlist and try again.';

  @override
  String get playlistErrorUnsupported =>
      'Unsupported link. Use a Spotify, YouTube Music, Apple Music or Deezer playlist.';

  @override
  String get playlistErrorNotFound => 'Playlist not found, or it\'s private.';

  @override
  String get playlistErrorForbidden =>
      'This playlist is private: make it public and try again.';

  @override
  String get playlistErrorRateLimited =>
      'Too many requests or quota exhausted: try again later.';

  @override
  String get playlistErrorNetwork =>
      'Couldn\'t connect. Check your network and firewall.';

  @override
  String get playlistErrorParse =>
      'The service changed its format: Sona needs an update.';

  @override
  String playlistErrorMissingKey(Object service) {
    return 'Reading from $service isn\'t configured (missing API key).';
  }

  @override
  String get thisService => 'this service';

  @override
  String get findingAudio => 'Finding audio…';

  @override
  String get stopPlayback => 'Stop';

  @override
  String get shuffle => 'Shuffle';

  @override
  String get repeat => 'Repeat';

  @override
  String get repeatOne => 'Repeat track';

  @override
  String get audioErrorBlocked =>
      'YouTube is blocking playback. Update Sona or try again later.';

  @override
  String get audioErrorNoMatch => 'No matching audio found for this track.';

  @override
  String get audioErrorUnavailable => 'Audio isn\'t available for this track.';

  @override
  String get audioErrorNetwork =>
      'Couldn\'t connect. Check your network and try again.';

  @override
  String get audioErrorPlayback => 'Playback stopped because of an error.';
}
