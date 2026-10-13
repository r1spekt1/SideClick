# GestureActionRow

One Form row on the Buttons pane that maps a gesture (Single click, Double click, Triple click, Long press) to nothing, a keyboard shortcut or a system action.

- Render four of them, one per gesture, in a section titled with the selected side button ("Back button").
- The consumer supplies `gesture` and `action: Binding<ButtonAction?>`.
- Layout: `LabeledContent` with the gesture title as label; trailing an action-kind pop-up ("None", "Shortcut", "System action"), followed by a ShortcutRecorder or a system-action pop-up ("Back", "Forward", "Mission Control", "App Exposé", "Desktop left", "Desktop right", "Apps (Launchpad)", "Show Desktop").
- Pop-ups use `.fixedSize()` and hidden labels so the row stays one line at `detail-min-width`.

Source: `Sources/XiaomiMouseFix/UI/GestureActionRow.swift`.
