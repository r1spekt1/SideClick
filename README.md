# XiaomiMouseFix

macOS menu bar aplikacija za Xiaomi Silent Mouse 2: programabilna side dugmad
(single / double / triple click i long press), brzina i akceleracija pointera,
smooth scroll, invert i Shift za horizontalni scroll.

## Zašto

Miš je standardan: side dugmad su mouse dugmad 4 i 5. Neke aplikacije, npr. Vorssaint,
drže event tap koji guta ta dugmad, pa ih ostali softveri ne vide (`docs/spike/`).
Isključi mouse funkcije u takvim aplikacijama. XiaomiMouseFix na to upozorava.

## Build

```bash
scripts/build-app.sh
```

Instalacija u `~/Applications` (stabilna putanja za Accessibility i „Pokreni pri prijavi"):

```bash
pkill -x XiaomiMouseFix; ditto ~/Library/Caches/XiaomiMouseFix/XiaomiMouseFix.app ~/Applications/XiaomiMouseFix.app
```

```bash
open ~/Applications/XiaomiMouseFix.app
```

Build se pravi van repoa (u `~/Library/Caches/XiaomiMouseFix`) jer je `~/Documents`
sinhronizovan preko iCloud-a, a iCloud xattr-ovi lome `codesign`.

Testovi:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --scratch-path ~/Library/Caches/XiaomiMouseFix/.build
```

## Potpisivanje (jednom)

macOS vezuje Accessibility dozvolu za potpis aplikacije. Da dozvola ne bi nestajala posle
svakog build-a, napravi lokalni sertifikat:

1. Otvori **Keychain Access → Certificate Assistant → Create a Certificate…**
2. Name: `XiaomiMouseFix Dev`, Identity Type: **Self-Signed Root**, Certificate Type: **Code Signing**.
3. Klikni **Create**. `scripts/build-app.sh` će ga sam koristiti.

Bez sertifikata build je ad-hoc potpisan. Posle svakog build-a ukloni aplikaciju iz
**System Settings → Privacy & Security → Accessibility** i ponovo je odobri.
Pre uklanjanja iz Accessibility liste ugasi aplikaciju (Quit iz menija), inače njeni
event tap-ovi mogu na trenutak zakočiti scroll i side dugmad.

## Dozvole

Potrebna je samo **Accessibility**. Aplikacija je traži pri prvom pokretanju.
