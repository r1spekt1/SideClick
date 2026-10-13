# ShortcutRecorder

A push button that shows a key combination and records the next one pressed while it is armed.

- Use it in a GestureActionRow whose action kind is "Shortcut".
- The consumer supplies `shortcut: Binding<KeyShortcut>`.
- Label: the shortcut's `displayString` (modifiers in menu order ⌃⌥⇧⌘, then the key) in the `shortcut` style; while armed it reads "Press a shortcut…".
- Clicking again or pressing Escape cancels and keeps the old shortcut; the armed state ends when the row disappears.
- Standard push button look; no custom colors.

Source: `Sources/XiaomiMouseFix/UI/ShortcutRecorder.swift`.
