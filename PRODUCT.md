# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

Note: Sona is a Flutter desktop app for Windows 10/11, not a website. `web` is recorded only because it is not a mobile-native (iOS/Android) design language.

## Users

Windows users who listen to music on their PC. There is no primary segment; all of these situations matter equally:

- people working, studying or coding with Sona open beside their work, who want to see what is playing, read the lyrics and skip tracks without switching to the player;
- gamers and streamers who keep the detached mini player always on top of a game or broadcast;
- music lovers who want listening to be something to look at, with the vinyl card and synced lyrics shown large or full screen.

## Product Purpose

Sona shows and controls whatever is playing on the PC, from any app, through one interface the user can make their own. Success means users stop switching to the source player: they see the track, follow the lyrics and control playback from Sona.

## Positioning

Three things together, which Spotify and other single-source players cannot offer:

1. **Works with any player.** Sona reads the Windows media controls (SMTC), so Spotify, YouTube in the browser, Apple Music, VLC and any other app that publishes a media session all work through the same interface.
2. **Aesthetic customization.** The user chooses the accent color, disc style (vinyl or album cover), progress bar style (line or wave), glass or opaque background, and a custom disc image or GIF.
3. **Detachable mini player.** The card can leave the main window as a frameless, resizable, always-on-top window over anything else.

## Operating Context

- Runs beside other apps on the desktop, or over them (always-on-top main window by default, plus the detached mini player).
- Playback is controlled by the source app. Sona sends commands through SMTC: play/pause, next, previous and seek. Per-app volume is available for Spotify.
- Track information arrives as SMTC events only when something changes. The UI estimates position between events.
- Synced lyrics come from LRCLIB (lrclib.net) and need a network connection.

## Capabilities and Constraints

- **Windows only (10/11).** No macOS, Linux or mobile versions are planned.
- **Free and open source (MIT).** No accounts, subscriptions or paid features.
- **Shipped features:** now-playing card with spinning disc, seek bar, playback and volume controls; synced lyrics where the user can click a line to seek to it; detachable mini player; settings for appearance, background, audio, window and about; accent color picker; auto-updater from GitHub releases.
- **In progress (uncommitted as of 2026-10-14):** Playlist section that reads public playlists from Spotify, YouTube Music, Apple Music and Deezer links, plus a now-playing bar. Reading YouTube needs an API key injected at build time.
- **Languages:** currently Italian and English (ARB/gen-l10n). The user has not made this a binding commitment.
- **Undecided:** whether low resource use is a binding constraint. Do not assume it either way.

## Brand Commitments

- Name: **Sona** (wordmark rendered as "SONA").
- App icon: `image/sona.png`, `windows/runner/resources/app_icon.ico`.
- Repository: https://github.com/Carmine0033/Sona

## Evidence on Hand

- README, CHANGELOG (releases v0.1.2 to v0.1.4) and the MIT LICENSE in the repo.
- No user counts, testimonials, reviews or press exist. Do not fabricate any.

## Product Principles

1. **Any source, one interface.** Never build a feature that only works with one player when SMTC can cover all of them. Where a feature is source-specific (such as Spotify volume), say so in the UI.
2. **The user's player.** Customization is part of the product, not a settings afterthought. New visual elements must respect the user's accent color and style choices.
3. **Works where it lives.** Every window state, including the detached frameless one, must stay movable, closable and readable over arbitrary content.
4. **Free, open, no strings.** No account walls, telemetry dark patterns or upsells.
