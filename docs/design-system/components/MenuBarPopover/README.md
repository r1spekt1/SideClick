# MenuBarPopover

The window that opens from the menu bar icon: device status, warnings, the three quick switches and the way into Settings.

- One per app, in a `MenuBarExtra` with `.menuBarExtraStyle(.window)`; the system paints its material.
- The consumer supplies the `AppModel` (connection, Accessibility, conflicts, settings).
- Layout: width `popover-width`, padding `space-14`, vertical rhythm `space-10`. Header: `computermouse.fill`, "Xiaomi Silent Mouse 2" in `headline`, StatusIndicator trailing. Then the Accessibility button (only while not granted) and ConflictWarning (only with conflicts), a divider, switches "Uključeno", "Glatko skrolovanje", "Obrni skrolovanje" (`.switch` style), a divider, "Podešavanja…" and "Izađi".
- Keep it to these items; anything more belongs in the Settings window.

Source: `Sources/XiaomiMouseFix/UI/MenuBarView.swift`.
