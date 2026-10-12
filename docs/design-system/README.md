XiaomiMouseFix je macOS menu bar aplikacija za Xiaomi Silent Mouse 2. Izgleda kao deo sistema: Apple HIG, SwiftUI sistemski stilovi i SF Symbols, uz jedan akcenat koji prati sistemsku boju korisnika. Sve vrednosti ovde opisuju ono što SwiftUI već crta. U Swift kodu koristi semantičke stilove (`.primary`, `.secondary`, `Color.accentColor`, `.quaternary`), nikad hex vrednosti iz `tokens.json`. Hex vrednosti služe samo za dokumentaciju i web mock-upove.

## Principi

- **Native pre svega.** Novi ekran pravi od sistemskih kontrola: `Form` sa `.formStyle(.grouped)`, `Toggle` sa `.switch` stilom u popover-u, `Slider`, `Picker`, `LabeledContent`. Ne pravi sopstvene kontrole ako sistemska postoji.
- **Jedan akcenat.** `accent` je jedina boja sa značenjem „ovo je aktivno ili izabrano". Ne uvodi drugu brend boju.
- **Status rečju, ne samo bojom.** Svaki status ima i tekst: `status-connected` tačka uvek stoji uz „Povezan", `warning` trougao uz rečenicu koja objašnjava problem.
- **Bez dekoracije.** Nema gradijenata, senki koje sistem ne crta, kartica sa obojenom ivicom ni emoji-ja.

## Sadržaj i ton

- UI tekst je na srpskom, latinica, ekavica: „Podešavanja", „Prečica", „Dugo držanje", „Obrni smer skrolovanja".
- Kontrola kaže šta radi, kratko i u infinitivu ili imperativu: „Uključi glatko skrolovanje", „Pokreni pri prijavi", „Odobri Accessibility pristup…", „Vrati podrazumevana podešavanja".
- Tri tačke (`…`) samo kad akcija otvara novi prozor ili traži dodatni korak: „Podešavanja…", „Odobri…".
- Pomoćni tekst je jedna rečenica u `caption` stilu, `secondary-label` boji, ispod kontrole: „Ako dugme ima samo „Jedan klik", akcija se okida odmah, bez čekanja."
- Statusi su pridevi u muškom rodu jer se odnose na miš: „Povezan", „Nije povezan", „Odobreno".
- Greška kaže šta se desilo i šta da korisnik uradi. Primer iz aplikacije: „Vorssaint presreće dodatna dugmad miša. Isključi njegove mouse funkcije da bi side dugmad radila ovde."
- Imena sistema i proizvoda ostaju kako ih Apple i proizvođač pišu: Accessibility, Mission Control, App Exposé, Xiaomi Silent Mouse 2.

## Boje

- Tekst: `label` za glavni tekst, `secondary-label` za opise, statuse i jedinice („250 ms"), `tertiary-label` samo za onemogućene kontrole.
- Podloge: prozor podešavanja je `window-background`, redovi grupisane forme su `control-background`. Popover crta sistemski materijal (`popover-background` je samo aproksimacija za mock-up).
- `accent` boji pritisnuto dugme na ilustraciji, prsten oko izabranog dugmeta, prekidače i segmentirane kontrole. Na akcent podlozi tekst je `on-accent`.
- Statusi: `status-connected` i `status-disconnected` za tačku veze, `warning` za trougao konflikta, `destructive` za tekst greške i destruktivno dugme.
- Ilustracija miša: telo `quaternary-fill` sa obrubom `mouse-outline` i linijom `mouse-split`; neaktivno side dugme `side-button-idle`.
- Kontrast: sistemske vrednosti ostaju tačne. `secondary-label` i `accent` kao tekst su oko 4:1 na svetloj podlozi, pa za važnu informaciju koristi `label`. `status-connected` tačka sama ne nosi značenje, uvek ima reč pored sebe.

## Tipografija

- Font je sistemski San Francisco (`sans`), a monospace je SF Mono (`mono`). Font fajlovi se ne isporučuju: SF je deo macOS-a i njegova licenca ne dozvoljava ugrađivanje.
- `body` (13/16) je podrazumevani stil za sve labele u formi. Ne menjaj ga ručno.
- `headline` (13/16 bold) samo za ime uređaja na vrhu popover-a.
- `caption` (10/13) za pomoćne redove, statuse i poruku o konfliktu, uvek u `secondary-label`.
- `title2-bold` (17/22) samo za ime aplikacije na panelu „O aplikaciji".
- `shortcut` (SF Mono 13) za labelu ShortcutRecorder dugmeta. Brojeve uz slidere piši sa `.monospacedDigit()` da se ne pomeraju dok se vrednost menja.

## Raspored i razmaci

- Menu bar popover: širina `popover-width` (300px), unutrašnji razmak `space-14`, vertikalni ritam `space-10`. Redosled: zaglavlje sa statusom, upozorenja, `Divider()`, prekidači, `Divider()`, „Podešavanja…" i „Izađi".
- Prozor podešavanja: `NavigationSplitView` sa sidebar-om širine `sidebar-width` (180px). Panel ima najmanje `detail-min-width` × `detail-min-height` (480 × 440). Redosled stavki: Opšte, Pointer, Scroll, Dugmad, O aplikaciji.
- Svaki panel je jedan `Form` sa `.formStyle(.grouped)`. Sekcije nose kratke naslove („Smer i korak", „Glatko skrolovanje", „Vreme"). Kontrole koje zavise od prekidača se onemogućavaju (`.disabled`), ne sakrivaju.
- Vrednost slidera stoji desno od njega, poravnata desno, širine `value-label-width` (56px; za množilac 44px).
- Razmak između ilustracije miša i birača dugmeta je `space-24`, između dva side dugmeta `space-8`.

## Stanja

- Pritisnuto (fizički pritisak na mišu): side dugme na ilustraciji se puni sa `accent`.
- Izabrano: prsten od 2px u `accent` boji oko side dugmeta.
- Snimanje prečice: dugme recorder-a pokazuje „Pritisni prečicu…" dok čeka taster; Escape otkazuje i zadržava staru prečicu.
- Onemogućeno: sistemski izgled `.disabled`, bez sopstvene boje.
- Fokus: sistemski fokus prsten. Ne crtaj sopstveni.

## Pokret

Nema sopstvenih animacija. Promene stanja su trenutne ili koriste podrazumevane SwiftUI tranzicije. Glatko skrolovanje je funkcija aplikacije za korisnikov miš, nije UI animacija.

## Ikonografija

- Koristi samo SF Symbols, u sistemskoj veličini i boji teksta.
- Simboli u aplikaciji: `computermouse` (menu bar ikonica i sidebar „Dugmad"), `computermouse.fill` (zaglavlje popover-a, „O aplikaciji"), `gearshape` (Opšte), `cursorarrow.motionlines` (Pointer), `scroll` (Scroll), `info.circle` (O aplikaciji), `exclamationmark.triangle.fill` u `warning` boji (konflikt).
- Menu bar ikonica je monohromni template simbol. Sistem joj sam menja boju za svetli i tamni menu bar.
- Emoji se ne koriste.

## Ikonica aplikacije

Aplikacija još nema sopstvenu app ikonicu. Do tada Finder prikazuje generičku ikonicu, a menu bar koristi `computermouse`. Smernice za buduću ikonicu:

- macOS 26 squircle format, sa slojevima za Liquid Glass (Default, Dark, Clear i Tinted varijante).
- Motiv je miš viđen odozgo, bez kabla, sa jednim istaknutim side dugmetom na levoj ivici u akcent plavoj (`accent`). Telo je mat svetlo sivo ili belo, na mirnoj, tamnijoj podlozi.
- Bez teksta, bez Xiaomi logotipa i bez trademark oblika. Ime proizvođača se ne pojavljuje u ikonici.
- Uz app ikonicu ide monohromni menu bar simbol istog obrisa, 16–18pt, kao template slika.
