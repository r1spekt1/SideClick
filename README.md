# SideClick

A macOS menu bar app for mice with back/forward side buttons: programmable side buttons
(single / double / triple click and long press), pointer speed and acceleration,
smooth scroll, scroll invert, and Shift for horizontal scroll.

Works with any external mouse whose side buttons are the standard mouse buttons 4 and 5.
It is developed and tested on a Xiaomi Silent Mouse 2; other mice should work but are untested,
so reports are welcome.

## Why

Side buttons are standard mouse buttons 4 and 5. Some apps, for
example Vorssaint, install an event tap that swallows those buttons, so other software never
sees them (see `docs/spike/`). Turn off the mouse features in such apps. SideClick warns
you when it detects this.

## Install

Download the latest `.dmg` from [Releases](https://github.com/r1spekt1/SideClick/releases),
open it, and drag `SideClick.app` onto the `Applications` shortcut.

Requires macOS 14+ and Apple Silicon. The only permission needed is **Accessibility**; the app
asks for it on first launch.

> The app is ad-hoc signed and not notarized, so Gatekeeper blocks it on first launch. Either:
>
> - open **System Settings → Privacy & Security** and click **Open Anyway** next to the
>   SideClick message (macOS 15+; on macOS 14 right-click the app and choose **Open**), or
> - remove the quarantine flag once:
>
>   ```bash
>   xattr -dr com.apple.quarantine /Applications/SideClick.app
>   ```
>
> Because the signature is ad-hoc, macOS also asks you to re-grant Accessibility after you
> replace the app with a newer version.

### Upgrading from XiaomiMouseFix

SideClick is the new name of XiaomiMouseFix (0.1.0). It has a new bundle identifier, so:
grant **Accessibility** again, and remove the old `XiaomiMouseFix` entry from **System Settings →
General → Login Items** if you had enabled "Launch at login". Your settings are copied over
automatically on first launch.

## Build from source

```bash
scripts/build-app.sh
```

Install into `~/Applications` (a stable path for Accessibility and "Launch at login"):

```bash
pkill -x SideClick; ditto ~/Library/Caches/SideClick/SideClick.app ~/Applications/SideClick.app
```

```bash
open ~/Applications/SideClick.app
```

To produce a drag-to-Applications DMG (ad-hoc signed) next to the app:

```bash
scripts/make-dmg.sh
```

The build is created outside the repo (in `~/Library/Caches/SideClick`) because
`~/Documents` can be synced by iCloud, and iCloud's extended attributes break `codesign`.

Run the tests:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --scratch-path ~/Library/Caches/SideClick/.build
```

## Signing (one time)

macOS ties the Accessibility permission to the app's signature. To stop the permission from
disappearing after every build, create a local certificate:

1. Open **Keychain Access → Certificate Assistant → Create a Certificate…**
2. Name: `SideClick Dev`, Identity Type: **Self-Signed Root**, Certificate Type: **Code Signing**.
3. Click **Create**. `scripts/build-app.sh` picks it up automatically.

Without the certificate the build is ad-hoc signed. After each build, remove the app from
**System Settings → Privacy & Security → Accessibility** and approve it again. Quit the app
(from its menu) before removing it from the Accessibility list, otherwise its event taps can
briefly stall scrolling and the side buttons.

## Icons

The SVG sources are in `Resources/Icon/`. After editing an SVG, regenerate the PNGs,
`AppIcon.icns` and the menu bar image, then build:

```bash
scripts/render-icons.sh
```

## Design system

The source of truth is [docs/design-system/](docs/design-system/): the brand book
(`README.md`), tokens (`tokens.json`), and per-component guidance and previews (`components/`).

- In Swift code, use semantic SwiftUI styles (`.secondary`, `Color.accentColor`, …), never the
  hex values from `tokens.json`; those exist for documentation and mock-ups.
- When you change the app's look, update `docs/design-system/` first.
- The previews (`components/*/preview.html`) use CSS variables generated from `tokens.json`,
  so they only render correctly when published as an artifact.

## License

[MIT](LICENSE)
