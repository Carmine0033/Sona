// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get options => 'Opzioni';

  @override
  String get player => 'Riproduttore';

  @override
  String get nothingPlaying => 'Nessun brano in riproduzione';

  @override
  String error(Object error) {
    return 'Errore: $error';
  }

  @override
  String get cancel => 'Annulla';

  @override
  String get apply => 'Applica';

  @override
  String get detachCard => 'Stacca Card Vinile';

  @override
  String get reattachCard => 'Riaggancia alla finestra principale';

  @override
  String get detachedCardTitle => 'Card Vinile Staccata';

  @override
  String get detachedCardSubtitle =>
      'La card del vinile è ora in una finestra trasparente separata.';

  @override
  String get seekbarStyleWave => 'Stile Barra (Onda)';

  @override
  String get seekbarStyleLine => 'Stile Barra (Linea)';

  @override
  String get discStyleVinyl => 'Stile Disco (Vinile)';

  @override
  String get discStyleAlbum => 'Stile Disco (Copertina)';

  @override
  String get settings => 'IMPOSTAZIONI';

  @override
  String get personalization => 'Personalizzazione';

  @override
  String get accentColor => 'Colore accento';

  @override
  String get opaqueBackground => 'Sfondo opaco';

  @override
  String get opaqueBackgroundSubtitle =>
      'Usa uno sfondo solido al posto dell\'effetto vetro';

  @override
  String get progressBarStyle => 'Stile barra di progresso';

  @override
  String get progressBarStyleSubtitle =>
      'Scegli tra linea classica o onda animata';

  @override
  String get line => 'Linea';

  @override
  String get wave => 'Onda';

  @override
  String get discImage => 'Immagine disco';

  @override
  String get choose => 'Scegli';

  @override
  String get reset => 'Ripristina';

  @override
  String get discStyle => 'Stile disco';

  @override
  String get vinyl => 'Vinile';

  @override
  String get album => 'Copertina';

  @override
  String get general => 'Generale';

  @override
  String get alwaysOnTop => 'Sempre in primo piano';

  @override
  String get alwaysOnTopSubtitle =>
      'Mantieni la finestra sopra le altre applicazioni';

  @override
  String get source => 'Codice Sorgente';

  @override
  String get releases => 'Rilasci';

  @override
  String get transparentBackground => 'Sfondo trasparente';

  @override
  String get searchingLyrics => 'Ricerca testo in corso...';

  @override
  String get syncingLyrics => 'Sincronizzazione dei versi tramite LRCLIB';

  @override
  String get lyricsUnavailable => 'Testo non disponibile';

  @override
  String get serverTimeout => 'Timeout server (lrclib.net non raggiungibile)';

  @override
  String get noSyncedLyrics => 'Nessun testo sincronizzato';

  @override
  String get noSyncedLyricsSubtitle =>
      'Questo brano non ha un testo sincronizzato disponibile';

  @override
  String newVersionAvailable(Object version) {
    return 'Nuova versione disponibile (v$version)';
  }

  @override
  String get update => 'Aggiorna';

  @override
  String get downloadingUpdate => 'Download aggiornamento in corso…';

  @override
  String get updateFailed => 'Aggiornamento non riuscito';
}
