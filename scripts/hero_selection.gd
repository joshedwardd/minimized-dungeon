extends Window

signal hero_chosen(id: String)

const Game = preload("res://scripts/game.gd")
const Pixel = preload("res://ui/pixel_ui.gd")
const KNIGHT = preload("res://assets/knight/east.png")

var welcome: VBoxContainer
var picker: VBoxContainer
var start: Button
var enter: Button
var back: Button
var preview: TextureRect
var announcement: Label
var selected := Game.DEFAULT_HERO
var fresh := false
var choices: Dictionary = {}


static func art(id: String) -> Texture2D:
	var path := "res://assets/heroes/%s.png" % id
	if ResourceLoader.exists(path, "Texture2D"):
		var texture := load(path) as Texture2D
		if texture != null and texture.get_size() == Vector2(48, 48):
			return texture
	return KNIGHT


static func tint(id: String, texture: Texture2D) -> Color:
	return Color.WHITE if texture != KNIGHT else Game.HEROES[id].tint


func build() -> void:
	title = "Minimized Dungeon"
	theme = Pixel.THEME
	unresizable = true
	always_on_top = true

	var frame := Panel.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(frame)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	margin.add_child(scroll)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)

	welcome = _column(body)
	var display := PanelContainer.new()
	welcome.add_child(display)
	var hall := TextureRect.new()
	hall.texture = Pixel.DUNGEON_BACKDROP
	hall.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	hall.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hall.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	display.add_child(hall)
	var title_art := TextureRect.new()
	title_art.texture = art(Game.DEFAULT_HERO)
	title_art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	title_art.custom_minimum_size.y = 144
	title_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	display.add_child(title_art)
	var heading := _label(welcome, "Minimized Dungeon", 32)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_color_override("font_color", Pixel.GOLD)
	_label(welcome, "A dungeon at the edge of your desktop.").horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	start = _button(welcome, "Choose your hero", _show_picker)

	picker = _column(body)
	_label(picker, "Choose your hero", 24)
	_label(picker, "Your hero changes appearance only.")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	picker.add_child(row)
	var list := _column(row)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var group := ButtonGroup.new()
	for id: String in Game.HEROES:
		var button := _button(list, Game.HEROES[id].name, _select.bind(id))
		button.toggle_mode = true
		button.button_group = group
		choices[id] = button

	var portrait := PanelContainer.new()
	portrait.custom_minimum_size = Vector2(112, 112)
	row.add_child(portrait)
	preview = TextureRect.new()
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.add_child(preview)
	announcement = _label(picker, "")
	enter = _button(picker, "Enter the dungeon", func(): hero_chosen.emit(selected))
	back = _button(picker, "Back", _show_welcome)


func open(id: String, first_run: bool, area: Rect2i) -> void:
	fresh = first_run
	_select(id)
	enter.text = "Enter the dungeon" if fresh else "Use this hero"
	back.visible = fresh
	Pixel.fit_window(self, Vector2i(568, 480), area)
	show()
	grab_focus()
	if fresh:
		_show_welcome()
	else:
		_show_picker()


func show_error(message: String) -> void:
	announcement.text = message


func _show_welcome() -> void:
	picker.hide()
	welcome.show()
	start.grab_focus()


func _show_picker() -> void:
	welcome.hide()
	picker.show()
	choices[selected].grab_focus()


func _select(id: String) -> void:
	selected = id
	choices[id].button_pressed = true
	preview.texture = art(id)
	preview.modulate = tint(id, preview.texture)
	announcement.text = Game.HEROES[id].description


func _column(parent: Node) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	parent.add_child(column)
	return column


func _label(parent: Node, caption: String, font_size: int = 16) -> Label:
	var label := Label.new()
	label.text = caption
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label


func _button(parent: Node, caption: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size.y = 38
	button.pressed.connect(action)
	parent.add_child(button)
	return button
