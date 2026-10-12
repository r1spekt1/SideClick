# MouseIllustration

A top-down drawing of the mouse with its two side buttons on the left edge; clicking a button selects it, a physical press lights it up.

- Use it only at the top of the Buttons pane, next to the segmented button picker.
- The consumer supplies `selected: Binding<SideButton>` and `pressed: Set<SideButton>` (from `AppModel.pressedButtons`).
- Body: 110 × 170 capsule (`radius-pill`) filled `quaternary-fill`, outlined 1px `mouse-outline`, with a 1px × 60px `mouse-split` line from the top.
- Side buttons: `side-button-width` × `side-button-height`, `radius-side-button`, `space-8` apart, front button above the rear one. Idle `side-button-idle`; pressed fills `accent`; selected adds a 2px `accent` ring.
- Each button keeps its accessibility label ("Prednje dugme", "Zadnje dugme") and a tooltip with the same text.

Source: `Sources/XiaomiMouseFix/UI/MouseIllustration.swift`.
