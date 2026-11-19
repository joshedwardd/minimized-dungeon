# Pixel interface verification

## Current direction, 2026-11-18

The user requested remaining implementation without UI capture. No further captures are attempted or required to continue this prototype. Historical capture instructions below are optional tooling, not the next user action. Visual quality and the native display-scale matrix remain unverified; open native acceptance tasks are not counted as missing theme implementation.

Original 32x32 side-view pet and rat assets now replace the active placeholders. The knight remains the supplied image; its transparent bottom padding is compensated so its visible feet align with the shared ground. Encounter-driven wind-up, slash, hit reaction, and recovery are bounded stepped poses. **Combat animation** disables movement and effects immediately, while pause and recovery reset active effects. No gameplay rules or save schema changed. `tests/combat_presentation_check.gd` verifies these states, integer art dimensions, binary alpha, grounded knight positioning, and presentation leaving game data unchanged.

## Implementation, 2026-11-17

The user approved an original local bitmap font in place of the planned Kenney download after network resolution failed. All asset preparation is local and requires no new dependency.

Implemented:

- Original printable-ASCII font plus ellipsis, with integer bitmap scaling and a locally generated glyph atlas.
- Shared Theme and resources for buttons, toggle icons, tabs, dropdown popup, scrollbars, tooltips, dialogs, and window content.
- Cached static stone backdrop, stepped panel frames, gold/egg icons, pixel-aligned health bars, and integer-scaled normalized creature textures in the strip.
- Explicit theme assignment across the root Window, progression Window, settings Window, floor popup, and reset confirmation.
- Scrolling panel content and usable-area fitting, retaining the existing separate window layout.
- Immediate hatch icon/name/rarity/duplicate feedback without a timer or new animation. Other notices clear stale hatch colors/icons. The existing motion setting retains control of actor movement.
- Existing game rules, persistence model, and save format remain in `scripts/game.gd` and `scripts/progress_store.gd` without visual-change edits.

## Evidence

The original font source-grid sample was generated and visually inspected at `.godot/pixel-preview/font-sample.png`. This is a bitmap font sample, not a screenshot of the native application. Godot verifies every printable ASCII glyph is present and that requested 16/24 sizes retain 20/30 line-height metrics.

`scripts/prepare_pixel_assets.gd` verifies all six 32x32 normalized images exactly reconstruct their original 128x128 exports when enlarged with nearest sampling. The normalized rat was also inspected.

Headless `tests/prototype_check.gd` covers the original hatch/equip/upgrade/floor/pause/save flow plus:

- Theme identity across windows, dialog, popup, and root tooltip scope.
- Explicit normal/hover/pressed/disabled/focus resources; tab selection/focus and tooltip/dialog frames.
- Integer font and enemy scaling; constrained work-area fitting; HUD action-row bounds.
- Instant motion-off hatch feedback, duplicate outcome wording, and no second reward when reopening.
- Unaffordable upgrades remaining disabled, save errors clearing stale rarity presentation, and complete recovery/resource text.
- Keyboard acceptance activating an upgrade, and a copied existing-format save being readable.

The unchanged core game/save suite and scene `--shell-check` remain required regression checks. A successful headless run establishes behavior and layout properties, not rendered control appearance.

## Native verification pending

Rechecked 2026-11-18: prototype, game/save, desktop visibility, and scene shell checks pass. Native capture still exits immediately with signal 6 and produces no screenshots. Headless runs also emit a macOS system-certificate lookup error; the local game checks complete successfully. No additional implementation changes or visual acceptance claims were made during this retry.

A native capture attempt used a preview subclass that bypasses progress reads/writes and local instance binding. The installed Godot executable exited with signal 6 before producing application captures. The bounded wrapper returned; it did not leave a new background command running. The launch failure is not a visual pass.

`tests/render_pixel_preview.gd` is available to capture the real Godot viewport on a desktop where native launch works. It renders fixture state through the production interface and writes to `.godot/pixel-preview/`. `tests/preview_desktop.gd` prevents the fixture from reading or changing player saves or creating a status icon. Run it with the normal installed Godot executable and `--script tests/render_pixel_preview.gd`.

Still required: native macOS/Windows captures of all theme states, supported scale factors, light/dark desktop transparency, tooltips, dropdown/reset content, long values, recovery text, and a constrained working area. Native no-focus startup, click-through, drag, restore, and hidden render suspension remain open. The earlier gameplay change retains its separate platform release, energy, and soak-test gates.

## Capture continuation

A second bounded native launch was attempted after the user asked to continue. It again exited with signal 6 before producing captures. The new invocation returned immediately and left no new background command running.

On the user's Mac, double-click `scripts/capture-pixel-interface.command` in Finder, or run it from Terminal. It invokes the installed Godot with the preview fixture, checks that a fresh manifest was produced, and opens the capture folder after success. It does not read or write player progress. The fixture has a 30-second watchdog and a 1,200-frame engine limit.

The expanded fixture captures battling/recovering strips, transparency, all tabs, the floor popup, five rarity outcomes, a new-pet outcome, long pet text, empty/disabled states, maximum resources, offline/save messages, settings, reset confirmation, a constrained panel, and a control-state gallery. The gallery explicitly previews hover/pressed style resources and uses a real focused button. Its tooltip is a style sample; OS hover behavior still needs manual checking. The manifest records the actual OS, engine, display scale, DPI, and filenames. Each invocation covers only its current platform/display scale.

The preview Control is anchored to the viewport to match the real scene, and continuous rendering is enabled only in the capture fixture so static screenshots cannot stall while waiting for a redraw. These fixture changes do not alter the game's production performance settings.

The capture script parses successfully, and the Mac launcher passes shell syntax checking. Native pictures still need to be produced and inspected before the remaining visual tasks are marked complete.

## Main-window visibility fix

The user's native run log confirmed successful OpenGL initialization on Apple M2, with embedding disabled. It also reported `Can't change visibility of main window` from the Hide action. Calling that action in the headless preview reproduced the same engine error before editing.

Hide now minimizes the main window through its mode instead of calling `Window.hide()`. Restore returns to windowed mode without calling `Window.show()`. `tests/desktop_visibility_check.gd` passes checks that presentation processing and rendering stop/resume, with no main-window visibility error. The existing UI regression suite also passes. Actual macOS minimize/restore behavior and the rendered pixel appearance still need the user's native check.

## Rebuild commands

```sh
python3 scripts/build_pixel_font.py
Godot --headless --path . --import
Godot --headless --path . --script scripts/prepare_pixel_assets.gd
Godot --headless --path . --import
Godot --headless --path . --script scripts/build_pixel_theme.gd
Godot --headless --path . --script tests/game_check.gd
Godot --headless --path . --script tests/prototype_check.gd
Godot --headless --path . --quit-after 5 -- --shell-check
```

Replace `Godot` with `/Applications/Godot.app/Contents/MacOS/Godot` on macOS. The Theme and font `.tres` files are generated by the theme builder and should not be hand-edited.
