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
