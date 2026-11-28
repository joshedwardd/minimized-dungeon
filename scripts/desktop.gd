extends Control

const KNIGHT = preload("res://assets/knight/east.png")
const INK = Color("111a22")
const GOLD = Color("d8b777")
const STRIP_SIZE := Vector2i(760, 180)
const PLACEMENTS := ["Custom", "Bottom left", "Bottom center", "Bottom right",
	"Top left", "Top center", "Top right"]
const BOTTOM_CENTER := 2
enum { MENU_UPGRADES, MENU_PAUSE, MENU_SETTINGS, MENU_HIDE, MENU_QUIT }
const SAVE_PATH = "user://desktop.cfg"
const Game = preload("res://scripts/game.gd")
const Store = preload("res://scripts/progress_store.gd")
const HeroSelection = preload("res://scripts/hero_selection.gd")
const ProgressionPanel = preload("res://scripts/progression_panel.gd")
const RAT = preload("res://assets/creatures/rat.svg")
const SLASH = preload("res://assets/gemini/combat-slash.png")
const HEALTH_BAR_FRAME = preload("res://assets/gemini/health-bar-frame.png")
const HERO_POSITION = Vector2(320, 64)
const ENEMY_POSITION = Vector2(408, 80)
const PET_POSITION = Vector2(224, 80)
const Pixel = preload("res://ui/pixel_ui.gd")

var backdrop: Texture2D

var game = Game.new()
var store = Store.new()
var progression: Window
var hero_selection: HeroSelection
var first_run := false
var hero_tint := Color.WHITE
var enemy: Sprite2D
var companion: Sprite2D
var slash: Sprite2D
var battle_label: Label
var gold_label: Label
var actions_menu: PopupMenu
var return_summary: Label
var dismiss_summary: Button
var pending_return: Dictionary = {}
var return_text := ""
var boss_result := ""
var boss_result_until := 0
var can_play := false
var owns_lock := false
var game_message := ""
var last_tick := 0
var last_wall := 0.0
var last_save := 0
var hud_time := 0.0

var panel: Window
var knight: Sprite2D
var status_menu: PopupMenu
var indicator: StatusIndicator
var placement_choice: OptionButton
var scale_choice: OptionButton
var placement := BOTTOM_CENTER
var strip_scale := 1
var background_opacity := 100
var use_transparency := false
var motion_enabled := true
var transparent_enabled := false
var dragging := false
var drag_origin := Vector2i.ZERO
var drag_moved := false
var display_signature := ""
var settings := ConfigFile.new()
var settings_writable := true


func _ready() -> void:
	Engine.max_fps = 30
	OS.low_processor_usage_mode = true
	get_tree().auto_accept_quit = false
	get_window().content_scale_size = STRIP_SIZE
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	get_window().unresizable = true
	get_window().close_requested.connect(_quit)
	get_window().size_changed.connect(_update_hit_region)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_boot_game()
	_build_theme()
	_build_strip()
	_build_panel()
	progression = ProgressionPanel.new()
	add_child(progression)
	progression.build(theme)
	progression.action_requested.connect(_game_action)
	_build_status_menu()
	_load_settings()
	_apply_hero()
	var timer := Timer.new()
	timer.wait_time = 2.0
	timer.timeout.connect(_check_displays)
	add_child(timer)
	timer.start()
	_check_displays()
	_update_hit_region()
	_refresh_game_ui()
	if first_run:
		_open_hero_selection.call_deferred()
	if "--shell-check" in OS.get_cmdline_user_args():
		call_deferred("_self_check")


func _build_theme() -> void:
	theme = Pixel.THEME
	get_window().theme = theme
	var stone := Pixel.DUNGEON_BACKDROP.get_image()
	stone.convert(Image.FORMAT_RGBA8)
	var image := Image.create(STRIP_SIZE.x, STRIP_SIZE.y, false, Image.FORMAT_RGBA8)
	image.fill(INK)
	image.blit_rect(stone, Rect2i(Vector2i.ZERO, stone.get_size()), Vector2i(16, 16))
	image.fill_rect(Rect2i(24, 24, 176, 92), INK)
	image.fill_rect(Rect2i(524, 24, 212, 108), INK)
	backdrop = ImageTexture.create_from_image(image)


func _build_strip() -> void:
	knight = Sprite2D.new()
	knight.texture = KNIGHT
	knight.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	knight.scale = Vector2(2, 2)
	knight.position = HERO_POSITION
	knight.offset.y = 48 - KNIGHT.get_image().get_used_rect().end.y
	add_child(knight)
	enemy = Sprite2D.new()
	enemy.texture = RAT
	enemy.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	enemy.scale = Vector2(2, 2)
	enemy.position = ENEMY_POSITION
	add_child(enemy)
	companion = Sprite2D.new()
	companion.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	companion.scale = Vector2(2, 2)
	companion.position = PET_POSITION
	add_child(companion)
	slash = Sprite2D.new()
	slash.texture = SLASH
	slash.scale = Vector2(2, 2)
	slash.position = Vector2(376, 80)
	slash.visible = false
	add_child(slash)
	battle_label = Label.new()
	battle_label.position = Vector2(32, 31)
	battle_label.size = Vector2(156, 84)
	battle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	battle_label.add_theme_font_size_override("font_size", 16)
	add_child(battle_label)
	gold_label = Label.new()
	gold_label.position = Vector2(558, 35)
	gold_label.size = Vector2(164, 52)
	gold_label.mouse_filter = Control.MOUSE_FILTER_PASS
	gold_label.clip_text = true
	gold_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	add_child(gold_label)
	var menu := MenuButton.new()
	menu.text = "Menu"
	menu.position = Vector2(532, 94)
	menu.size = Vector2(196, 38)
	add_child(menu)
	actions_menu = menu.get_popup()
	actions_menu.prefer_native_menu = false
	actions_menu.theme = theme
	for label in ["Upgrades", "Pause", "Settings", "Hide", "Quit"]:
		actions_menu.add_item(label)
	actions_menu.set_item_icon(MENU_SETTINGS, Pixel.SETTINGS_ICON)
	actions_menu.id_pressed.connect(_menu_action)
	return_summary = Label.new()
	return_summary.position = Vector2(32, 136)
	return_summary.size = Vector2(574, 40)
	return_summary.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(return_summary)
	dismiss_summary = _button(self, "Dismiss", func():
		return_text = ""
		_refresh_game_ui()
	)
	dismiss_summary.position = Vector2(616, 133)
	dismiss_summary.size = Vector2(112, 38)
	gui_input.connect(_drag_input)
	battle_label.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _menu_action(id: int) -> void:
	match id:
		MENU_UPGRADES: _show_progression()
		MENU_PAUSE: _game_action("pause", null)
		MENU_SETTINGS: _show_panel()
		MENU_HIDE: _hide_strip()
		MENU_QUIT: _quit()



func _build_panel() -> void:
	panel = Window.new()
	panel.title = "Minimized Dungeon - Settings"
	panel.size = Vector2i(440, 360)
	panel.min_size = Vector2i(300, 200)
	panel.theme = theme
	panel.unresizable = true
	panel.always_on_top = true
	panel.visible = false
	panel.close_requested.connect(func(): panel.hide())
	add_child(panel)
	var background := Panel.new()
	background.theme = theme
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 24)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.theme = theme
	box.add_theme_constant_override("separation", 16)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)
	var heading := Label.new()
	heading.text = "Desktop settings"
	heading.add_theme_font_size_override("font_size", 24)
	box.add_child(heading)
	var note := Label.new()
	note.text = "Drag the dungeon to place it anywhere."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(note)
	var motion := CheckButton.new()
	motion.text = "Combat animation"
	motion.button_pressed = true
	motion.toggled.connect(func(value: bool):
		motion_enabled = value
		_update_combat_presentation()
		_save_settings()
	)
	box.add_child(motion)
	motion.name = "Motion"
	var transparency := CheckButton.new()
	transparency.text = "Transparent top margin"
	transparency.toggled.connect(func(value: bool):
		transparent_enabled = value
		_apply_transparency()
		_save_settings()
	)
	box.add_child(transparency)
	transparency.name = "Transparency"
	placement_choice = _setting_choice(box, "Placement", PLACEMENTS)
	placement_choice.item_selected.connect(func(index: int):
		placement = index
		_clamp_position()
		_save_settings()
	)
	scale_choice = _setting_choice(box, "Strip scale", ["1×", "2×"])
	scale_choice.item_selected.connect(func(index: int):
		strip_scale = index + 1
		_clamp_position()
		_save_settings()
	)
	var opacity_choice := _setting_choice(box, "Background opacity", ["100%", "85%", "70%", "55%"])
	opacity_choice.name = "Opacity"
	opacity_choice.disabled = not DisplayServer.has_feature(DisplayServer.FEATURE_WINDOW_TRANSPARENCY)
	transparency.disabled = opacity_choice.disabled
	opacity_choice.item_selected.connect(func(index: int):
		background_opacity = 100 - index * 15
		_apply_transparency()
		_save_settings()
	)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	box.add_child(actions)
	_button(actions, "Reset position", _reset_position)
	_button(actions, "Close", func(): panel.hide())
	_button(box, "Choose hero", _open_hero_selection)
	panel.set_meta("controls", box)


func _setting_choice(parent: VBoxContainer, caption: String, options: Array) -> OptionButton:
	var label := Label.new()
	label.text = caption
	parent.add_child(label)
	var choice := OptionButton.new()
	choice.accessibility_name = caption
	choice.custom_minimum_size.y = 38
	for option in options:
		choice.add_item(option)
	choice.get_popup().prefer_native_menu = false
	parent.add_child(choice)
	return choice


func _build_status_menu() -> void:
	if DisplayServer.get_name() == "headless":
		actions_menu.set_item_disabled(MENU_HIDE, true)
		return
	status_menu = PopupMenu.new()
	status_menu.name = "StatusMenu"
	status_menu.prefer_native_menu = true
	status_menu.add_item("Show Minimized Dungeon", 0)
	status_menu.add_item("Settings", 1)
	status_menu.add_item("Hero and pets", 3)
	status_menu.add_separator()
	status_menu.add_item("Quit", 2)
	status_menu.id_pressed.connect(func(id: int):
		match id:
			0: _restore_strip()
			1: _show_panel()
			2: _quit()
			3: _show_progression()
	)
	add_child(status_menu)
	indicator = StatusIndicator.new()
	indicator.icon = KNIGHT
	indicator.tooltip = "Minimized Dungeon"
	add_child(indicator)
	indicator.menu = indicator.get_path_to(status_menu)
	if indicator.get_rect().size == Vector2.ZERO:
		actions_menu.set_item_disabled(MENU_HIDE, true)
		actions_menu.set_item_tooltip(MENU_HIDE, "No tray icon available; hiding is disabled to keep the game reachable.")


func _button(parent: Node, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 38
	button.pressed.connect(action)
	parent.add_child(button)
	return button


func _process(delta: float) -> void:
	if get_window().mode == Window.MODE_MINIMIZED:
		_hide_strip()
		return
	_synchronize_game()
	_update_combat_presentation()
	hud_time += delta
	if hud_time > 0.25:
		hud_time = 0.0
		_refresh_game_ui()
	queue_redraw()


func _update_combat_presentation() -> void:
	knight.position = HERO_POSITION
	enemy.position = ENEMY_POSITION
	companion.position = PET_POSITION
	knight.modulate = hero_tint
	enemy.modulate = GOLD if Game.is_boss(int(game.data.stage)) else Color.WHITE
	slash.visible = false
	var fight: Dictionary = game.encounter()
	var elapsed := float(game.data.remainder)
	var recovering: bool = elapsed >= fight.fight_time
	enemy.visible = not (recovering and fight.won)
	if recovering and not fight.won:
		knight.modulate = hero_tint * Color("82919a")
	if not motion_enabled or game.data.paused or not can_play or recovering:
		return
	# cap decorative strikes; combat keeps the full attack speed.
	var speed := minf(float(game.attributes().speed), 2.5)
	var attack_phase := fmod(elapsed * speed, 1.0)
	var impact := elapsed >= 1.0 / speed and attack_phase < 0.25
	if attack_phase >= 0.8:
		knight.position.x -= 4
	elif impact:
		knight.position.x += 10
		enemy.position.x += 6
		enemy.modulate = Color("e8c477")
		slash.visible = true
	else:
		knight.position.y -= 2 if fmod(elapsed, 1.2) > 0.6 else 0
	if elapsed >= 1.25 and fmod(elapsed, 1.25) < 0.12:
		knight.position.x -= 4
		knight.modulate = hero_tint * Color("dc9889")
		if not impact:
			enemy.position.x -= 8
	companion.position.y -= 2 if fmod(elapsed, 1.6) > 0.8 else 0


func _draw() -> void:
	var opacity := float(background_opacity) / 100.0 if use_transparency else 1.0
	var top := 16 if use_transparency and transparent_enabled else 0
	var bounds := Rect2(0, top, STRIP_SIZE.x, STRIP_SIZE.y - top)
	draw_texture_rect_region(backdrop, bounds, bounds, Color(1, 1, 1, opacity))
	draw_texture(Pixel.COIN, Vector2(536, 38))
	draw_texture(Pixel.EGG, Vector2(536, 58))
	var fight: Dictionary = game.encounter()
	var elapsed := minf(float(game.data.remainder), fight.fight_time)
	var hero_fraction := maxf(0.0, 1.0 - elapsed / fight.death_time)
	var enemy_fraction := maxf(0.0, 1.0 - elapsed / fight.kill_time)
	for entry in [[280, hero_fraction, Color("99cf94")], [368, enemy_fraction, Color("dc9889")]]:
		draw_texture(HEALTH_BAR_FRAME, Vector2(entry[0], 110))
		draw_rect(Rect2(entry[0] + 4, 114, floorf(36 * entry[1]) * 2, 4), entry[2])



func _drag_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = event.pressed
		if dragging:
			drag_moved = false
			drag_origin = DisplayServer.mouse_get_position() - get_window().position
		elif drag_moved:
			_clamp_position()
			_save_settings()
	elif event is InputEventMouseMotion and dragging:
		var position := DisplayServer.mouse_get_position() - drag_origin
		if position != get_window().position:
			drag_moved = true
			placement = 0
			get_window().position = position


func _show_panel() -> void:
	if first_run:
		return
	_restore_strip()
	Pixel.fit_window(panel, Vector2i(440, 360))
	panel.show()
	panel.grab_focus()
	var box: VBoxContainer = panel.get_meta("controls")
	box.get_node("Motion").grab_focus()


func _hide_strip() -> void:
	if first_run:
		return
	if actions_menu.is_item_disabled(MENU_HIDE):
		get_window().mode = Window.MODE_WINDOWED
		return
	panel.hide()
	progression.hide()
	_synchronize_game()
	_save_game()
	_save_settings()
	get_window().mode = Window.MODE_MINIMIZED
	RenderingServer.render_loop_enabled = false
	set_process(false)


func _restore_strip() -> void:
	_synchronize_game()
	_save_game()
	RenderingServer.render_loop_enabled = true
	get_window().mode = Window.MODE_WINDOWED
	_clamp_position()
	_refresh_game_ui()
	set_process(true)


func _reset_position() -> void:
	placement = BOTTOM_CENTER
	_clamp_position()
	_save_settings()


func _work_area() -> Rect2i:
	var screen := DisplayServer.get_primary_screen()
	var center := get_window().position + get_window().size / 2
	for index in DisplayServer.get_screen_count():
		if DisplayServer.screen_get_usable_rect(index).has_point(center):
			screen = index
			break
	return DisplayServer.screen_get_usable_rect(screen)


func _clamp_position() -> void:
	if DisplayServer.get_name() == "headless":
		return
	_apply_strip_layout(_work_area())


func _apply_strip_layout(area: Rect2i) -> void:
	var window := get_window()
	var fits_double := area.size.x >= STRIP_SIZE.x * 2 and area.size.y >= STRIP_SIZE.y * 2
	var ratio := minf(2.0 if strip_scale == 2 and fits_double else 1.0,
		minf(float(area.size.x) / STRIP_SIZE.x, float(area.size.y) / STRIP_SIZE.y))
	window.size = Vector2i(Vector2(STRIP_SIZE) * ratio).max(Vector2i.ONE)
	var room := (area.size - window.size).max(Vector2i.ZERO)
	var maximum := area.position + room
	if placement == 0:
		window.position = window.position.clamp(area.position, maximum)
	else:
		var horizontal_margin := mini(8, room.x / 2)
		var vertical_margin := mini(8, room.y / 2)
		var column := (placement - 1) % 3
		var x: int = [horizontal_margin, room.x / 2, room.x - horizontal_margin][column]
		var y := room.y - vertical_margin if placement <= 3 else vertical_margin
		window.position = area.position + Vector2i(x, y)
	placement_choice.select(placement)
	scale_choice.set_item_disabled(1, not fits_double)
	scale_choice.select(1 if strip_scale == 2 and fits_double else 0)
	_update_hit_region()



func _check_displays() -> void:
	if DisplayServer.get_name() == "headless":
		return
	if indicator != null:
		actions_menu.set_item_disabled(MENU_HIDE, indicator.get_rect().size == Vector2.ZERO)
	var signature := ""
	for index in DisplayServer.get_screen_count():
		signature += str(DisplayServer.screen_get_usable_rect(index))
	if signature != display_signature:
		display_signature = signature
		_clamp_position()


func _apply_transparency() -> void:
	use_transparency = (transparent_enabled or background_opacity < 100) and DisplayServer.has_feature(DisplayServer.FEATURE_WINDOW_TRANSPARENCY)
	get_window().transparent = use_transparency
	get_window().transparent_bg = use_transparency
	_update_hit_region()
	queue_redraw()


func _update_hit_region() -> void:
	if not use_transparency or not transparent_enabled:
		get_window().mouse_passthrough_polygon = PackedVector2Array()
		return
	var physical := Vector2(get_window().size)
	var y := roundf(16.0 * physical.y / STRIP_SIZE.y)
	get_window().mouse_passthrough_polygon = PackedVector2Array([
		Vector2(0, y), Vector2(physical.x, y), physical, Vector2(0, physical.y)])



func _load_settings() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var result := settings.load(SAVE_PATH)
	if result == OK:
		motion_enabled = bool(settings.get_value("desktop", "motion", true))
		transparent_enabled = bool(settings.get_value("desktop", "transparent", false))
		background_opacity = 100 - 15 * clampi(roundi((100.0 - int(settings.get_value("desktop", "opacity", 100))) / 15.0), 0, 3)
		strip_scale = 2 if settings.get_value("desktop", "scale", 1) == 2 else 1
		var position_value: Variant = settings.get_value("desktop", "position", null)
		placement = clampi(int(settings.get_value("desktop", "placement", 0 if position_value is Vector2i else BOTTOM_CENTER)), 0, PLACEMENTS.size() - 1)
		if position_value is Vector2i:
			get_window().position = position_value
		else:
			_reset_position()
	elif result == ERR_FILE_NOT_FOUND:
		_reset_position()
	else:
		settings_writable = false
		push_warning("Desktop settings could not be loaded; original file retained.")
		_reset_position()
	var box: VBoxContainer = panel.get_meta("controls")
	box.get_node("Motion").set_pressed_no_signal(motion_enabled)
	box.get_node("Transparency").set_pressed_no_signal(transparent_enabled)
	box.get_node("Opacity").select((100 - background_opacity) / 15)
	_apply_transparency()
	_clamp_position()


func _save_settings() -> void:
	if DisplayServer.get_name() == "headless" or not settings_writable:
		return
	settings.set_value("desktop", "motion", motion_enabled)
	settings.set_value("desktop", "transparent", transparent_enabled)
	settings.set_value("desktop", "position", get_window().position)
	settings.set_value("desktop", "placement", placement)
	settings.set_value("desktop", "scale", strip_scale)
	settings.set_value("desktop", "opacity", background_opacity)
	var error := settings.save(SAVE_PATH)
	if error != OK:
		push_warning("Desktop settings were not saved: " + error_string(error))


func _quit() -> void:
	_synchronize_game()
	_save_game()
	_save_settings()
	get_tree().quit()


func _boot_game() -> void:
	last_tick = Time.get_ticks_msec()
	last_wall = Time.get_unix_time_from_system()
	last_save = last_tick
	if DisplayServer.get_name() == "headless":
		game.data.checkpoint = last_wall
		return
	owns_lock = store.acquire_lock()
	if not owns_lock:
		game_message = "Another instance is running, or the local instance lock is unavailable. Close the other game and restart."
		return
	if not FileAccess.file_exists(store.path) and not FileAccess.file_exists(store.path + ".bak"):
		first_run = true
		return
	store.read_progress(game)
	game_message = store.message
	if not store.writable:
		return
	var previous: Dictionary = game.data.duplicate(true)
	var result: Dictionary = game.settle(last_wall)
	can_play = store.save_progress(game)
	if not can_play:
		game.data = previous
		game_message = store.message
	elif result.seconds >= 60 and (result.gold > 0 or result.xp > 0):
		_set_return_summary(result)


func _open_hero_selection() -> void:
	if not first_run and not can_play:
		return
	panel.hide()
	if hero_selection == null:
		hero_selection = HeroSelection.new()
		hero_selection.visible = false
		add_child(hero_selection)
		hero_selection.build()
		hero_selection.hero_chosen.connect(_choose_hero)
		hero_selection.close_requested.connect(func():
			if first_run:
				_quit()
			else:
				hero_selection.hide()
		)
	var area := Rect2i(0, 0, 1280, 720) if DisplayServer.get_name() == "headless" else _work_area()
	hero_selection.open(game.data.get("hero", Game.DEFAULT_HERO), first_run, area)


func _choose_hero(id: String) -> void:
	if not Game.HEROES.has(id) or not (first_run or can_play):
		return
	_synchronize_game()
	var previous: Dictionary = game.data.duplicate(true)
	game.data.hero = id
	game.data.checkpoint = last_wall
	if not store.save_progress(game):
		game.data = previous
		hero_selection.show_error(store.message)
		return
	can_play = true
	first_run = false
	hero_selection.hide()
	_apply_hero()
	_refresh_game_ui()


func _apply_hero() -> void:
	var id: String = game.data.get("hero", Game.DEFAULT_HERO)
	knight.texture = HeroSelection.art(id)
	knight.offset.y = knight.texture.get_height() - knight.texture.get_image().get_used_rect().end.y
	hero_tint = HeroSelection.tint(id, knight.texture)
	knight.modulate = hero_tint


func _synchronize_game() -> void:
	var now_tick := Time.get_ticks_msec()
	var now_wall := Time.get_unix_time_from_system()
	var elapsed := maxf(0.0, (now_tick - last_tick) / 1000.0)
	var wall_elapsed := maxf(0.0, now_wall - last_wall)
	if can_play:
		var absent := elapsed > 2.0 or wall_elapsed > 2.0
		var result: Dictionary = game.advance(maxf(elapsed, wall_elapsed) if absent else elapsed, absent)
		game.data.checkpoint = now_wall
		if absent and result.seconds >= 60 and (result.gold > 0 or result.xp > 0):
			pending_return = result
		if not absent and result.battles > 0 and Game.is_boss(int(game.data.stage)):
			boss_result = "Boss cleared" if result.wins > 0 else "Boss defeated you"
			boss_result_until = now_tick + 3000
		if now_tick - last_save >= 60000 or absent:
			_save_game()
	last_tick = now_tick
	last_wall = now_wall


func _save_game() -> bool:
	if not can_play:
		return false
	var saved: bool = store.save_progress(game)
	last_save = Time.get_ticks_msec()
	if saved and not pending_return.is_empty():
		_set_return_summary(pending_return)
		pending_return.clear()
	elif not saved:
		game_message = store.message + " Current session continues; progress is not yet durable."
	return saved


func _set_return_summary(result: Dictionary) -> void:
	var minutes := floori(float(result.seconds) / 60.0)
	var levels := ""
	if result.levels > 0:
		levels = "  /  +%d %s" % [result.levels, "level" if result.levels == 1 else "levels"]
	return_text = "Back after %d min\n+%d gold  /  +%d XP%s" % [minutes, result.gold, result.xp, levels]


func _game_action(action: String, value: Variant) -> void:
	if not can_play and (action != "reset" or not owns_lock):
		return
	_synchronize_game()
	var previous: Dictionary = game.data.duplicate(true)
	var changed := false
	var notice := ""
	var hatch_result: Dictionary = {}
	match action:
		"hero": changed = game.upgrade_hero(str(value))
		"pet": changed = game.upgrade_pet(str(value))
		"equip": changed = game.equip(str(value))
		"stage":
			changed = game.select_stage(int(value))
		"pause":
			game.data.paused = not game.data.paused
			changed = true
		"hatch":
			var result: Dictionary = game.hatch()
			hatch_result = result
			changed = not result.is_empty()
			if changed:
				notice = "%s %s! %s" % [result.rarity, result.name,
					"Duplicate: +1 pet level." if result.duplicate else "Select Equip to activate its bonus."]
		"reset":
			can_play = store.reset_progress(game)
			if can_play:
				_apply_hero()
				return_text = ""
				pending_return.clear()
				boss_result_until = 0
			game_message = "Progress reset. Previous files were preserved." if can_play else store.message
			_refresh_game_ui()
			return
	if changed:
		game.data.checkpoint = Time.get_unix_time_from_system()
		if not _save_game():
			game.data = previous
		else:
			if action == "stage":
				boss_result_until = 0
			game_message = notice
			if not hatch_result.is_empty():
				progression.show_hatch_result(hatch_result, notice)
	_refresh_game_ui()


func _show_progression() -> void:
	if first_run:
		return
	_restore_strip()
	progression.refresh(game, game_message, can_play, owns_lock)
	Pixel.fit_window(progression, Vector2i(620, 620))
	progression.show()
	progression.grab_focus()


func _refresh_game_ui() -> void:
	var fight: Dictionary = game.encounter()
	var boss := Game.is_boss(int(game.data.stage))
	var status := "Battling" if game.data.remainder < fight.fight_time else "Recovering"
	if boss and Time.get_ticks_msec() < boss_result_until:
		status = boss_result
	if game.data.paused:
		status = "Paused"
	battle_label.modulate = GOLD if boss else Color.WHITE
	battle_label.text = "%s\nFloor %d\n%s" % ["Boss floor" if boss else "Rat Cellar", game.data.stage, status]
	gold_label.text = "%d gold\n%d eggs" % [game.data.gold, game.data.eggs]
	gold_label.tooltip_text = gold_label.text
	actions_menu.set_item_text(MENU_PAUSE, "Resume" if game.data.paused else "Pause")
	actions_menu.set_item_disabled(MENU_PAUSE, not can_play)
	return_summary.text = return_text
	return_summary.visible = not return_text.is_empty()
	dismiss_summary.visible = return_summary.visible
	companion.visible = game.data.equipped != ""
	for pet in Game.PETS:
		if pet.id == game.data.equipped:
			companion.texture = Pixel.PET_TEXTURES[pet.id]
	if first_run:
		battle_label.text = "Rat Cellar\nChoose a hero to begin"
	elif not can_play:
		battle_label.text = "Progress unavailable\nOpen Upgrades for recovery"
	if progression.visible or not can_play:
		progression.refresh(game, game_message, can_play, owns_lock)


func _self_check() -> void:
	assert(Engine.max_fps == 30)
	assert(KNIGHT.get_size() == Vector2(48, 48))
	assert(ProjectSettings.get_setting("display/window/size/no_focus"))
	assert(ProjectSettings.get_setting("display/window/size/always_on_top"))
	if DisplayServer.get_name() != "headless":
		assert(get_window().unfocusable)
		assert(get_window().always_on_top)
	assert(panel.size == Vector2i(440, 360))
	print("Desktop shell checks passed.")
	get_tree().quit()
