# Minimized Dungeon hero art prompts

Generate one idle sprite per hero. Start with the Iron Warden to establish the scale, lighting, and pixel density. Then use your own Warden sprite as the consistency reference for the other two.

Use this shared direction for each prompt:

> Original side-view pixel art for Minimized Dungeon. Single full-body idle sprite facing right, transparent background, 48×48 pixel canvas. Fit the figure inside about 36×40 pixels, with boots on row 44 and room for the weapon. Light from the upper left. Use crisp pixel clusters and a few blocked shades, with cool shadows and a restrained warm highlight. Keep the silhouette distinct at native size. No text, border, scenery, ground shadow, antialiasing, or extra poses.

## Iron Warden

> A compact, broad dungeon knight with slate plate armor, a squared brass visor, and a rectangular shield held close to the body. A short steel sword angles forward so the shield and blade read separately. Use charcoal shadows, blue gray steel, and a few muted brass pixels on the visor and shield rim. Heavy stance and clearly separated boots.

Save as `assets/heroes/iron_warden.png`.

## Moss Runner

> A narrow tunnel scout with a short moss green hood, a rearward cloak, and a small crescent blade held low in front. Show part of the face under the hood. Use deep pine shadows, sage green cloth, and a muted copper clasp. Lean slightly forward and keep the hood, cloak, and blade legible as three distinct shapes.

Save as `assets/heroes/moss_runner.png`.

## Cinder Keeper

> A lantern keeper in a short ash gray hooded coat, with a tall iron lantern held away from the body. The lantern is the brightest shape, with an ember orange core and a few pale gold pixels. Give the keeper a split coat hem, dark boots, and a rust red shoulder wrap. Keep the light inside the lantern and on the nearest hand.

Save as `assets/heroes/cinder_keeper.png`.

Create the `assets/heroes` directory if it does not exist. Check the PNGs are exactly 48×48 with an alpha channel. Import them in Godot and select each hero in **Menu > Settings > Choose hero**. The picker and desktop strip use the same file.
