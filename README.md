# Minimized Dungeon

A Godot 4.7.2 desktop idle RPG prototype targeting macOS and Windows, using the supplied 48x48 side-view knight. Auto-battles, hero and pet upgrades, instant egg hatching, local saves, and offline gold are implemented. Native platform release checks remain pending.

## Open and run

1. In Godot's Project Manager, click **Import**, then select this folder's `project.godot`.
2. Open the project. In the editor's **Game** view, disable **Embed Game on Next Play** so the strip uses a real desktop window.
3. Press **F6** with `scenes/desktop.tscn` open, or **F5** to run the project.

The strip starts above the primary display's taskbar or Dock. Drag its background to reposition it. **Settings** opens a separate window with keyboard focus. Toggle **Combat animation** or transparent background there. **Reset position** returns the strip to the bottom of the primary display.

## Play the prototype

- The knight starts fighting on floor 1. The first victory earns gold, an egg, and access to floor 2.
- Click **Upgrades**. The **Hero** tab spends gold on attack, health, defense, or speed. **Pets** hatches eggs instantly and lets you equip or upgrade a companion. Scroll the pet list if necessary.
- One pet is active at a time; only its attribute bonus applies. Switching pets retains their levels. Duplicate hatches add one level. Each species has matching side-view artwork in the strip, pet list, and hatch result.
- Use **Dungeon** to select unlocked floors. The panel warns when a matchup is expected to lose. Return to an easier floor to earn upgrades; defeat does not remove earned upgrades.
- Floors 1, 5, 10, 15, and 20 award a first-clear egg. Every visible-play victory also has a 10% egg chance. Hatch odds are Common 55%, Uncommon 25%, Rare 13%, Epic 6%, Legendary 1%.
- Hidden, sleeping, and closed time grants up to eight hours of gold at your last saved floor and attributes. It does not grant eggs, change floors, or buy upgrades. Pause disables both active and absent-time rewards.

All prices, drop rates, pet bonuses, and encounter numbers are provisional. Attribute upgrades, pet swaps, and stage changes begin a new encounter after prior elapsed time is credited.

## Pixel interface

The interface uses an original local pixel font, stepped frames, a static stone backdrop, pixel health bars and resource icons, and a shared theme across progression, settings, dropdowns, tooltips, and reset content. Game-owned content is themed; operating-system window chrome and tray menus remain native.

If the editor is already running an older version, stop with **F8**, allow new assets to import, and restart with **F5**. Five original pet sprites and a side-view rat replace the item placeholders. The supplied knight remains unchanged; attack wind-up, slash, impact, and recovery use stepped transforms rather than a new animation sheet. Combat presentation follows encounter time, freezes when paused, and resets immediately when motion is disabled. See `docs/pixel-interface-verification.md` for rebuild commands and verification limits. UI captures are skipped at the user's request.

**Hide** removes the strip. Use the knight icon in the macOS menu bar or Windows notification area to restore it, open settings, or quit. Hide is disabled if no status icon is available. **Quit** fully exits the process. The opaque background is the default for predictable readability and serves as the transparency fallback.

## Command line

On macOS:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path .
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --import
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --quit-after 5 -- --shell-check
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/game_check.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/prototype_check.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/combat_presentation_check.gd
```

On Windows, use the Godot 4.7.2 executable in place of the macOS executable path.

## Settings and recovery

Desktop position and display options are stored in `user://desktop.cfg`. On macOS this is `~/Library/Application Support/Godot/app_userdata/Minimized Dungeon/desktop.cfg`; on Windows it is `%APPDATA%/Godot/app_userdata/Minimized Dungeon/desktop.cfg`.

Position is clamped to an available display after monitor layout changes. Settings load errors preserve the original file and disable further writes for that session. Rename an invalid settings file to keep a backup and restore defaults next time. Save failures are reported in Godot's output.

Game progress lives alongside settings in `progress.json`, with the previous valid save in `progress.json.bak`. It saves every 60 seconds of active play, on purchases, pet/floor/pause changes, hide, restore, and quit. Writes use a validated temporary file and retain a backup before replacement. Failed purchase saves roll back that purchase. Other write errors appear in **Upgrades** so session progress is not mistaken for durable progress.

Corrupt saves recover from a valid backup where possible. Unknown versions are preserved. **Upgrades > Reset local progress...** asks for confirmation, then preserves existing files under timestamped names before starting over. If persistence cannot be initialized, progression stays disabled and the panel explains recovery.

Only one instance may progress at a time. A local loopback listener on port 43871 prevents competing writers. If that port is unavailable, close the other instance and restart; no remote service is required.

## Exports

Godot **Editor > Manage Export Templates** must contain templates matching **4.7.2 stable**. Presets target macOS Universal 2 and Windows x86_64. Create `build/macos` and `build/windows`, then use **Project > Export**. Public macOS distribution additionally requires Developer ID signing and notarization; do not commit signing credentials.

Alternatively, run `python3 scripts/export_release.py` to build both platforms, or add `--platform macos` / `--platform windows`. Use `--godot /path/to/Godot` when the executable is not on PATH or in the standard macOS location. `--check` verifies the pinned engine and required templates without exporting. The helper creates output folders and checks fresh artifacts; distribute the Windows `.exe` together with its `.pck`. Tests, capture fixtures, documentation, and asset preparation scripts are excluded from both export presets.

The resource pack exports and starts headlessly with compiled game scripts. Standalone releases have not been produced because matching templates are missing and network DNS is unavailable in this environment.

## Verification status

See `docs/verification.md` for actual checks and remaining gates. Desktop integration must be tested outside the editor's embedded preview. Exclusive fullscreen overlays are not supported. Transparent windows may behave differently with hybrid Windows GPUs; use opaque mode if needed. This shell is not a release-ready game.
