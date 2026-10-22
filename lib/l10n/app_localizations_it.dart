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
  String get playlist => 'Playlist';

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
  String get discordPresence => 'Stato su Discord';

  @override
  String get discordPresenceSubtitle =>
      'Mostra su Discord il brano che stai ascoltando';

  @override
  String get discordPaused => 'In pausa';

  @override
  String get discordDownload => 'Scarica Sona';

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

  @override
  String get appearance => 'Aspetto';

  @override
  String get background => 'Sfondo';

  @override
  String get audio => 'Audio';

  @override
  String get window => 'Finestra';

  @override
  String get about => 'Info';

  @override
  String get systemVolume => 'Volume di sistema';

  @override
  String get systemVolumeSubtitle => 'Regola il volume di riproduzione';

  @override
  String get checkForUpdates => 'Verifica aggiornamenti';

  @override
  String get upToDate => 'Sei alla versione più recente';

  @override
  String get checkingUpdates => 'Verifica in corso...';

  @override
  String updateAvailable(Object version) {
    return 'Aggiornamento disponibile: v$version';
  }

  @override
  String get updateCheckFailed =>
      'Impossibile verificare gli aggiornamenti. Controlla la connessione e riprova.';

  @override
  String get nothingPlayingHint =>
      'Avvia la musica in Spotify, YouTube o in qualsiasi app che compare nei controlli multimediali di Windows.';

  @override
  String get previousTrack => 'Precedente';

  @override
  String get nextTrack => 'Successivo';

  @override
  String get play => 'Riproduci';

  @override
  String get pause => 'Pausa';

  @override
  String get mute => 'Disattiva audio';

  @override
  String get unmute => 'Riattiva audio';

  @override
  String get close => 'Chiudi';

  @override
  String get invalidHex => 'Usa #RRGGBB o #AARRGGBB';

  @override
  String get playlistLinkHint => 'Incolla il link di una playlist…';

  @override
  String get pasteAndLoad => 'Incolla e carica';

  @override
  String get removePlaylist => 'Rimuovi playlist';

  @override
  String get playlistEmptyTitle => 'Incolla il link di una playlist pubblica';

  @override
  String get playlistEmptySubtitle =>
      'Spotify · YouTube Music · Apple Music · Deezer';

  @override
  String trackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count brani',
      one: '1 brano',
    );
    return '$_temp0';
  }

  @override
  String get playlistTruncated =>
      'Elenco parziale: il servizio ha restituito solo una parte dei brani.';

  @override
  String openTrack(Object service) {
    return 'Apri in $service';
  }

  @override
  String playlistErrorUnexpected(Object error) {
    return 'Errore imprevisto: $error';
  }

  @override
  String get playlistErrorInvalidLink =>
      'Il testo incollato non è un link valido.';

  @override
  String get playlistErrorAutoMix =>
      'I mix automatici di YouTube non sono playlist vere: salvalo come playlist e riprova.';

  @override
  String get playlistErrorUnsupported =>
      'Link non supportato. Usa una playlist di Spotify, YouTube Music, Apple Music o Deezer.';

  @override
  String get playlistErrorNotFound => 'Playlist non trovata, oppure è privata.';

  @override
  String get playlistErrorForbidden =>
      'Questa playlist è privata: rendila pubblica e riprova.';

  @override
  String get playlistErrorRateLimited =>
      'Troppe richieste o quota esaurita: riprova più tardi.';

  @override
  String get playlistErrorNetwork =>
      'Connessione non riuscita. Controlla rete e firewall.';

  @override
  String get playlistErrorParse =>
      'Il servizio ha cambiato formato: serve un aggiornamento di Sona.';

  @override
  String playlistErrorMissingKey(Object service) {
    return 'Lettura da $service non configurata (chiave API mancante).';
  }

  @override
  String get thisService => 'questo servizio';

  @override
  String get findingAudio => 'Ricerca dell\'audio…';

  @override
  String get stopPlayback => 'Interrompi';

  @override
  String get shuffle => 'Riproduzione casuale';

  @override
  String get repeat => 'Ripeti';

  @override
  String get repeatOne => 'Ripeti brano';

  @override
  String get audioErrorBlocked =>
      'YouTube sta bloccando la riproduzione. Aggiorna Sona o riprova più tardi.';

  @override
  String get audioErrorNoMatch =>
      'Nessun audio compatibile trovato per questo brano.';

  @override
  String get audioErrorUnavailable => 'Audio non disponibile per questo brano.';

  @override
  String get audioErrorNetwork =>
      'Connessione non riuscita. Controlla la rete e riprova.';

  @override
  String get audioErrorPlayback => 'Riproduzione interrotta da un errore.';

  @override
  String get libraryInputHint =>
      'Incolla il link di una playlist Spotify, YouTube Music, Apple Music o Deezer…';

  @override
  String get libraryPaste => 'Incolla';

  @override
  String get libraryAdd => 'Aggiungi playlist';

  @override
  String get libraryAll => 'Tutte';

  @override
  String get libraryFavorites => 'Preferite';

  @override
  String get libraryYourPlaylists => 'Le tue playlist';

  @override
  String libraryAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count disponibili',
      one: '1 disponibile',
    );
    return '$_temp0';
  }

  @override
  String libraryTracks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count brani',
      one: '1 brano',
    );
    return '$_temp0';
  }

  @override
  String librarySourcePlaylist(String source) {
    return 'Playlist $source';
  }

  @override
  String get libraryNowPlaying => 'In riproduzione';

  @override
  String get libraryNowPlayingTicker => 'Riproduzione in corso:';

  @override
  String get libraryPlayNow => 'Riproduci ora';

  @override
  String get libraryPause => 'Pausa';

  @override
  String get librarySync => 'Sincronizza';

  @override
  String get librarySynced => 'Playlist aggiornata';

  @override
  String get libraryRemove => 'Rimuovi';

  @override
  String libraryRemoveConfirm(String title) {
    return 'Rimuovere \"$title\" dalla libreria?';
  }

  @override
  String get libraryCancel => 'Annulla';

  @override
  String get libraryBack => 'Libreria';

  @override
  String get libraryAddCardTitle => 'Aggiungi playlist';

  @override
  String get libraryAddCardBody => 'Incolla il link di una playlist pubblica';

  @override
  String get libraryAddCardAction => 'Incolla link';

  @override
  String get libraryUpdatedToday => 'Aggiornata oggi';

  @override
  String get libraryUpdatedYesterday => 'Aggiornata ieri';

  @override
  String libraryUpdatedDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Aggiornata $days giorni fa',
      one: 'Aggiornata 1 giorno fa',
    );
    return '$_temp0';
  }

  @override
  String get settingsBarTitle => 'Barra di riproduzione';

  @override
  String get settingsBarBackground => 'Sfondo';

  @override
  String get barBgGlass => 'Trasparente';

  @override
  String get barBgAlbum => 'Copertina sfocata';

  @override
  String get barBgCustom => 'Immagine / GIF';

  @override
  String get settingsBarPick => 'Scegli immagine o GIF';

  @override
  String get settingsBarChange => 'Cambia';

  @override
  String get settingsBarDim => 'Oscuramento';

  @override
  String get settingsBarIcons => 'Stile icone';

  @override
  String get iconStyleFilled => 'Piene';

  @override
  String get iconStyleOutlined => 'Contorno';

  @override
  String get iconStyleRounded => 'Arrotondate';

  @override
  String get iconStyleSharp => 'Squadrate';

  @override
  String get settingsBarTooLarge => 'File troppo grande (massimo 15 MB)';

  @override
  String get settingsBarFailed => 'Impossibile caricare il file';

  @override
  String get searchTracksHint => 'Cerca un brano in tutte le playlist';

  @override
  String get searchInPlaylistHint => 'Cerca in questa playlist';

  @override
  String get searchOpen => 'Cerca (Ctrl+F)';

  @override
  String get searchClose => 'Chiudi ricerca';

  @override
  String searchResults(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count risultati',
      one: '1 risultato',
      zero: 'Nessun risultato',
    );
    return '$_temp0';
  }

  @override
  String get searchNoResults => 'Nessun brano trovato';

  @override
  String get searchTooMany =>
      'Mostrati i primi 200 risultati: affina la ricerca';
}
