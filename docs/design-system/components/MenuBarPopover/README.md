# MenuBarPopover

The window that opens from the menu bar icon: mouse status, warnings, the three quick switches and the way into Settings.

- One per app, in a `MenuBarExtra` with `.menuBarExtraStyle(.window)`; the system paints its material.
- The consumer supplies the `AppModel` (connection, Accessibility, conflicts, settings).
- Layout: width `popover-width`, padding `space-14`, vertical rhythm `space-10`. Header: `computermouse.fill`, the connected mouse's name in `headline` (e.g. "Mi Wireless Mouse"; "+N" is appended when more than one mouse is connected, "No mouse" when none), StatusIndicator trailing. Then the Accessibility button (only while not granted) and ConflictWarning (only with conflicts), a divider, switches "Enabled", "Smooth scrolling", "Reverse scrolling" (`.switch` style), a divider, "Settings…" and "Quit".
- Keep it to these items; anything more belongs in the Settings window.

Source: `Sources/SideClick/UI/MenuBarView.swift`.
