# Asset provenance

`knight/east.png` and `knight/west.png` are unchanged directional poses extracted from the user-provided `A_silver_hair_knight_wit-Idle.zip` on 2026-11-17. Metadata identifies 48x48 sprites with a side view and no animation frames. The original archive is retained. Knight artwork has not been redrawn; combat poses and effects are applied separately at runtime.

The following unchanged PNGs were copied from `../gamify/assets/sprites/` on 2026-11-17:

| Local file | Source file | Prototype use |
| --- | --- | --- |
| `prototype/rat.png` | `rat-cellar.png` | Temporary enemy sprite |
| `prototype/turtle-shell-charm.png` | `turtle-shell-charm.png` | Moss Turtle placeholder icon |
| `prototype/phoenix-feather.png` | `phoenix-feather.png` | Ember Finch placeholder icon |
| `prototype/rabbits-foot.png` | `rabbits-foot.png` | Swift Rabbit placeholder icon |
| `prototype/owl-totem.png` | `owl-totem.png` | Stone Owl placeholder icon |
| `prototype/mind-sigil.png` | `mind-sigil.png` | Astral Wisp placeholder icon |

These source images are 128x128 exports of the existing project's pixel art. They remain provisional and do not establish final pet appearances or a side-view enemy design. Old hero equipment overlays are excluded because they do not align to the new 48x48 knight.

On 2026-11-18, `creatures/moss.svg`, `ember.svg`, `swift.svg`, `stone.svg`, `wisp.svg`, and `rat.svg` replaced the active prototype illustrations with original side-view pixel geometry. Each source uses a 32x32 grid, integer coordinates, a transparent background, and the shared dungeon palette. The Godot import check verifies binary alpha with no smoothed edges. No external artwork or generation service was used. Original copied PNGs remain available as historical source assets. `ui/slash.svg` is an original 24x24 stepped combat effect.

`ui/prototype/*.png` are derived 32x32 copies prepared by `scripts/prepare_pixel_assets.gd` using nearest-neighbor resampling. The preparation check verifies that scaling each result back to 128x128 exactly reconstructs its corresponding original image. Originals remain intact.

`ui/frame.svg`, `ui/focus.svg`, `ui/gold.svg`, `ui/egg.svg`, the directional `ui/arrow*.svg` files, and `ui/check.svg` are original code-native pixel geometry authored for this interface on 2026-11-17. They contain no sourced artwork.

`ui/attack.svg`, `ui/health.svg`, `ui/defense.svg`, and `ui/speed.svg` are original matching pixel attribute icons.

`ui/font/dungeon-pixel.png` and `ui/font/dungeon-pixel.fnt` are generated from original glyph drawings in `scripts/build_pixel_font.py`. The user approved this local font instead of the unavailable Kenney download. No external font was copied or bundled. See `ui/font/README.md` for coverage and rebuild instructions. The earlier stone backdrop used original code-native geometry.

## Gemini artwork

The full-size JPEG originals are retained under `assets/gemini/source/`. The game uses the resized dungeon backdrop, isolated toolbar icons and control frames, the sword slash, and the three 48×48 hero sprites. The preparation script removes the checkerboard from the sprite and UI crops and uses nearest-neighbor sampling. Godot imports the prepared PNGs from `assets/gemini/` and `assets/heroes/`. The equipment, consumables, and crafting material sheets use keyed magenta backgrounds and are prepared as three transparent atlases with six 24×24 cells each for the Items catalog.

To rebuild the textures, run `Godot --headless --path . --script scripts/prepare_gemini_assets.gd`, then run `Godot --headless --path . --import`. Run `Godot --headless --path . --script scripts/build_pixel_theme.gd` after changing the theme builder.
