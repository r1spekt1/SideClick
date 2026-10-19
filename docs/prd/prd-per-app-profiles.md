# PRD: Per-App Button Profiles

## 1. Introduction / Overview

SideClick lets users map the two mouse side buttons (Back and Forward) to actions. Each
button supports four gestures: single click, double click, triple click and long press. Today
these mappings are **global**, so the same gesture does the same thing in every app.

Different apps need different actions. In a browser, Back and Forward should go back and forward,
but in Figma users would rather have Undo and Redo. In an editor such as VS Code they may want
"Go Back" and "Go Forward" in the navigation history. Games and some other apps handle the side
buttons themselves and work best when SideClick leaves the buttons alone. Today the only way to
get this is to open Settings and change the mappings by hand every time the user switches apps.

**Per-app profiles** let users define button mappings for specific apps. When one of those apps is
the active (frontmost) app, its profile applies automatically. Everywhere else, the global
mappings apply as before.

**Goal:** the side buttons do the right thing in every app, without any manual switching.

## 2. Goals

1. A user can create a profile for any installed app and change only the gestures that should
   behave differently there.
2. The correct mappings apply as soon as the user switches apps, with no restart and no manual
   action.
3. The user never has to copy global mappings into a profile: a gesture the profile doesn't
   change keeps working as it does globally.
4. A user can tell SideClick to leave the side buttons completely alone in a chosen app.
5. Existing users keep all their current settings after updating, and SideClick behaves exactly
   as before until they create their first profile.

## 3. User Stories

- **US-1:** As a designer, I want the Back and Forward buttons to undo and redo in Figma while
  still going back and forward in Safari, so that I don't have to reach for the keyboard while
  drawing.
- **US-2:** As a developer, I want to remap only the single click of the Back button in VS Code,
  so that my double click and long press keep the global actions I already set up.
- **US-3:** As a gamer, I want SideClick to leave the side buttons alone in my game, so that the
  game's own key bindings for mouse buttons 4 and 5 work.
- **US-4:** As a user, I want to disable one specific gesture in one app without affecting other
  apps, so that an accidental long press does nothing there.
- **US-5:** As a user, I want to see at a glance which apps have a profile, and remove one I no
  longer need.
- **US-6:** As a user who uninstalled an app, I don't want to lose its profile, so that it works
  again if I reinstall the app.

## 4. Functional Requirements

### Managing profiles

1. The Buttons pane in Settings must let the user choose what they are editing: **All apps**
   (the global mappings) or one of the app profiles. **All apps** must be selected by default when
   the pane opens.
2. The user must be able to add a profile with an **Add app** control. It must offer:
   - a list of the apps that are currently running, and
   - a way to pick any `.app` from disk (for example from `/Applications`).
3. Each profile must show the app's name and icon.
4. An app can have at most one profile. If the user adds an app that already has a profile, the
   existing profile must be selected instead of creating a second one.
5. The user must be able to delete a profile. After deletion, that app uses the global mappings.
6. A newly created profile must start with every gesture set to **Same as All apps**. It is not a
   copy of the current global mappings.
7. Profiles must be listed alphabetically by app name, below **All apps**.

### Editing a profile

8. While a profile is selected, the Buttons pane must show the same Back/Forward button picker
   and the same four gesture rows as for **All apps**.
9. In a profile, each gesture row must offer these choices:
   - **Same as All apps** (default): the gesture uses whatever is set globally, including later
     changes to the global mapping.
   - **None**: the gesture does nothing in this app, even if it has a global action.
   - **Shortcut**: a keyboard shortcut, recorded the same way as in the global mappings.
   - **System action**: one of the same system actions available globally.
10. While a gesture is set to **Same as All apps**, its row must show the global action it currently
    resolves to (for example "Same as All apps (Back)"). The user should not have to switch back to
    **All apps** to check it.
11. The **All apps** view must not offer **Same as All apps**. Its options stay as they are today.
12. The **Timing** settings (multi-click window and long-press threshold) are global. While a
    profile is selected they must stay visible and editable, with the note "Timing applies to all
    apps."

### Pass-through

13. Each profile must have a **Pass-through** toggle, off by default, with a short explanation such
    as "SideClick ignores the side buttons in this app, so the app receives them unchanged."
14. While **Pass-through** is on, both side buttons must reach the app exactly as if SideClick were
    not running. No gestures are recognized and no actions run.
15. While **Pass-through** is on, the gesture rows of that profile must be disabled (greyed out). The
    values must be kept, so turning **Pass-through** off restores them.

### Which profile applies

16. The profile that applies is the one for the **frontmost (active) app**, the app that receives
    keyboard input. The app under the pointer does not matter. (Shortcut actions are sent to the
    frontmost app, so this keeps the action and its target in sync.)
17. If the frontmost app has no profile, the global mappings apply.
18. When the user switches to another app, that app's mappings must apply to the next button
    press, with no noticeable delay and no restart of SideClick.
19. A gesture already in progress when the frontmost app changes (for example a button held for a
    long press, or the wait for a possible double click) must finish using the mappings that were
    active when it started. A switch in the middle of a gesture must never fire two actions or a
    "phantom" long press.
20. Each gesture follows the same rule that already applies to the global mappings: if, after
    profile and global mappings are combined, a button has no action for any gesture, the button
    passes through unchanged (as with Pass-through). If at least one gesture has an action,
    gestures without one do nothing.
21. If SideClick is disabled (**Enable SideClick** off), no profile applies and the buttons pass
    through, as today.

### Uninstalled apps

22. If an app with a profile is no longer installed, its profile must stay in the list, marked
    **Not installed** and shown with a generic app icon. It can still be edited and deleted.
23. If the app is installed again, its profile must apply again with no action from the user.

### Existing users

24. After updating, all existing global mappings, timing, scroll and pointer settings must be kept
    unchanged. The user starts with no profiles.
25. Until the user creates a profile, SideClick must behave exactly as the previous version.

## 5. Non-Goals (Out of Scope)

- **Per-app scroll or pointer settings.** Smooth scroll, invert, scroll speed, tracking speed and
  acceleration stay global.
- **Per-app timing.** The multi-click window and long-press threshold stay global.
- **Built-in templates** or suggested mappings for popular apps. Users set up every profile
  themselves.
- **Import / export** of profiles or settings.
- **Profiles in the menu bar.** The menu bar menu does not show the active profile and cannot
  create or switch profiles.
- **Per-mouse profiles** (different mappings for different connected mice).
- **Profiles for websites or windows** inside an app (for example one profile for Figma in the
  browser and another for the Figma desktop app). Matching is by app only.
- **Manual override or pinning** of a profile regardless of the frontmost app.

## 6. Design Considerations

- Follow the existing SideClick design system in `docs/design-system/` and the current layout of
  the Buttons pane. The profile selector sits at the top of the pane, above the mouse illustration.
- The selector should work well with 0 to about 20 profiles. A popup menu or a compact list with
  app icons is enough. No search is needed for v1.
- **Same as All apps** must look clearly different from an explicit choice, for example by showing
  the inherited action in secondary (grey) text. Users must be able to tell which gestures a
  profile actually changes.
- Deleting a profile should ask for confirmation, because the mappings are lost.
- The mouse illustration's live press indicator must keep working while a profile is selected.

## 7. Constraints & Dependencies

- Platform: macOS 14+ on Apple Silicon, the same as the rest of SideClick.
- No new system permission may be required. The feature must work with the Accessibility
  permission SideClick already has.
- Switching profiles must not add any delay a user can feel to button presses, in apps with or
  without a profile.
- Apps are identified in a way that survives renaming or moving the `.app` and updating the app to
  a new version.

## 8. Success Metrics

- **Correctness:** in manual testing across at least 3 apps with profiles plus 2 without, every
  gesture fires the action expected for the frontmost app, including right after switching apps.
- **No regressions:** with no profiles defined, all existing button, scroll and pointer behaviour is
  unchanged, and all existing automated tests pass.
- **Stability:** switching apps during a held long press or during a pending double click never
  produces a duplicate or wrong action in testing (FR-19).
- **Ease of setup:** a new user can create a profile that changes one gesture for one app in under
  a minute without reading documentation.
- **Upgrade safety:** updating from 0.3.x keeps 100 % of existing settings (FR-24).

## 9. Open Questions

1. Should the profile selector show a small badge on profiles that use **Pass-through**, so they are
   easy to spot in the list?
2. Should SideClick handle apps that run as separate helper processes (for example some Electron
   apps or games launched through a launcher), where the frontmost app may not be the app the user
   thinks of? For v1 the profile follows whatever macOS reports as the frontmost app.
3. Without a menu bar indicator, how does a user check which profile is active when a button does
   something unexpected? Is the Settings window enough for v1?
4. Should the README get a short "Per-app profiles" section in the same release, with an example
   such as Figma Undo/Redo?
