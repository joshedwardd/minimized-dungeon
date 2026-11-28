extends RefCounted

const THEME = preload("res://ui/pixel_theme.tres")
const INK = Color("111a22")
const STONE = Color("25343e")
const PAPER = Color("f0e6ce")
const GOLD = Color("e8c477")
const RARITIES = [Color("c7d1d6"), Color("99cf94"), Color("8bbfe9"), Color("d4a0e8"), GOLD]
const COIN = preload("res://assets/gemini/icon-coin.png")
const EGG = preload("res://assets/gemini/icon-egg.png")
const ATTRIBUTE_ICONS = {
	"attack": preload("res://assets/gemini/icon-attack.png"),
	"health": preload("res://assets/gemini/icon-health.png"),
	"defense": preload("res://assets/gemini/icon-defense.png"),
	"speed": preload("res://assets/gemini/icon-speed.png"),
}
const DUNGEON_ICON = preload("res://assets/gemini/icon-dungeon.png")
const SETTINGS_ICON = preload("res://assets/gemini/icon-settings.png")
const DUNGEON_BACKDROP = preload("res://assets/gemini/battle-strip-backdrop.png")
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
