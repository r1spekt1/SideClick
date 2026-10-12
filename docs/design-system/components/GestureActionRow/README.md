# GestureActionRow

One Form row on the Buttons pane that maps a gesture (Jedan klik, Dupli klik, Trostruki klik, Dugo držanje) to nothing, a keyboard shortcut or a system action.

- Render four of them, one per gesture, in a section titled with the selected side button ("Zadnje dugme").
- The consumer supplies `gesture` and `action: Binding<ButtonAction?>`.
- Layout: `LabeledContent` with the gesture title as label; trailing an action-kind pop-up ("Ništa", "Prečica", "Sistemska akcija"), followed by a ShortcutRecorder or a system-action pop-up ("Nazad", "Napred", "Mission Control", "App Exposé", "Desktop levo", "Desktop desno", "Apps (Launchpad)", "Prikaži desktop").
- Pop-ups use `.fixedSize()` and hidden labels so the row stays one line at `detail-min-width`.

Source: `Sources/XiaomiMouseFix/UI/GestureActionRow.swift`.
