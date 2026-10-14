---
name: Sona
description: A glass-fronted vinyl player for whatever Windows is playing.
colors:
  reiatsu-violet: "#9D4EDD"
  abyss: "#08060D"
  obsidian-glass: "#181226"
  obsidian-deep: "#0F0B18"
  dusk-container: "#211E27"
  veil-outline: "#4D4353"
  moonlit-text: "#E7E0EC"
  lilac-mist: "#D0C2D5"
  pure-white: "#FFFFFF"
  amethyst-whisper: "#E0AAFF"
  text-secondary: "rgba(255, 255, 255, 0.70)"
  text-tertiary: "rgba(255, 255, 255, 0.60)"
  coral-error: "#FFB4AB"
typography:
  lyric-active:
    fontFamily: "Segoe UI, system-ui, sans-serif"
    fontSize: "23px"
    fontWeight: 700
    lineHeight: 1.35
    letterSpacing: "-0.2px"
  lyric:
    fontFamily: "Segoe UI, system-ui, sans-serif"
    fontSize: "18px"
    fontWeight: 500
    lineHeight: 1.35
    letterSpacing: "-0.2px"
  headline:
    fontFamily: "Segoe UI, system-ui, sans-serif"
    fontSize: "20px"
    fontWeight: 700
    letterSpacing: "-0.4px"
  title:
    fontFamily: "Segoe UI, system-ui, sans-serif"
    fontSize: "17px"
    fontWeight: 600
  body:
    fontFamily: "Segoe UI, system-ui, sans-serif"
    fontSize: "14px"
    fontWeight: 500
  body-sm:
    fontFamily: "Segoe UI, system-ui, sans-serif"
    fontSize: "13px"
    fontWeight: 400
  caption:
    fontFamily: "Segoe UI, system-ui, sans-serif"
    fontSize: "11px"
    fontWeight: 400
    fontFeature: "tnum"
  wordmark:
    fontFamily: "Segoe UI, system-ui, sans-serif"
    fontSize: "13px"
    fontWeight: 700
    letterSpacing: "2px"
rounded:
  xs: "4px"
  sm: "6px"
  md: "8px"
  lg: "10px"
  xl: "12px"
  line: "14px"
  modal: "18px"
  card: "24px"
  full: "9999px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "12px"
  lg: "16px"
  xl: "20px"
  2xl: "24px"
  3xl: "32px"
components:
  player-card:
    backgroundColor: "{colors.obsidian-glass}"
    rounded: "{rounded.card}"
    padding: "20px 24px"
    width: "440px"
  button-play-hero:
    backgroundColor: "{colors.pure-white}"
    textColor: "{colors.abyss}"
    rounded: "{rounded.full}"
    size: "52px"
  button-transport:
    backgroundColor: "rgba(255, 255, 255, 0.10)"
    textColor: "{colors.pure-white}"
    rounded: "{rounded.full}"
    size: "40px"
  button-header-icon:
    backgroundColor: "rgba(0, 0, 0, 0.25)"
    textColor: "{colors.text-secondary}"
    rounded: "{rounded.lg}"
    padding: "8px"
  nav-item:
    backgroundColor: "transparent"
    textColor: "{colors.text-tertiary}"
    typography: "{typography.body-sm}"
    rounded: "{rounded.lg}"
    padding: "10px 12px"
  nav-item-active:
    backgroundColor: "rgba(157, 78, 221, 0.18)"
    textColor: "{colors.pure-white}"
    rounded: "{rounded.lg}"
    padding: "10px 12px"
  chip:
    backgroundColor: "rgba(255, 255, 255, 0.05)"
    textColor: "{colors.text-tertiary}"
    rounded: "{rounded.md}"
    padding: "7px 14px"
  chip-selected:
    backgroundColor: "rgba(157, 78, 221, 0.25)"
    textColor: "{colors.pure-white}"
    rounded: "{rounded.md}"
    padding: "7px 14px"
  input-field:
    backgroundColor: "rgba(24, 18, 38, 0.80)"
    textColor: "{colors.moonlit-text}"
    typography: "{typography.body-sm}"
    rounded: "{rounded.xl}"
  settings-modal:
    backgroundColor: "{colors.obsidian-glass}"
    rounded: "{rounded.modal}"
    width: "660px"
    height: "440px"
  tooltip:
    backgroundColor: "{colors.dusk-container}"
    textColor: "{colors.moonlit-text}"
    rounded: "{rounded.sm}"
---

# Design System: Sona

## Overview

**Creative North Star: "The Glass Vinyl"**

Sona is a physical object behind a pane of tinted glass. The record (a spinning vinyl, or the bare album cover) sits at the center of a translucent card. The glass takes its tint from the user's accent color, and the room around it is lit by the track itself: the album artwork, blurred until only its colors remain, fills the window behind everything.

The interface is discreet and refined. Controls are thin-edged, low in contrast and quiet until touched. Color appears only where the user's attention belongs: the active state, the playing progress, the current lyric line. The music is the subject and the chrome steps back. A single glow, the accent halo around the player card, is the one moment of spectacle.

Everything is the user's. The accent hue is a user setting, so the system is written in roles and alpha steps of "the accent", never in fixed hues. Reiatsu Violet is only the default.

**Key Characteristics:**
- Dark, near-black canvas lit from behind by blurred album art.
- Translucent obsidian glass surfaces tinted by the accent at low alpha (6–10%).
- Softly rounded geometry everywhere; circles for the record and transport buttons.
- Text hierarchy built from a ladder of white opacities, not from extra hues.
- One accent halo, reserved for the player card.

## Colors

A violet-tinted obsidian palette in which the only saturated color is the accent the user picks.

### Primary
- **Reiatsu Violet** (`reiatsu-violet`): the default accent, the deep spiritual purple of Aizen's reiatsu in *Bleach*. It is the theme's `primary`, which the user can replace from Settings → Appearance. It drives active navigation, selected chips, progress fill, focus borders, the card tint and the halo. Every accent-derived surface reads `colorScheme.primary`, so a new accent repaints the whole app.

### Neutral
- **Abyss** (`abyss`): the window canvas behind every screen. It is the backdrop in opaque mode and the veil color (65% alpha) over the blurred artwork in glass mode.
- **Obsidian Glass** (`obsidian-glass`): the base of the raised surfaces (player card, settings modal, now-playing bar, dialogs). It is always blended with the accent at 6–10%, and at 45% alpha on the player card.
- **Obsidian Deep** (`obsidian-deep`): the darker recessed panel, used for the settings navigation column and the empty now-playing bar.
- **Dusk Container** (`dusk-container`): tooltip and snackbar fill.
- **Veil Outline** (`veil-outline`): hairline border on tooltips.
- **Moonlit Text** (`moonlit-text`): body text on surfaces and input text.
- **Lilac Mist** (`lilac-mist`): supporting copy in empty states and hints.
- **Pure White** (`pure-white`): track titles, the active lyric, selected labels and the face of the hero Play button.
- **Amethyst Whisper** (`amethyst-whisper`): the artist line and other secondary text inside the player card, where it reads as glass-tinted rather than gray.
- **Coral Error** (`coral-error`): error icons and error copy.

### Named Rules
**The User's Accent Rule.** Never hard-code a hue for an interactive or decorative element. Derive it from the theme primary with an alpha step: 0.06 (tint), 0.12–0.18 (hover/active fill), 0.25–0.35 (selected fill, borders) or 0.5+ (focus, emphasis).

**The White Ladder Rule.** Text hierarchy on dark surfaces is pure white for primary, 70% for labels and 60% for secondary and meta. Anything below 60% is for icons, disabled states and already-sung lyric lines, never for copy someone has to read.

**The Album Is the Light Rule.** In glass mode the backdrop is the current artwork blurred at sigma 65 under a 65% Abyss veil. Never replace it with a gradient or a stock texture. Opaque mode is flat Abyss.

## Typography

**Body Font:** Segoe UI (the Windows system face that Flutter uses by default; no bundled fonts).

**Character:** One family carries everything. Hierarchy comes from size, weight and white opacity, so the type stays native and calm next to whatever else is on the desktop.

### Hierarchy
- **Lyric Active** (700, 23px, 1.35): the line being sung. It is the largest text in the app, with a soft accent text-glow.
- **Lyric** (500, 18px, 1.35): upcoming lines at 62% white, sung lines at 38%.
- **Headline** (700, 20px, −0.4px): the track title in the player card. It scrolls as a marquee when too long.
- **Title** (600, 17–18px): modal titles, empty-state headings and the detached-card title.
- **Body** (500, 14px): settings row labels and track titles in lists.
- **Body Small** (400, 13px): navigation, input text, hints and settings subtitles (12px).
- **Caption** (400, 11px, tabular figures): elapsed and total time, durations, metadata.
- **Wordmark** (700, 11–13px, 1.5–2px tracking, uppercase): "SONA" in the sidebar (accent color) and in the card header (70% white).

### Named Rules
**The Fixed Digits Rule.** Every time, duration and counter uses tabular figures, so ticking values never jitter.

## Layout

The main window is a fixed 160px sidebar beside a content area (1280×780 default, 920×580 minimum). The player screen places the card on the left (max 440px wide, vertically centered, 32px left inset) and the synced lyrics filling the rest. Below 780px of content width it stacks: the card on top, then a 420px-tall lyrics panel, in one scroll.

The playlist screen is a link field (16px inset) above a full-width track list, with the now-playing bar docked at the bottom (68px). Settings open as a centered 660×440 modal over a blurred, dimmed shell (blur 8, 55% black); Esc or a click outside closes it.

The detached mini player is a frameless, transparent, always-on-top window (440×580 default, 280×360 minimum). The card scales down to fit, and an 8px invisible resize frame surrounds it. Every state must stay draggable.

The spacing rhythm runs on a 4px step: 4, 8, 12, 16, 20, 24, 32. Rows inside settings align on a shared 168px label column.

## Elevation & Depth

Depth comes from glass layering: translucent obsidian over a blurred, veiled artwork, with a hairline accent border defining each raised edge. Raised surfaces get soft dark drop shadows. The accent glow is a signature, not a depth system.

### Shadow Vocabulary
- **Card halo** (`0 4px 36px 2px` accent at 14%, plus `0 8px 28px 4px rgba(0,0,0,0.45)`): the player card only.
- **Hero glow** (`0 3px 16px 1px` accent at 45%): the white Play button only.
- **Modal drop** (`0 8px 40px 4px rgba(0,0,0,0.65)`): the settings modal and dialogs.
- **Lyric glow** (text-shadow, blur 18, accent at 50%): the active lyric line.

### Named Rules
**The Single Halo Rule.** The accent halo belongs to the player card and the hero Play button, nowhere else. Modals, dialogs and bars lift with neutral dark shadows only.

## Shapes

The form language is soft and object-like. Radii grow with the size of the surface: thumbnails 4–6px, chips and small buttons 8px, nav items and icon buttons 10px, inputs 12px, lyric lines 14px, modals 18px, the player card 24px. The record, the transport buttons and the accent status dot are perfect circles. Raised surfaces carry a 1–1.5px border of the accent at 20–30% alpha. Recessed or neutral controls use white at 8–18%.

## Components

### Player Card (signature)
The glass vinyl itself.
- **Structure:** a header (accent status dot, "SONA" wordmark, then disc style, seek bar style and detach toggles), the spinning disc (185px), the title (marquee), the artist (Amethyst Whisper), the seek bar (line or animated wave), the transport row and the volume row.
- **Surface:** Obsidian Glass at 45% blended with the accent at 10%, a 1.5px accent border at 28%, 24px radius, and the card halo.
- **Travel:** the card owns its own style toggles, because it can leave the main window as the mini player.

### Buttons
- **Hero Play:** a 52px white circle with a black glyph and the hero glow. It is the one high-contrast object on screen.
- **Transport (previous/next):** a 40px circle in white at 10%, with a 1px white border at 18% and a white glyph.
- **Header icon:** a 10px-radius square in black at 25% with a hairline white border at 10% and a 70% white icon.
- **Text and outlined actions:** the label is in the accent color. Outlined actions use an accent border at 40–50%, filled-tint actions use an accent background at 12%, and both have an 8px radius.
- **Hover / press:** ink overlays at 8% (hover) and 12% (press) of the foreground color, drawn on the button's own Material so the feedback stays visible. Every icon-only button has a tooltip.

### Chips
- **Style:** an 8px radius with 7×14px padding, white at 5% with a white border at 24%, and the label at 60% white, 12px.
- **Selected:** accent fill at 25%, a full-accent border, white 600-weight label, with a 150ms transition.

### Inputs / Fields
- **Style:** Obsidian Glass fill at 80%, a hairline white border at 8%, a 12px radius (8px for the compact hex field), Moonlit Text, and a Lilac Mist hint.
- **Focus:** the border shifts to the accent at 80%. The caret and selection use the accent (selection at 35%).
- **Loading:** the field turns read-only and an accent spinner replaces the trailing action.
- **Error:** a Coral Error helper line under the field.

### Navigation
- **Sidebar item:** an 18px icon and 13px label at 60% white on transparent, with a 10px radius and 10×12px padding.
- **Active:** accent fill at 18%, accent icon, white 600-weight label, with a 160ms transition.
- **Settings item:** the same, plus a 1px accent border at 35% when active.

### Synced Lyrics
- **Lines:** padded 12×16px and spaced 8px apart, with a 14px radius. The whole list fades in and out at the top and bottom 12%.
- **Active line:** white at 8% fill, with the Lyric Active type and glow.
- **Interaction:** hovering a line shows a 5% white wash, and clicking it seeks to that line. Auto-scroll centers the active line and pauses for 4 seconds after the user scrolls.

### Now-Playing Bar
A 68px dock on Obsidian Glass at 95% with a top border in white at 12%. Artwork (44px, 6px radius) sits beside the title and artist, the transport sits in the center (with an accent-filled Play), and the ticking elapsed/total time and a jump-to-player button sit on the right.

### Empty States
A centered column at most 360–420px wide: a 44–56px icon (accent or white at about 45–55%), a Title-size heading in white, and a Lilac Mist explanation of what to do next. Inside the mini player it sits on its own glass panel and offers the reattach action.

## Do's and Don'ts

### Do:
- **Do** derive every accent use from `colorScheme.primary` with the alpha steps of The User's Accent Rule.
- **Do** keep text on the White Ladder: 100%, 70% or 60%.
- **Do** use tabular figures for every time and count.
- **Do** give every icon-only control a tooltip and a visible hover state.
- **Do** keep every window state (empty, loading, error, detached) movable, closable and readable over arbitrary desktop content.

### Don't:
- **Don't** put the accent halo on anything except the player card and the hero Play button.
- **Don't** hard-code surface colors in dialogs or modals (such as `#1A0B2E`). Use the theme's dialog and surface tokens.
- **Don't** use readable copy below 60% white opacity.
- **Don't** replace the blurred artwork backdrop with gradients or decorative textures.
- **Don't** duplicate the same control in two places on one screen.
