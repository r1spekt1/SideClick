# StatusIndicator

An 8px dot plus a status word that tells whether a mouse is connected.

- Use it in the menu bar popover header and the "Status" section of the General pane.
- The consumer supplies one Boolean, `isMouseConnected`.
- Dot: `status-dot` size, `radius-pill`, `status-connected` when connected, `status-disconnected` otherwise. Word: `caption` in `secondary-label`, "Connected" / "Not connected".
- Always show the word next to the dot; the dot alone does not carry the meaning.

Source: `Sources/XiaomiMouseFix/UI/MenuBarView.swift`.
