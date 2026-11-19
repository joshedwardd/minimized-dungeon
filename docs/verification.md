# Desktop shell verification

## 2026-11-18 continuation

UI captures are skipped at the user's request. The remaining code/content pass adds five original side-view companion sprites, a rat sprite, grounded knight placement, encounter-driven stepped attack/impact/recovery poses, and an immediate motion-off reset. Core game/save, UI integration, desktop visibility, and combat-presentation headless checks pass. This is not native desktop or visual-quality evidence.

`python3 scripts/export_release.py --check` confirms the pinned engine but reports missing `macos.zip` and `windows_release_x86_64.exe` under the matching template directory. Attempting the official template download failed at DNS resolution. The helper is ready to export both presets after templates are installed. Export presets omit tests, capture fixtures, development asset builders, documentation, and historical placeholder art.

The Windows preset successfully exported a compiled resource pack using `--export-pack`; starting that pack with `--headless --main-pack .godot/release-check.pck -- --shell-check` passed. This establishes packaged game-resource availability and startup, not a Windows executable or standalone macOS app. Native packages, signing, cross-platform smoke tests, single-instance binding, real sleep/wake, hardware measurements, and soak testing remain pending.

Five stdlib tests in `tests/test_release_export.py` pass for release-helper prerequisite failure, version mismatch, check-only behavior, both output paths including the Windows pack, and rejection of stale artifacts after a nominally successful export. These use an isolated executable fixture and do not replace real template-backed exports. Run with `python3 -m unittest discover -s tests -p 'test_release_export.py'`. Both OpenSpec changes pass strict validation after recording the user's no-capture direction.

## 2026-11-17

Environment: macOS arm64, Godot `4.7.2.stable.official.ed1daf0bf` from `/Applications/Godot.app/Contents/MacOS/Godot`.

Completed:

- Imported both unchanged 48x48 knight PNGs and the desktop scene with the Compatibility project settings.
- Parsed and ran the desktop script headlessly. `--shell-check` passed assertions for the sprite dimensions, 30 FPS cap, configured no-focus/always-on-top flags, and settings window size. Headless checks validate configuration, not operating-system window behavior.
- Native launch was attempted with a bounded frame count, but macOS desktop-service connections failed before the renderer started. Interrupts were requested, but process termination could not be confirmed because the sandbox also rejected a termination signal. No visual result is claimed.

Sandbox limitations:

- The normal Godot user-data directory under Library/Application Support is not writable from this tool session. Runs reported directory creation errors. Desktop setting persistence could not be exercised here.
- A local executable copy in ignored `.tools/` uses self-contained editor mode to keep editor caches inside the project. Self-contained mode does not relocate game user data. The local copy was ad-hoc signed for execution; the installed Godot app was not modified.
- macOS system certificate retrieval also reported an error. The shell makes no network requests.
- No matching export templates were found in the installed Godot export templates directory. Release packages have not been produced.

Pending manual checks, outside embedded editor preview:

- Launch while typing in another application; confirm keyboard focus stays there.
- Drag and reset the strip, then disconnect an external monitor and change display scaling.
- Enable transparency; confirm the empty top margin passes clicks to the underlying application.
- Open Settings, navigate its controls with keyboard focus, toggle animation and transparency, and close it.
- Hide, restore through the status menu, and quit. If the status menu is unavailable, verify Hide is disabled.
- Reopen and verify desktop position/options are preserved. Rename `desktop.cfg` if it becomes invalid.
- Repeat integration checks on Windows and Intel macOS.
- Install matching export templates and test native release packages.
- Measure visible/hidden CPU, GPU, energy, and memory using the spec protocol, followed by the eight-hour soak.

## Playable prototype checks

The user authorized gameplay implementation while platform and release checks remain pending. The repository now includes automatic combat, hero/pet upgrades, five fixed pet rarities, milestone/random eggs, instant hatching, derived pet bonuses, local saves with recovery, and offline gold.

Passing checks using the project-local Godot 4.7.2 executable:

- `tests/game_check.gd`: fresh-character victories, defeats without rewards, unaffordable/invalid purchases, one-time deductions, repeated pet swaps without accumulated bonuses, unequipped upgrades, all five hatch rarities and egg consumption, pause behavior, negative time, the eight-hour cap, no duplicate settlement, no offline unlocks/eggs, and equivalent progression at 15/30 FPS.
- Eight-hour arithmetic settlement completed within the 100 ms assertion budget in the headless check. This is a narrow logic measurement, not a laptop energy benchmark.
- Save checks use isolated writable test paths: JSON round trips, equipped pet/levels, interrupted temporary writes, corrupt primary recovery, short-absence settlement followed by restart, unknown-version preservation, explicit reset with archived files, and write failure reporting.
- `tests/prototype_check.gd`: actual UI signals hatch/equip a pet, purchase hero/pet upgrades, select a floor, pause/resume, and persist state. Simulated wall-time absence grants gold once. The Pets tab remains within the intended compact window size.
- `--shell-check`: scene startup/configuration assertions still pass after integration.

The local socket bind was unavailable in this sandbox, so the concurrent-instance OS check reports SKIP. Normal `user://` persistence, native desktop input, rendered presentation, real sleep/wake, platform release packages, and energy measurements still need validation outside this session. Headless UI signal checks do not establish visual quality or OS focus behavior.

Tasks 2.2, 2.4, and 3.2 are complete at their specified logic/check scope. Tasks requiring artwork approval, native interaction, release builds, or hardware measurements remain open.
