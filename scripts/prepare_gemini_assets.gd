extends SceneTree
## Rebuilds the game textures from the original Gemini JPEGs.

const SOURCE := "res://assets/gemini/source/"
const OUTPUT := "res://assets/gemini/"
const HEROES := "res://assets/heroes/"
const ITEM_ATLASES := ["items-equipment-atlas", "items-consumables-atlas", "items-crafting-materials-atlas"]
const ITEM_SIZE := 24
# Crop coordinates use a 760-pixel-wide preview of each source sheet.
const HERO_CROPS := {
	"hero-iron-warden-original": ["iron_warden", Rect2i(114, 40, 579, 694)],
	"hero-moss-runner": ["moss_runner", Rect2i(76, 54, 578, 681)],
	"hero-cinder-keeper": ["cinder_keeper", Rect2i(130, 38, 570, 698)],
}
const ICON_CROPS := {
	"coin": Rect2i(34, 34, 120, 120),
	"egg": Rect2i(234, 34, 100, 122),
	"health": Rect2i(410, 38, 131, 120),
	"attack": Rect2i(600, 28, 131, 136),
	"defense": Rect2i(29, 211, 132, 145),
	"speed": Rect2i(226, 224, 115, 119),
	"dungeon": Rect2i(406, 206, 135, 149),
	"settings": Rect2i(594, 211, 144, 143),
}
const FRAME_CROPS := {
	"panel-frame": [Rect2i(26, 22, 222, 212), Vector2i(46, 44)],
	"tab-frame": [Rect2i(296, 94, 199, 81), Vector2i(56, 23)],
	"selected-tab-frame": [Rect2i(536, 93, 194, 82), Vector2i(56, 23)],
	"health-bar-frame": [Rect2i(21, 338, 351, 75), Vector2i(80, 12)],
	"tooltip-frame": [Rect2i(558, 342, 170, 75), Vector2i(48, 21)],
}


func _initialize() -> void:
	for source_name: String in HERO_CROPS:
		var entry: Array = HERO_CROPS[source_name]
		var subject := cut(read_source(source_name), entry[1], Vector2i(36, 40))
		var sprite := Image.create_empty(48, 48, false, Image.FORMAT_RGBA8)
		var baseline := Vector2i((48 - subject.get_width()) / 2, 45 - subject.get_height())
		sprite.blit_rect(subject, Rect2i(Vector2i.ZERO, subject.get_size()), baseline)
		save(sprite, HEROES + entry[0] + ".png")

	var icons := read_source("toolbar-icons-atlas")
	for name: String in ICON_CROPS:
		var glyph := cut(icons, ICON_CROPS[name], Vector2i(15, 15))
		var icon := Image.create_empty(16, 16, false, Image.FORMAT_RGBA8)
		icon.blit_rect(glyph, Rect2i(Vector2i.ZERO, glyph.get_size()), (Vector2i(16, 16) - glyph.get_size()) / 2)
		save(icon, OUTPUT + "icon-" + name + ".png")

	var frames := read_source("ui-frames-and-controls-atlas")
	for name: String in FRAME_CROPS:
		var entry: Array = FRAME_CROPS[name]
		# Sample at twice the target size first so the frame can be fitted edge to edge.
		var frame := cut(frames, entry[0], entry[1] * 2)
		frame.resize(entry[1].x, entry[1].y, Image.INTERPOLATE_NEAREST)
		save(frame, OUTPUT + name + ".png")

	var effect := cut(read_source("combat-effects-atlas"), Rect2i(47, 41, 296, 277), Vector2i(22, 22))
	var slash := Image.create_empty(24, 24, false, Image.FORMAT_RGBA8)
	slash.blit_rect(effect, Rect2i(Vector2i.ZERO, effect.get_size()), (Vector2i(24, 24) - effect.get_size()) / 2)
	save(slash, OUTPUT + "combat-slash.png")

	var backdrop := read_source("battle-strip-backdrop")
	backdrop.resize(728, 112, Image.INTERPOLATE_NEAREST)
	save(backdrop, OUTPUT + "battle-strip-backdrop.png")
	for name: String in ITEM_ATLASES:
		prepare_item_atlas(name)
	quit()


func prepare_item_atlas(name: String) -> void:
	var source := read_source(name)
	var grid := Vector2i(3, 2)
	var atlas := Image.create_empty(grid.x * ITEM_SIZE, grid.y * ITEM_SIZE, false, Image.FORMAT_RGBA8)
	var preview_cell := Vector2i(253, 254)
	for row in grid.y:
		for column in grid.x:
			var cell := Vector2i(column, row)
			var item := cut(source, Rect2i(cell * preview_cell, preview_cell), Vector2i(44, 44), true)
			var fit := 22.0 / maxi(item.get_width(), item.get_height())
			var size := Vector2i((Vector2(item.get_size()) * fit).round())
			item.resize(size.x, size.y, Image.INTERPOLATE_NEAREST)
			var offset := cell * ITEM_SIZE + (Vector2i(ITEM_SIZE, ITEM_SIZE) - size) / 2
			atlas.blit_rect(item, Rect2i(Vector2i.ZERO, size), offset)
	save(atlas, OUTPUT + name + ".png")


func read_source(name: String) -> Image:
	var source := Image.load_from_file(SOURCE + name + ".jpg")
	assert(source != null and not source.is_empty(), "Missing source image: " + name)
	return source


func cut(source: Image, preview: Rect2i, maximum: Vector2i, magenta_background := false) -> Image:
	var source_scale := float(source.get_width()) / 760.0
	var crop := source.get_region(Rect2i(Vector2i(Vector2(preview.position) * source_scale),
		Vector2i(Vector2(preview.size) * source_scale)))
	var fit := minf(float(maximum.x) / crop.get_width(), float(maximum.y) / crop.get_height())
	var size := Vector2i((Vector2(crop.get_size()) * fit).round())
	crop.resize(size.x, size.y, Image.INTERPOLATE_NEAREST)
	crop.convert(Image.FORMAT_RGBA8)
	# The source sheets have either a magenta key or a gray checkerboard baked in.
	for y in size.y:
		for x in size.x:
			var pixel := crop.get_pixel(x, y)
			var darkest := minf(pixel.r, minf(pixel.g, pixel.b))
			var lightest := maxf(pixel.r, maxf(pixel.g, pixel.b))
			var magenta := minf(pixel.r, pixel.b)
			var is_key := magenta > 0.59 and pixel.g < magenta * 0.5 and absf(pixel.r - pixel.b) < 0.18
			# Remove darker magenta left by JPEG compression along the sprite edges.
			is_key = is_key or (magenta > 0.34 and pixel.g < magenta * 0.46 and absf(pixel.r - pixel.b) < 0.12)
			var is_checkerboard := darkest > 0.57 and lightest - darkest < 0.065
			var is_background := is_key if magenta_background else is_checkerboard
			if is_background:
				crop.set_pixel(x, y, Color.TRANSPARENT)
	var bounds := crop.get_used_rect()
	assert(bounds.has_area(), "No foreground pixels in crop %s" % preview)
	return crop.get_region(bounds)


func save(image: Image, path: String) -> void:
	var result := image.save_png(path)
	assert(result == OK, "Could not save %s: %s" % [path, error_string(result)])
