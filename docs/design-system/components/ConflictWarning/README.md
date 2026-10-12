# ConflictWarning

A warning row naming other apps that intercept the extra mouse buttons, so the side buttons cannot reach XiaomiMouseFix.

- Show it in the popover and in the General pane only while `AppModel.conflicts` is not empty.
- The consumer supplies `names: [String]`, the localized app names, joined with ", ".
- Glyph: SF Symbol `exclamationmark.triangle.fill` in `warning`. Text: `caption` in `label`, wrapping over several lines (`.fixedSize(horizontal: false, vertical: true)`).
- Copy pattern: "<names> presreće dodatna dugmad miša. Isključi njegove mouse funkcije da bi side dugmad radila ovde."
- Never put the warning color on the text; the sentence carries the meaning.

Source: `Sources/XiaomiMouseFix/UI/ConflictWarning.swift`.
