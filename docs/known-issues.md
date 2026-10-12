# Poznati sitni problemi (backlog)

Odloženi nalazi iz code review-a (2026-10-12). Nijedan ne blokira upotrebu.

- **Task 1:** tolerant decoder untested in T1 (covered by T2 missingSectionsFallBackToDefaults)
- **Task 1:** nested settings structs use synthesized Decodable — adding a field later breaks old files (store backs up + defaults)
- **Task 1:** decoded values not range-validated (hand-edited JSON)
- **Task 2:** load() treats any read error as "missing" → defaults, next save overwrites the real file (non-ENOENT errors should back up/log)
- **Task 2:** backUpUnreadableFile swallows errors and deletes old .bak before move
- **Task 2:** schemaVersion stamped to current regardless of file value; test temp dirs not cleaned
- **Task 3:** duplicate buttonDown while already down (lost up) resets downAt → possible second long press; mapping/timing mutation contract (reset) only implied; coverage gaps (up-after-threshold w/o tick, click after long press, nextDeadline min across buttons)
- **Task 4-6:** Int32()/Int64()/Int() conversions trap on NaN/huge values (wholeLines, animator step, PointerProperties.fixed) — sanitize at call sites
- **Task 5:** negative dt moves wrong way (guard max(dt,0)); no fractional-carry / same-direction accumulation tests
- **Task 6:** no test for disabled-accel + speed resolution combo
- **Task 7:** build-app.sh `security find-identity | grep -q` under pipefail may SIGPIPE; untrusted identity would make codesign fail instead of falling back
- **Task 7:** accessibility revocation never detected (flag goes stale); requestAccessibility double-prompts
- **Task 7:** app bundle under ~/Library/Caches may be purged — matters for launch-at-login (SMAppService registers the bundle path); consider install-copy to ~/Applications at manual session
- **Task 8:** stale held-button state if tap disabled/stopped mid-hold → phantom long press, pressedButtons stuck; Mission Control/openApplication errors swallowed; gesture timing uses callback time not event timestamp; Handler "same event" contract undocumented
- **Task 8:** button tap matches buttons 3/4 from any mouse (spec "samo Xiaomi") — accepted: only this mouse has side buttons on the user's machine; trackpad has none; parked for final review
- **Task 9:** Shift stripped even when no axis swap happened; shiftScrollsHorizontally=false inconsistent between smooth/non-smooth; glide can interleave with trackpad gesture (stopGliding on continuous event); turning smooth off mid-glide doesn't cancel; modifier+Shift strips Shift; "pass-through modifier" naming
- **Task 10:** no acceleration fallback if HIDMouseAcceleration unset at capture; stale snapshot if user changes System Settings while customized; DeviceMonitor has no deinit/unschedule (lifetime = app)
- **Task 11:** conflict filter ignores tap ordering (a later tap can't swallow ours); conflictTimer never invalidated; LaunchAtLogin errors must be surfaced in UI (T12 does)
- **Task 12:** launchAtLogin @State read once (stale if changed in System Settings / requiresApproval); %.2g formatting cosmetic
- **Task 13:** armed recorder swallows all keyDowns and survives selection change (cancel on selection change / window resign key); private-use labels for F13+ keys; switching kind loses previous value; selection not exposed to VoiceOver
- **Final review:** update() with unchanged settings (connect retries/wake) resets held state so a held swallowed press's up passes as orphan — Ruling: accepted for v1, rare (first press waking the mouse held >0.5 s); fix later by no-op update when mappings/timing unchanged — cost if wrong: occasional stray button-3/4 up.
- **Final review:** pointer originals narrowed to [String: Int]; stale snapshot after quit-while-disconnected — Ruling: accepted, observed values are integers — cost if wrong: restore of an old tracking value.
- **Final review:** Timer.scheduledTimer timers pause during menu tracking; `security` non-zero exit aborts build under set -e — Ruling: accepted for v1.
