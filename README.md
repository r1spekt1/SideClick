# SideClick

A macOS menu bar app for mice with back/forward side buttons: programmable side buttons
(single / double / triple click and long press), tracking speed and acceleration,
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
asks for it on first launch. Two more are needed only for the battery level (see below):
**Bluetooth**, asked for when a Bluetooth Low Energy mouse connects, and **Input Monitoring**,
offered as a button when a WhiteShark Maximus receiver is connected.

> The app is signed with a self-signed certificate and not notarized, so Gatekeeper blocks it
> on first launch. Either:
>
> - open **System Settings → Privacy & Security** and click **Open Anyway** next to the
>   SideClick message (macOS 15+; on macOS 14 right-click the app and choose **Open**), or
> - remove the quarantine flag once:
>
>   ```bash
>   xattr -dr com.apple.quarantine /Applications/SideClick.app
>   ```
>
> Every release is signed with the same certificate, so the permissions you grant are kept
> when you replace the app with a newer version. Versions up to 0.3.0 were ad-hoc signed:
> after updating from one of them, grant the permissions once more.

### Upgrading from XiaomiMouseFix

SideClick is the new name of XiaomiMouseFix (0.1.0). It has a new bundle identifier, so:

1. Quit XiaomiMouseFix from its menu bar menu and delete it. Running both at once makes them fight over the side buttons, scroll and pointer settings. Also remove its entry from **System Settings → General → Login Items** if you had enabled "Launch at login".
2. Open SideClick and grant **Accessibility** again.
3. Turn "Launch at login" on again in SideClick → General if you used it.

Your settings are copied over automatically on first launch.

### Connection and battery level

The menu and Settings → General show how each mouse is connected: **Bluetooth**, **USB**, or
for a WhiteShark Maximus **2.4 GHz** (its receiver) and **Wired** (its cable). For other USB mice
a receiver and a cable look the same to macOS, so they show as USB.

SideClick shows the battery in the menu bar, in the menu and in Settings → General, and warns
once when it drops to 15 %:

- **Bluetooth Low Energy mice** that offer the standard Battery Service. The mouse reports
  changes itself. This needs the **Bluetooth** permission. Classic Bluetooth mice have no such
  service, so their battery isn't shown and the permission isn't asked for. While a Bluetooth
  reading is available it is shown instead of the receiver's, since the receiver only knows the
  level from the mouse's last 2.4 GHz session.
- **WhiteShark Maximus (GM-9010) on its 2.4 GHz receiver.** SideClick sends the receiver the same
  status query as WhiteShark's Windows software, every 2 seconds and when you open the menu, and
  no other command. The receiver answers from its own cache, so this costs the mouse no battery.
  macOS allows the query only with **Input Monitoring**, because the receiver's status report is
  on its keyboard interface. SideClick reads no keyboard input. While the mouse is off or asleep,
  the receiver reports the last level it knew. On its charging cable the mouse shows as charging.

Other mice on a USB receiver show no battery level: each vendor uses its own protocol.

### Known limitations

Virtual HID pointing devices (for example from Karabiner-Elements or remote-desktop tools) can be listed as mice, and a mouse that exposes several mouse interfaces may be listed twice.

**Tracking speed** on the Pointer pane sets the same value as System Settings → Mouse → Tracking speed, but only for external mice. There is no separate speed control: changing the mouse's pointer resolution, which earlier versions did, has no noticeable effect on macOS 27 (tested with a Xiaomi Silent Mouse 2 and a Whiteshark GM-9010).

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

To produce a drag-to-Applications DMG next to the app, signed with the release certificate
(see [Release signing](#release-signing)):

```bash
scripts/make-dmg.sh
```

The build is created outside the repo (in `~/Library/Caches/SideClick`) because
`~/Documents` can be synced by iCloud, and iCloud's extended attributes break `codesign`.

Run the tests:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --scratch-path ~/Library/Caches/SideClick/.build
```

## Signing for development (optional)

Only needed if you build from source. Users who install the DMG do not need a certificate.

macOS ties the Accessibility permission to the app's signature. To stop the permission from
disappearing after every build, create a local certificate:

1. Open **Keychain Access → Certificate Assistant → Create a Certificate…**
2. Name: `SideClick Dev`, Identity Type: **Self-Signed Root**, Certificate Type: **Code Signing**.
3. Click **Create**. `scripts/build-app.sh` picks it up automatically.

If you created the certificate under the old name `XiaomiMouseFix Dev`, either create `SideClick Dev` or build with `SIGN_IDENTITY="XiaomiMouseFix Dev" scripts/build-app.sh`.

Without the certificate the build is ad-hoc signed. After each build, remove the app from
**System Settings → Privacy & Security → Accessibility** and approve it again. Quit the app
(from its menu) before removing it from the Accessibility list, otherwise its event taps can
briefly stall scrolling and the side buttons.

## Release signing

Only needed to publish a release. `scripts/make-dmg.sh` signs with a self-signed certificate
named `SideClick`, pinned by its SHA-1 in `RELEASE_CERT_SHA1`, and stops if it is missing.
macOS ties the permissions users grant to this certificate's hash, so every release must be
signed with the same one: a new certificate, even with the same name, makes every user grant
the permissions again. The pinned hash makes the script refuse such a certificate. It does not
get past Gatekeeper; that needs a paid Apple Developer ID and notarization.

To create it:

1. Open **Keychain Access → Certificate Assistant → Create a Certificate…**
2. Name: `SideClick`, Identity Type: **Self-Signed Root**, Certificate Type: **Code Signing**,
   and check **Let me override defaults**.
3. Set **Validity Period** to `7300` days (20 years; the default is one year), keep the other
   defaults, and click **Create**.
4. Back it up: in Keychain Access → **My Certificates**, right-click `SideClick` →
   **Export…**, save it as `.p12` with a password, and keep the file outside the repo. Without
   this backup a lost Mac means a new certificate.
5. Pin it: run `security find-identity -p codesigning`, copy the 40-character hash in front of
   `"SideClick"` into `RELEASE_CERT_SHA1` in `scripts/make-dmg.sh`, and commit it. The hash is
   not secret: it is in every shipped app's designated requirement (`codesign -d -r- SideClick.app`
   shows it as `certificate leaf = H"…"`).

On another Mac, import the `.p12` backup instead of creating a new certificate. To sign with a
different identity (for a test build), set `SIGN_IDENTITY` to its name or SHA-1.

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
