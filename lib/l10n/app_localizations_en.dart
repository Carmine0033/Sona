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
}
