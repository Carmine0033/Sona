---------------------------
Release Sona V0.1.4
---------------------------

### Added

* \- Detachable mini player mode (frameless, resizable, always-on-top window).
* \- New modern modal settings card with Appearance, Background, Audio, and Window sections.
* \- Accent color customization with curated color palette.
* \- Official MIT License.

### Changed

* \- Refactored UI layout: replaced legacy side panel with the new settings modal.
* \- Simplified playback controls: removed unsupported shuffle and repeat buttons.
* \- Optimized SeekBar wave rendering using RepaintBoundary to avoid background blur repaints.
* \- Unified player volume API (per-app volume for Spotify).

### Fixed

* \- Fixed detached mini player not closing and duplicating when reattaching to the main window.
* \- Fixed auto-updater conflicts using Win32 named mutex and delayed detached installer launch.
* \- Added `runZonedGuarded` startup error boundary to prevent launch failures on corrupted settings.
* \- Added defensive clamping on volume sliders and safe enum bounds checking.
* \- Fixed release script failure on Windows 11 when opening Notepad.
---------------------------
Release Sona V0.1.3
---------------------------

### Added

* feat: add detachable mini player mode
* feat: add accent color customization in a Personalization section
* 

### Changed

* refactor: remove non-functional shuffle and repeat buttons

### Fixed

* Auto Updates
---------------------------
Release Sona V0.1.2
---------------------------

### Added

* Three disc styles: classic vinyl, full album, and animated pulse
* Custom image or GIF in place of the album artwork
* Per-app volume control for Spotify
* Settings persist across restarts

### Changed

* Removed external plugins (native Win32 + dart:io), fixing a build failure

### Fixed

*




