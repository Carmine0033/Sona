---
name: Sona HUD
colors:
  surface: '#15121a'
  surface-dim: '#15121a'
  surface-bright: '#3b3841'
  surface-container-lowest: '#100d15'
  surface-container-low: '#1d1a22'
  surface-container: '#211e27'
  surface-container-high: '#2c2831'
  surface-container-highest: '#37333c'
  on-surface: '#e7e0ec'
  on-surface-variant: '#d0c2d5'
  inverse-surface: '#e7e0ec'
  inverse-on-surface: '#322f38'
  outline: '#998d9e'
  outline-variant: '#4d4353'
  surface-tint: '#e0b6ff'
  primary: '#e0b6ff'
  on-primary: '#4c007d'
  primary-container: '#9d4edd'
  on-primary-container: '#fffdff'
  inverse-primary: '#8433c4'
  secondary: '#e1b6ff'
  on-secondary: '#4c007b'
  secondary-container: '#691a9f'
  on-secondary-container: '#d69eff'
  tertiary: '#deb7ff'
  on-tertiary: '#4a007f'
  tertiary-container: '#9a4fdf'
  on-tertiary-container: '#fffdff'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#f2daff'
  primary-fixed-dim: '#e0b6ff'
  on-primary-fixed: '#2e004e'
  on-primary-fixed-variant: '#6a0baa'
  secondary-fixed: '#f2daff'
  secondary-fixed-dim: '#e1b6ff'
  on-secondary-fixed: '#2e004d'
  on-secondary-fixed-variant: '#691a9f'
  tertiary-fixed: '#f1dbff'
  tertiary-fixed-dim: '#deb7ff'
  on-tertiary-fixed: '#2d0050'
  on-tertiary-fixed-variant: '#680eac'
  background: '#15121a'
  on-background: '#e7e0ec'
  surface-variant: '#37333c'
typography:
  headline-xl:
    fontFamily: Space Grotesk
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.03em
  headline-lg:
    fontFamily: Space Grotesk
    fontSize: 24px
    fontWeight: '500'
    lineHeight: 32px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Space Grotesk
    fontSize: 18px
    fontWeight: '500'
    lineHeight: 26px
    letterSpacing: -0.01em
  body-lg:
    fontFamily: Geist
    fontSize: 15px
    fontWeight: '400'
    lineHeight: 22px
    letterSpacing: -0.01em
  body-md:
    fontFamily: Geist
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
    letterSpacing: 0em
  body-sm:
    fontFamily: Geist
    fontSize: 11px
    fontWeight: '400'
    lineHeight: 16px
    letterSpacing: 0.01em
  label-lg:
    fontFamily: JetBrains Mono
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.06em
  label-md:
    fontFamily: JetBrains Mono
    fontSize: 10px
    fontWeight: '500'
    lineHeight: 14px
    letterSpacing: 0.08em
  label-sm:
    fontFamily: JetBrains Mono
    fontSize: 9px
    fontWeight: '600'
    lineHeight: 12px
    letterSpacing: 0.12em
spacing:
  gutter: 0.75rem
  margin: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 0.75rem
  space-lg: 1.25rem
  space-xl: 2rem
---

## Brand & Style

This design system embodies supreme calculated authority, transcendent tranquility, and lethal precision—directly inspired by Sosuke Aizen’s presence in Hueco Mundo. Designed as an ethereal desktop audio overlay, it commands the screen with absolute stillness and intoxicating power.

The aesthetic fuses **Ethereal Brutalism** with **Dark Violet Glassmorphism**. UI planes evoke suspended obsidian monoliths, framed by ultra-fine hairline light guides that reference Kyōka Suigetsu’s crystalline edge. Spiritual Reiatsu manifests not as noisy clutter, but as sharp amethyst accents and deep violet atmospheric bleeds. The tone is calculated, hyper-refined, and unobtrusive during gaming or high-focus creative sessions, yet striking and transcendent when interacted with.

## Colors

The palette establishes an absolute contrast between cosmic void depths and divine spiritual radiance.

- **Obsidian Voids & Canvas Tiers:**
  - `canvas-abyss`: `#08060d` — The deep void baseline, absorbing all light.
  - `surface-base`: `#0f0b18` — Primary translucent panel layer (75-85% alpha).
  - `surface-elevated`: `#181226` — High-tier modules, control islands, and floating widgets.
  - `surface-stroke`: `rgba(199, 125, 255, 0.12)` — Ghostly crystalline hairline dividers.

- **Reiatsu & Hōgyoku Resonance:**
  - `primary` (`#9d4edd`): Resonant spiritual purple for interactive cores, active EQ bands, and active states.
  - `secondary` (`#c77dff`): Amethyst electric brilliance used for peak audio signals, playhead scrubbers, and focused borders.
  - `tertiary` (`#7b2cbf`): Deep psychic undertone for back-glows and gradient sinks.

- **Divine Arrancar Whites & Accents:**
  - `luminescence-pure`: `#ffffff` — Crisp, razor-sharp typography for primary track titles, volume decibels, and high-priority glyphs.
  - `luminescence-subtle`: `#e0aaff` — Ethereal secondary text, spectral labels, and track metadata.
  - `text-muted`: `rgba(224, 170, 255, 0.45)` — Ghostly auxiliary indicators and inactive parameters.

## Typography

The typographic hierarchy establishes surgical, technical precision:

- **Space Grotesk** anchors headline levels with architectural geometry and stark, calculating modernity. It echoes the sharp silhouettes of Las Noches architecture.
- **Geist** powers the functional body layer, guaranteeing neutral, anti-fatigue clarity at small overlay scales against dark glass.
- **JetBrains Mono** drives all telemetry, decibel values, timestamps, frequency labels, and system states. Set strictly in uppercase with wide tracking for an advanced military-spectral HUD readout.

## Layout & Spacing

Because this system operates as a non-intrusive desktop audio overlay and floating HUD, spatial economy is paramount. Layout relies on dense, calibrated component padding with rigid micro-gaps.

- **HUD Grid & Dock Structure:** The overlay adheres to a modular, anchorable node grid with an 8px base rhythm. Docking anchors support snapping to screen corners, mini-island pill modes, or expanded vertical mixer sidebars.
- **Negative Space:** Empty layout space behaves like a vacuum. Panels float with `space-md` gaps between audio modules, ensuring zero visual noise interferes with the underlying desktop work or gaming canvas.

## Elevation & Depth

Elevation does not rely on conventional drop shadows. Instead, it utilizes **Spectral Glassmorphism and Void Occlusion**:

- **Layer 0 (Canvas Backing):** `background: rgba(8, 6, 13, 0.72)`, paired with `backdrop-filter: blur(24px) saturate(160%)`.
- **Layer 1 (Modular Island):** `background: rgba(24, 18, 38, 0.65)`, rimmed by a 1px inner hairline stroke `box-shadow: inset 0 0 0 1px rgba(199, 125, 255, 0.15)`.
- **Layer 2 (Active Core & Focused State):** Surface illuminates with an ambient psychic aura—`box-shadow: 0 0 20px -2px rgba(157, 78, 221, 0.35), inset 0 0 12px 0 rgba(199, 125, 255, 0.2)`.
- **Kyōka Suigetsu Edge:** Crisp single-pixel light refraction lines appear only on the top and left borders (`rgba(255, 255, 255, 0.25)`), creating the illusion of razor-sharp glass blades.

## Shapes

The shape hierarchy is strictly **Sharp (Level 0)**.

To mirror the merciless geometry of the Espada throne and Katana edges, all buttons, sliders, meters, and overlay panels have zero border radius. Modules use clean right angles, diamond-cut 45° chamfered accents on high-level status badges, and strict rectangular framing. This eliminates soft consumer-toy design in favor of dangerous, cold, transcendental superiority.

## Components

### Audio Control Buttons
- **Style:** Obsidian monoliths with razor 1px borders (`rgba(199, 125, 255, 0.2)`).
- **Idle State:** Background `rgba(15, 11, 24, 0.8)`, icon colored in `#e0aaff`.
- **Hover & Active:** Background transforms to `#181226`, border flares to `#c77dff`, and icon blooms to `#ffffff` with a subtle `drop-shadow(0 0 6px #9d4edd)`.
- **Shape:** 0px radius; icon dimensions strictly 16x16px on a 32x32px target.

### VU Meters & EQ Visualizer
- **Structure:** Vertical or horizontal segmented light matrices.
- **Segments:** Micro-rectangles spaced by 1px gaps. Baseline levels pulse in `#7b2cbf`; mid levels glow in `#9d4edd`; dynamic audio peaks erupt into blinding `#ffffff`.
- **Overlay Decibel Ticks:** Labeled in `JetBrains Mono` (`label-sm`), rendered in `#e0aaff` at 50% opacity.

### Audio Scrubbers & Volume Faders
- **Track:** 2px hairline beam in `rgba(224, 170, 255, 0.15)`. Active fill glows in `#9d4edd`.
- **Thumb:** A sharp, vertical rectangular needle (2px width × 12px height) in `#ffffff`, trailing an amethyst ambient drop shadow.

### Telemetry Chips & Input Badges
- **Form:** Ultra-compact badges featuring `label-sm` monospaced type.
- **Appearance:** Background `rgba(123, 44, 191, 0.15)`, text `#e0aaff`, surrounded by a 1px border with optional 45° clipped corners on primary input devices (e.g., `MIC ACTIVE`, `48kHz / 24-BIT`).

### Holographic Sound Stage & Spatial Audio Card
- **Frame:** Floating container framed by razor-thin borders, with a faint radial gradient emitting from the center (`rgba(123, 44, 191, 0.12) to transparent`).
- **Interactive Nodes:** Audio sources appear as sharp diamond points (`#c77dff`) hovering over an obsidian planar grid. Selected sources project an upright violet beam.

### Inputs & Device Selectors
- **Dropdowns & Inputs:** Flat black background (`#08060d`), sharp square boundaries, active focus triggers a crisp `#c77dff` hairline outline with a 4px amethyst ambient bleed.