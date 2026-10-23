import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('it'),
  ];

  /// No description provided for @options.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get options;

  /// No description provided for @player.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get player;

  /// No description provided for @playlist.
  ///
  /// In en, this message translates to:
  /// **'Playlist'**
  String get playlist;

  /// No description provided for @nothingPlaying.
  ///
  /// In en, this message translates to:
  /// **'No track playing'**
  String get nothingPlaying;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String error(Object error);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @detachCard.
  ///
  /// In en, this message translates to:
  /// **'Detach Vinyl Card'**
  String get detachCard;

  /// No description provided for @reattachCard.
  ///
  /// In en, this message translates to:
  /// **'Re-attach to main window'**
  String get reattachCard;

  /// No description provided for @detachedCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Vinyl Card Detached'**
  String get detachedCardTitle;

  /// No description provided for @detachedCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The vinyl card is currently in a separate transparent window.'**
  String get detachedCardSubtitle;

  /// No description provided for @seekbarStyleWave.
  ///
  /// In en, this message translates to:
  /// **'Seekbar Style (Wave)'**
  String get seekbarStyleWave;

  /// No description provided for @seekbarStyleLine.
  ///
  /// In en, this message translates to:
  /// **'Seekbar Style (Line)'**
  String get seekbarStyleLine;

  /// No description provided for @discStyleVinyl.
  ///
  /// In en, this message translates to:
  /// **'Disc Style (Vinyl)'**
  String get discStyleVinyl;

  /// No description provided for @discStyleAlbum.
  ///
  /// In en, this message translates to:
  /// **'Disc Style (Album)'**
  String get discStyleAlbum;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'SETTINGS'**
  String get settings;

  /// No description provided for @personalization.
  ///
  /// In en, this message translates to:
  /// **'Personalization'**
  String get personalization;

  /// No description provided for @accentColor.
  ///
  /// In en, this message translates to:
  /// **'Accent color'**
  String get accentColor;

  /// No description provided for @opaqueBackground.
  ///
  /// In en, this message translates to:
  /// **'Opaque background'**
  String get opaqueBackground;

  /// No description provided for @opaqueBackgroundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use solid background instead of glass effect'**
  String get opaqueBackgroundSubtitle;

  /// No description provided for @progressBarStyle.
  ///
  /// In en, this message translates to:
  /// **'Progress bar style'**
  String get progressBarStyle;

  /// No description provided for @progressBarStyleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose between standard line or animated wave'**
  String get progressBarStyleSubtitle;

  /// No description provided for @line.
  ///
  /// In en, this message translates to:
  /// **'Line'**
  String get line;

  /// No description provided for @wave.
  ///
  /// In en, this message translates to:
  /// **'Wave'**
  String get wave;

  /// No description provided for @discImage.
  ///
  /// In en, this message translates to:
  /// **'Disc image'**
  String get discImage;

  /// No description provided for @choose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get choose;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @discStyle.
  ///
  /// In en, this message translates to:
  /// **'Disc style'**
  String get discStyle;

  /// No description provided for @vinyl.
  ///
  /// In en, this message translates to:
  /// **'Vinyl'**
  String get vinyl;

  /// No description provided for @album.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get album;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @alwaysOnTop.
  ///
  /// In en, this message translates to:
  /// **'Always on top'**
  String get alwaysOnTop;

  /// No description provided for @alwaysOnTopSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep window above other applications'**
  String get alwaysOnTopSubtitle;

  /// No description provided for @discordPresence.
  ///
  /// In en, this message translates to:
  /// **'Discord status'**
  String get discordPresence;

  /// No description provided for @discordPresenceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show the track you are listening to on Discord'**
  String get discordPresenceSubtitle;

  /// No description provided for @discordPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get discordPaused;

  /// No description provided for @discordDownload.
  ///
  /// In en, this message translates to:
  /// **'Get Sona'**
  String get discordDownload;

  /// No description provided for @source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// No description provided for @releases.
  ///
  /// In en, this message translates to:
  /// **'Releases'**
  String get releases;

  /// No description provided for @transparentBackground.
  ///
  /// In en, this message translates to:
  /// **'Transparent background'**
  String get transparentBackground;

  /// No description provided for @searchingLyrics.
  ///
  /// In en, this message translates to:
  /// **'Searching lyrics...'**
  String get searchingLyrics;

  /// No description provided for @syncingLyrics.
  ///
  /// In en, this message translates to:
  /// **'Syncing verses via LRCLIB'**
  String get syncingLyrics;

  /// No description provided for @lyricsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Lyrics unavailable'**
  String get lyricsUnavailable;

  /// No description provided for @serverTimeout.
  ///
  /// In en, this message translates to:
  /// **'Server timeout (lrclib.net unreachable)'**
  String get serverTimeout;

  /// No description provided for @noSyncedLyrics.
  ///
  /// In en, this message translates to:
  /// **'No synced lyrics'**
  String get noSyncedLyrics;

  /// No description provided for @noSyncedLyricsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This track does not have synced lyrics available'**
  String get noSyncedLyricsSubtitle;

  /// No description provided for @newVersionAvailable.
  ///
  /// In en, this message translates to:
  /// **'New version available (v{version})'**
  String newVersionAvailable(Object version);

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @downloadingUpdate.
  ///
  /// In en, this message translates to:
  /// **'Downloading update…'**
  String get downloadingUpdate;

  /// No description provided for @updateFailed.
  ///
  /// In en, this message translates to:
  /// **'Update failed'**
  String get updateFailed;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @background.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get background;

  /// No description provided for @audio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get audio;

  /// No description provided for @window.
  ///
  /// In en, this message translates to:
  /// **'Window'**
  String get window;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @systemVolume.
  ///
  /// In en, this message translates to:
  /// **'System volume'**
  String get systemVolume;

  /// No description provided for @systemVolumeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Control playback volume'**
  String get systemVolumeSubtitle;

  /// No description provided for @checkForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get checkForUpdates;

  /// No description provided for @upToDate.
  ///
  /// In en, this message translates to:
  /// **'You are up to date'**
  String get upToDate;

  /// No description provided for @checkingUpdates.
  ///
  /// In en, this message translates to:
  /// **'Checking for updates...'**
  String get checkingUpdates;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update available: v{version}'**
  String updateAvailable(Object version);

  /// No description provided for @updateCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t check for updates. Check your connection and try again.'**
  String get updateCheckFailed;

  /// No description provided for @nothingPlayingHint.
  ///
  /// In en, this message translates to:
  /// **'Start playing music in Spotify, YouTube or any app that shows up in the Windows media controls.'**
  String get nothingPlayingHint;

  /// No description provided for @previousTrack.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previousTrack;

  /// No description provided for @nextTrack.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextTrack;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @mute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get mute;

  /// No description provided for @unmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get unmute;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @invalidHex.
  ///
  /// In en, this message translates to:
  /// **'Use #RRGGBB or #AARRGGBB'**
  String get invalidHex;

  /// No description provided for @playlistLinkHint.
  ///
  /// In en, this message translates to:
  /// **'Paste a playlist link…'**
  String get playlistLinkHint;

  /// No description provided for @pasteAndLoad.
  ///
  /// In en, this message translates to:
  /// **'Paste and load'**
  String get pasteAndLoad;

  /// No description provided for @removePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Remove playlist'**
  String get removePlaylist;

  /// No description provided for @playlistEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Paste the link of a public playlist'**
  String get playlistEmptyTitle;

  /// No description provided for @playlistEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Spotify · YouTube Music · Apple Music · Deezer'**
  String get playlistEmptySubtitle;

  /// No description provided for @trackCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 track} other{{count} tracks}}'**
  String trackCount(int count);

  /// No description provided for @playlistTruncated.
  ///
  /// In en, this message translates to:
  /// **'Partial list: the service returned only some of the tracks.'**
  String get playlistTruncated;

  /// No description provided for @openTrack.
  ///
  /// In en, this message translates to:
  /// **'Open in {service}'**
  String openTrack(Object service);

  /// No description provided for @playlistErrorUnexpected.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error: {error}'**
  String playlistErrorUnexpected(Object error);

  /// No description provided for @playlistErrorInvalidLink.
  ///
  /// In en, this message translates to:
  /// **'The pasted text isn\'t a valid link.'**
  String get playlistErrorInvalidLink;

  /// No description provided for @playlistErrorAutoMix.
  ///
  /// In en, this message translates to:
  /// **'YouTube auto-mixes aren\'t real playlists: save it as a playlist and try again.'**
  String get playlistErrorAutoMix;

  /// No description provided for @playlistErrorUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Unsupported link. Use a Spotify, YouTube Music, Apple Music or Deezer playlist.'**
  String get playlistErrorUnsupported;

  /// No description provided for @playlistErrorNotFound.
  ///
  /// In en, this message translates to:
  /// **'Playlist not found, or it\'s private.'**
  String get playlistErrorNotFound;

  /// No description provided for @playlistErrorForbidden.
  ///
  /// In en, this message translates to:
  /// **'This playlist is private: make it public and try again.'**
  String get playlistErrorForbidden;

  /// No description provided for @playlistErrorRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many requests or quota exhausted: try again later.'**
  String get playlistErrorRateLimited;

  /// No description provided for @playlistErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t connect. Check your network and firewall.'**
  String get playlistErrorNetwork;

  /// No description provided for @playlistErrorParse.
  ///
  /// In en, this message translates to:
  /// **'The service changed its format: Sona needs an update.'**
  String get playlistErrorParse;

  /// No description provided for @playlistErrorMissingKey.
  ///
  /// In en, this message translates to:
  /// **'Reading from {service} isn\'t configured (missing API key).'**
  String playlistErrorMissingKey(Object service);

  /// No description provided for @thisService.
  ///
  /// In en, this message translates to:
  /// **'this service'**
  String get thisService;

  /// No description provided for @findingAudio.
  ///
  /// In en, this message translates to:
  /// **'Finding audio…'**
  String get findingAudio;

  /// No description provided for @stopPlayback.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopPlayback;

  /// No description provided for @shuffle.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get shuffle;

  /// No description provided for @repeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// No description provided for @repeatOne.
  ///
  /// In en, this message translates to:
  /// **'Repeat track'**
  String get repeatOne;

  /// No description provided for @audioErrorBlocked.
  ///
  /// In en, this message translates to:
  /// **'YouTube is blocking playback. Update Sona or try again later.'**
  String get audioErrorBlocked;

  /// No description provided for @audioErrorNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No matching audio found for this track.'**
  String get audioErrorNoMatch;

  /// No description provided for @audioErrorUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Audio isn\'t available for this track.'**
  String get audioErrorUnavailable;

  /// No description provided for @audioErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t connect. Check your network and try again.'**
  String get audioErrorNetwork;

  /// No description provided for @audioErrorPlayback.
  ///
  /// In en, this message translates to:
  /// **'Playback stopped because of an error.'**
  String get audioErrorPlayback;

  /// No description provided for @libraryInputHint.
  ///
  /// In en, this message translates to:
  /// **'Paste a Spotify, YouTube Music, Apple Music or Deezer playlist link…'**
  String get libraryInputHint;

  /// No description provided for @libraryPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get libraryPaste;

  /// No description provided for @libraryAdd.
  ///
  /// In en, this message translates to:
  /// **'Add playlist'**
  String get libraryAdd;

  /// No description provided for @libraryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get libraryAll;

  /// No description provided for @libraryFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get libraryFavorites;

  /// No description provided for @libraryYourPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Your playlists'**
  String get libraryYourPlaylists;

  /// No description provided for @libraryAvailable.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 available} other{{count} available}}'**
  String libraryAvailable(int count);

  /// No description provided for @libraryTracks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 track} other{{count} tracks}}'**
  String libraryTracks(int count);

  /// No description provided for @librarySourcePlaylist.
  ///
  /// In en, this message translates to:
  /// **'{source} playlist'**
  String librarySourcePlaylist(String source);

  /// No description provided for @libraryNowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Now playing'**
  String get libraryNowPlaying;

  /// No description provided for @libraryNowPlayingTicker.
  ///
  /// In en, this message translates to:
  /// **'Now playing:'**
  String get libraryNowPlayingTicker;

  /// No description provided for @libraryPlayNow.
  ///
  /// In en, this message translates to:
  /// **'Play now'**
  String get libraryPlayNow;

  /// No description provided for @libraryPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get libraryPause;

  /// No description provided for @librarySync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get librarySync;

  /// No description provided for @librarySynced.
  ///
  /// In en, this message translates to:
  /// **'Playlist updated'**
  String get librarySynced;

  /// No description provided for @libraryRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get libraryRemove;

  /// No description provided for @libraryRemoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{title}\" from your library?'**
  String libraryRemoveConfirm(String title);

  /// No description provided for @libraryCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get libraryCancel;

  /// No description provided for @libraryBack.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get libraryBack;

  /// No description provided for @libraryAddCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Add playlist'**
  String get libraryAddCardTitle;

  /// No description provided for @libraryAddCardBody.
  ///
  /// In en, this message translates to:
  /// **'Paste a link to a public playlist'**
  String get libraryAddCardBody;

  /// No description provided for @libraryAddCardAction.
  ///
  /// In en, this message translates to:
  /// **'Paste link'**
  String get libraryAddCardAction;

  /// No description provided for @libraryUpdatedToday.
  ///
  /// In en, this message translates to:
  /// **'Updated today'**
  String get libraryUpdatedToday;

  /// No description provided for @libraryUpdatedYesterday.
  ///
  /// In en, this message translates to:
  /// **'Updated yesterday'**
  String get libraryUpdatedYesterday;

  /// No description provided for @libraryUpdatedDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{Updated 1 day ago} other{Updated {days} days ago}}'**
  String libraryUpdatedDaysAgo(int days);

  /// No description provided for @settingsBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Player bar'**
  String get settingsBarTitle;

  /// No description provided for @settingsBarBackground.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get settingsBarBackground;

  /// No description provided for @barBgGlass.
  ///
  /// In en, this message translates to:
  /// **'Transparent'**
  String get barBgGlass;

  /// No description provided for @barBgAlbum.
  ///
  /// In en, this message translates to:
  /// **'Blurred cover'**
  String get barBgAlbum;

  /// No description provided for @barBgCustom.
  ///
  /// In en, this message translates to:
  /// **'Image / GIF'**
  String get barBgCustom;

  /// No description provided for @settingsBarPick.
  ///
  /// In en, this message translates to:
  /// **'Choose image or GIF'**
  String get settingsBarPick;

  /// No description provided for @settingsBarChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get settingsBarChange;

  /// No description provided for @settingsBarDim.
  ///
  /// In en, this message translates to:
  /// **'Dim'**
  String get settingsBarDim;

  /// No description provided for @settingsBarIcons.
  ///
  /// In en, this message translates to:
  /// **'Icon style'**
  String get settingsBarIcons;

  /// No description provided for @iconStyleFilled.
  ///
  /// In en, this message translates to:
  /// **'Filled'**
  String get iconStyleFilled;

  /// No description provided for @iconStyleOutlined.
  ///
  /// In en, this message translates to:
  /// **'Outlined'**
  String get iconStyleOutlined;

  /// No description provided for @iconStyleRounded.
  ///
  /// In en, this message translates to:
  /// **'Rounded'**
  String get iconStyleRounded;

  /// No description provided for @iconStyleSharp.
  ///
  /// In en, this message translates to:
  /// **'Sharp'**
  String get iconStyleSharp;

  /// No description provided for @settingsBarTooLarge.
  ///
  /// In en, this message translates to:
  /// **'File too large (max 15 MB)'**
  String get settingsBarTooLarge;

  /// No description provided for @settingsBarFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the file'**
  String get settingsBarFailed;

  /// No description provided for @searchTracksHint.
  ///
  /// In en, this message translates to:
  /// **'Search a track across all playlists'**
  String get searchTracksHint;

  /// No description provided for @searchInPlaylistHint.
  ///
  /// In en, this message translates to:
  /// **'Search in this playlist'**
  String get searchInPlaylistHint;

  /// No description provided for @searchOpen.
  ///
  /// In en, this message translates to:
  /// **'Search (Ctrl+F)'**
  String get searchOpen;

  /// No description provided for @searchClose.
  ///
  /// In en, this message translates to:
  /// **'Close search'**
  String get searchClose;

  /// No description provided for @searchResults.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No results} =1{1 result} other{{count} results}}'**
  String searchResults(int count);

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No tracks found'**
  String get searchNoResults;

  /// No description provided for @searchTooMany.
  ///
  /// In en, this message translates to:
  /// **'Showing the first 200 results: refine your search'**
  String get searchTooMany;

  /// No description provided for @colTrack.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get colTrack;

  /// No description provided for @colAlbum.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get colAlbum;

  /// No description provided for @colDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get colDuration;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by {column}'**
  String sortBy(String column);

  /// No description provided for @sortOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original order'**
  String get sortOriginal;

  /// No description provided for @trackMore.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get trackMore;

  /// No description provided for @trackCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy title and artist'**
  String get trackCopy;

  /// No description provided for @trackCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get trackCopied;

  /// No description provided for @trackOpenIn.
  ///
  /// In en, this message translates to:
  /// **'Open in {source}'**
  String trackOpenIn(String source);

  /// No description provided for @whatsNewToastTitle.
  ///
  /// In en, this message translates to:
  /// **'Sona has been updated to {version}.'**
  String whatsNewToastTitle(String version);

  /// No description provided for @whatsNewSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See what\'s new'**
  String get whatsNewSeeAll;

  /// No description provided for @whatsNewTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s new'**
  String get whatsNewTitle;

  /// No description provided for @whatsNewAdded.
  ///
  /// In en, this message translates to:
  /// **'New features'**
  String get whatsNewAdded;

  /// No description provided for @whatsNewChanged.
  ///
  /// In en, this message translates to:
  /// **'Changes'**
  String get whatsNewChanged;

  /// No description provided for @whatsNewFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixes'**
  String get whatsNewFixed;

  /// No description provided for @whatsNewInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get whatsNewInstalled;

  /// No description provided for @whatsNewAllReleases.
  ///
  /// In en, this message translates to:
  /// **'All releases on GitHub'**
  String get whatsNewAllReleases;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
