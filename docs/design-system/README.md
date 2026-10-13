XiaomiMouseFix is a macOS menu bar app for any external mouse. It looks like part of the system: Apple HIG, SwiftUI system styles and SF Symbols, with a single accent that follows the user's system color. Every value here describes what SwiftUI already draws. In Swift code use semantic styles (`.primary`, `.secondary`, `Color.accentColor`, `.quaternary`), never the hex values from `tokens.json`. The hex values are for documentation and web mock-ups only.

## Principles

- **Native first.** Build a new screen from system controls: `Form` with `.formStyle(.grouped)`, `Toggle` with the `.switch` style in the popover, `Slider`, `Picker`, `LabeledContent`. Do not build your own controls when a system one exists.
- **One accent.** `accent` is the only color that means "this is active or selected". Do not introduce a second brand color.
- **Status in words, not only color.** Every status also has text: the `status-connected` dot always sits next to "Connected", the `warning` triangle next to a sentence that explains the problem.
- **No decoration.** No gradients, no shadows the system does not draw, no cards with a colored edge, no emoji.

## Content and tone

- UI text is in English: "Settings", "Shortcut", "Long press", "Reverse scroll direction".
- A control says what it does, briefly, in the imperative: "Enable smooth scrolling", "Launch at login", "Grant Accessibility access…", "Restore default settings".
- Use an ellipsis (`…`) only when the action opens a new window or asks for an additional step: "Settings…", "Grant…".
- Helper text is one sentence in the `caption` style, `secondary-label` color, below the control: "If a button only has "Single click", the action fires immediately, without waiting."
- Statuses are short adjectives or participles: "Connected", "Not connected", "Granted".
- An error says what happened and what the user should do. Example from the app: "Vorssaint is intercepting the extra mouse buttons. Turn off its mouse features so the side buttons work here."
- System and product names stay as Apple and the vendors spell them: Accessibility, Mission Control, App Exposé.

## Color

- Text: `label` for main text, `secondary-label` for descriptions, statuses and units ("250 ms"), `tertiary-label` only for disabled controls.
- Backgrounds: the settings window is `window-background`, the rows of a grouped form are `control-background`. The popover draws the system material (`popover-background` is only an approximation for mock-ups).
- `accent` colors the pressed button on the illustration, the ring around the selected button, switches and segmented controls. Text on an accent background is `on-accent`.
- Statuses: `status-connected` and `status-disconnected` for the connection dot, `warning` for the conflict triangle, `destructive` for error text and the destructive button.
- Mouse illustration: body `quaternary-fill` with a `mouse-outline` border and a `mouse-split` line; idle side button `side-button-idle`.
- Contrast: the system values stay accurate. `secondary-label` and `accent` as text are about 4:1 on a light background, so use `label` for important information. The `status-connected` dot alone carries no meaning, it always has a word next to it.

## Typography

- The font is the system San Francisco (`sans`), and the monospace is SF Mono (`mono`). Font files are not shipped: SF is part of macOS and its license does not allow embedding.
- `body` (13/16) is the default style for all labels in a form. Do not change it manually.
- `headline` (13/16 bold) only for the device name at the top of the popover.
- `caption` (10/13) for helper lines, statuses and the conflict message, always in `secondary-label`.
- `title2-bold` (17/22) only for the app name on the "About" pane.
- `shortcut` (SF Mono 13) for the label of the ShortcutRecorder button. Write the numbers next to sliders with `.monospacedDigit()` so they do not shift while the value changes.

## Layout and spacing

- Menu bar popover: width `popover-width` (300px), inner padding `space-14`, vertical rhythm `space-10`. Order: header with status, warnings, `Divider()`, switches, `Divider()`, "Settings…" and "Quit".
- Settings window: `NavigationSplitView` with a sidebar of width `sidebar-width` (180px). A pane has a minimum of `detail-min-width` × `detail-min-height` (480 × 440). Order of items: General, Pointer, Scroll, Buttons, About.
- Each pane is a single `Form` with `.formStyle(.grouped)`. Sections carry short titles ("Direction and step", "Smooth scrolling", "Timing"). Controls that depend on a switch are disabled (`.disabled`), not hidden.
- A slider's value sits to its right, right-aligned, with width `value-label-width` (56px; 44px for a multiplier).
- The gap between the mouse illustration and the button picker is `space-24`, between the two side buttons `space-8`.

## States

- Pressed (physical press on the mouse): the side button on the illustration fills with `accent`.
- Selected: a 2px ring in `accent` around the side button.
- Recording a shortcut: the recorder button shows "Press a shortcut…" while it waits for a key; Escape cancels and keeps the old shortcut.
- Disabled: the system `.disabled` look, no custom color.
- Focus: the system focus ring. Do not draw your own.

## Motion

No custom animations. State changes are instant or use the default SwiftUI transitions. Smooth scrolling is an app feature for the user's mouse, not a UI animation.

## Iconography

- In the UI use only SF Symbols, at the system size and in the text color.
- Symbols in the app: `computermouse` (sidebar "Buttons"), `computermouse.fill` (popover header), `gearshape` (General), `cursorarrow.motionlines` (Pointer), `scroll` (Scroll), `info.circle` (About), `exclamationmark.triangle.fill` in the `warning` color (conflict).
- The only exception is the menu bar icon: a custom monochrome template symbol (`Resources/MenuBarIcon.png` and `@2x`), a drawing of a mouse with two side buttons. The system recolors it for light and dark menu bars.
- No emoji.

## App icon

- The sources are SVG files in `Resources/Icon/`: `AppIcon.svg` (detailed), `AppIcon-Small.svg` (16 and 32 px), the `-Dark`, `-Clear` and `-Tinted` variants, and the `-Background` and `-Foreground` layers for Icon Composer. The menu bar symbol is `MenuBarIcon.svg` on an 18 pt grid.
- `scripts/render-icons.sh` produces the PNGs (`Resources/Icon/png/`), `Resources/AppIcon.icns` and the menu bar images from them. After changing an SVG, run it again; the PNGs and the `icns` are never edited by hand.
- Motif: a mouse seen from above, a matte light gray body on a graphite squircle background, and the rear side button glows in `accent` blue, as if pressed. It is the only color on the icon.
- Small sizes (16 and 32 px) use a simplified drawing: a larger mouse and bigger buttons, no wheel.
- No text, no manufacturer logo and no trademarked shapes.
- The "About" pane shows the app icon at 96 px.
