extends RefCounted

const THEME = preload("res://ui/pixel_theme.tres")
const INK = Color("111a22")
const STONE = Color("25343e")
const PAPER = Color("f0e6ce")
const GOLD = Color("e8c477")
const RARITIES = [Color("c7d1d6"), Color("99cf94"), Color("8bbfe9"), Color("d4a0e8"), GOLD]
const COIN = preload("res://assets/ui/gold.svg")
const EGG = preload("res://assets/ui/egg.svg")
const ATTRIBUTE_ICONS = {
	"attack": preload("res://assets/ui/attack.svg"),
	"health": preload("res://assets/ui/health.svg"),
	"defense": preload("res://assets/ui/defense.svg"),
	"speed": preload("res://assets/ui/speed.svg"),
}
const PET_TEXTURES = {
	"moss": preload("res://assets/creatures/moss.svg"),
	"ember": preload("res://assets/creatures/ember.svg"),
	"swift": preload("res://assets/creatures/swift.svg"),
	"stone": preload("res://assets/creatures/stone.svg"),
	"wisp": preload("res://assets/creatures/wisp.svg"),
}


static func fit_window(window: Window, preferred: Vector2i, area := Rect2i()) -> void:
	if area.size == Vector2i.ZERO:
		area = Rect2i(0, 0, 1280, 720) if DisplayServer.get_name() == "headless" else DisplayServer.screen_get_usable_rect(window.current_screen)
	window.min_size = Vector2i(300, 200)
	window.size = Vector2i(mini(preferred.x, area.size.x - 48), mini(preferred.y, area.size.y - 48))
	window.position = area.position + (area.size - window.size) / 2


static func dungeon_texture() -> Texture2D:
	var image := Image.create(380, 48, false, Image.FORMAT_RGBA8)
	image.fill(Color("111a22"))
	for row in 5:
		for column in 17:
			var x := column * 24 - (12 if row % 2 else 0)
			var rectangle := Rect2i(x + 1, row * 10 + 1, 22, 8).intersection(Rect2i(0, 0, 380, 48))
			if rectangle.has_area():
				image.fill_rect(rectangle, Color("1c2933") if (column + row) % 3 else Color("202e37"))
	return ImageTexture.create_from_image(image)
