<p align="center">
  <b>English</b> · <a href="README.ko.md">한국어</a> · <a href="README.ja.md">日本語</a> · <a href="README.zh-Hans.md">简体中文</a>
</p>

<p align="center">
  <img src="docs/icon.png" width="128" height="128" alt="Canopy app icon">
</p>

# Canopy

A native macOS menu-bar app that plays looping nature footage from [Pixabay](https://pixabay.com) as your actual desktop background — a live wallpaper, not a screensaver.

![Canopy browsing screen — hero background, My Collection and Nature shelves, search field, and the now-playing bar](docs/screenshots/screenshot.png)

## Features

- **Browse & play** — Nature/Backgrounds/Animals/Travel shelves plus free-text search, with pagination ("Load More") through Pixabay's catalog
- **Per-display wallpapers** — pick a different video for each connected monitor, or apply one to **All** displays at once
- **My Collection** — videos you've played are saved automatically; reorder by drag-and-drop or the Move Earlier/Later controls, remove with one click
- **True Retina rendering** — the desktop-level player syncs to each screen's actual backing scale factor, so 4K source video renders crisp instead of upscaled
- **Battery-aware** — playback pauses automatically on screen lock/sleep, Low Power Mode, and (optionally) whenever running on battery
- **Menu-bar controls** — click the status item for Open / Play–Pause / Quit; the main window itself is a normal titled, resizable window (⌘Q to quit, closable, no Dock icon)
- **Localized** — English, 한국어, 日本語, 简体中文

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15+ (for building)
- A free [Pixabay API key](https://pixabay.com/api/docs/) — Canopy doesn't ship a shared key, so you'll paste your own into Settings on first launch

## Installation

Install via Homebrew — this repository doubles as its own tap, so no separate tap repo is needed:

```bash
brew tap mrKangHo/canopy https://github.com/mrKangHo/Canopy
brew install --cask canopy
```

Releases are ad-hoc signed, not notarized by Apple, so the first launch will be blocked by Gatekeeper as "from an unidentified developer." Right-click `Canopy.app` in `/Applications` and choose **Open** once to allow it — only needed the first time.

To update to a new release: `brew upgrade --cask canopy`.

## Building

The project is generated from `project.yml` via [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
brew install xcodegen   # once
xcodegen generate
open Canopy.xcodeproj
```

Build and run (⌘R) from Xcode. A `Package.swift` is also included for quick `swift build`/`swift run` iteration on the non-UI layers, but the XcodeGen project is what actually produces the signed `.app` with its Info.plist, asset catalog, and app icon.

Whenever you add, remove, or rename a source file, re-run `xcodegen generate` — the `.xcodeproj` is regenerated output, not something to hand-edit.

## Project layout

```
Sources/Canopy/
  App/            App entry point + AppDelegate (status item, menu)
  MainWindow/      SwiftUI screens: hero browse view, video detail, settings, shelves
  Models/          WallpaperManager (app state), DisplayInfo, CategorySection
  PixabayAPI/      Networking client + response models
  Caching/         On-disk video cache, search-result cache
  WallpaperWindow/ The actual desktop-level AVPlayer window, one per display
Resources/
  Assets.xcassets       App icon, status-bar icon
  Localizable.xcstrings String Catalog (en/ko/ja/zh-Hans)
docs/
  icon.png, screenshots/ Images used in this README (not part of the app bundle)
Casks/
  canopy.rb              Homebrew Cask — lets this repo serve as its own tap
```

The desktop wallpaper itself is rendered by a borderless `NSWindow` pinned one level below the Finder desktop-icon layer on each screen (`WallpaperWindow/WallpaperWindowController.swift`) — it never touches the system desktop-picture API, so it isn't affected by macOS's periodic tightening of that API's permissions.

## Content & licensing

Video content is streamed from Pixabay and cached locally after first playback, per [Pixabay's Content License](https://pixabay.com/service/license/) and [API Terms](https://pixabay.com/api/docs/) (no permanent hot-linking, search results cached 24h, attribution shown in Settings).

## Known limitations

- Pixabay's video API caps out at 4K (3840×2160) — there's currently no free source of genuine 8K footage suitable for this app; see the in-repo discussion if you're evaluating alternatives
- Releases are ad-hoc signed (no Apple Developer Program membership behind this build) and not notarized, not sandboxed, and not on the Mac App Store — desktop-level window placement and the current caching approach would need adjustment for App Sandbox
- `CGDirectDisplayID`-based per-display memory is best-effort across reconnects/reboots, matching typical wallpaper-app behavior, not guaranteed by Apple
