extends Control

const KNIGHT = preload("res://assets/knight/east.png")
const INK = Color("111a22")
const STONE = Color("25343e")
const PAPER = Color("f0e6ce")
const GOLD = Color("d8b777")
const SAVE_PATH = "user://desktop.cfg"
const Game = preload("res://scripts/game.gd")
const Store = preload("res://scripts/progress_store.gd")
const ProgressionPanel = preload("res://scripts/progression_panel.gd")
const RAT = preload("res://assets/creatures/rat.svg")
const SLASH = preload("res://assets/ui/slash.svg")
const HERO_POSITION = Vector2(320, 64)
const ENEMY_POSITION = Vector2(408, 80)
const PET_POSITION = Vector2(224, 80)
const Pixel = preload("res://ui/pixel_ui.gd")

var backdrop: Texture2D

var game = Game.new()
var store = Store.new()
var progression: Window
var enemy: Sprite2D
var companion: Sprite2D
var slash: Sprite2D
var battle_label: Label
var gold_label: Label
var pause_button: Button
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
var hide_button: Button
var motion_enabled := true
var transparent_enabled := false
var dragging := false
var drag_origin := Vector2i.ZERO
var display_signature := ""
var settings := ConfigFile.new()
var settings_writable := true


func _ready() -> void:
	Engine.max_fps = 30
	OS.low_processor_usage_mode = true
	get_tree().auto_accept_quit = false
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
	var timer := Timer.new()
	timer.wait_time = 2.0
	timer.timeout.connect(_check_displays)
	add_child(timer)
	timer.start()
	_check_displays()
	_update_hit_region()
	_refresh_game_ui()
	if "--shell-check" in OS.get_cmdline_user_args():
		call_deferred("_self_check")


func _build_theme() -> void:
	theme = Pixel.THEME
	get_window().theme = theme
	backdrop = Pixel.dungeon_texture()


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
	battle_label.position = Vector2(20, 24)
	battle_label.size = Vector2(144, 80)
	battle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	battle_label.add_theme_font_size_override("font_size", 16)
	add_child(battle_label)
	gold_label = Label.new()
	gold_label.position = Vector2(40, 128)
	gold_label.size = Vector2(200, 48)
	gold_label.clip_text = true
	gold_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	add_child(gold_label)
	var actions := HBoxContainer.new()
	actions.position = Vector2(250, 132)
	actions.add_theme_constant_override("separation", 6)
	add_child(actions)
	_button(actions, "Upgrades", _show_progression)
	pause_button = _button(actions, "Pause", func(): _game_action("pause", null))
	_button(actions, "Settings", _show_panel)
	hide_button = _button(actions, "Hide", _hide_strip)
	_button(actions, "Quit", _quit)
	gui_input.connect(_drag_input)
	for child in get_children():
		if child is Label:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE


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
	note.text = "Drag the strip to move it.\nOne equipped pet boosts your hero."
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
	transparency.text = "Transparent background"
	transparency.toggled.connect(func(value: bool):
		transparent_enabled = value
		_apply_transparency()
		_save_settings()
	)
	box.add_child(transparency)
	transparency.name = "Transparency"
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	box.add_child(actions)
	_button(actions, "Reset position", _reset_position)
	_button(actions, "Close", func(): panel.hide())
	panel.set_meta("controls", box)


func _build_status_menu() -> void:
	if DisplayServer.get_name() == "headless":
		hide_button.disabled = true
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
		hide_button.disabled = true
		hide_button.tooltip_text = "No tray icon available; hiding is disabled to keep the game reachable."


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
	knight.modulate = Color.WHITE
	enemy.modulate = Color.WHITE
	slash.visible = false
	var fight: Dictionary = game.encounter()
	var elapsed := float(game.data.remainder)
	var recovering: bool = elapsed >= fight.fight_time
	enemy.visible = not (recovering and fight.won)
	if recovering and not fight.won:
		knight.modulate = Color("82919a")
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
		knight.modulate = Color("dc9889")
		if not impact:
			enemy.position.x -= 8
	companion.position.y -= 2 if fmod(elapsed, 1.6) > 0.8 else 0


func _draw() -> void:
	if not transparent_enabled:
		draw_rect(Rect2(Vector2.ZERO, size), INK)
		draw_texture_rect(backdrop, Rect2(0, 16, 760, 96), false)
	var frame: StyleBox = theme.get_stylebox("panel", "Panel")
	draw_style_box(frame, Rect2(8, 16, 160, 80))
	draw_style_box(frame, Rect2(0, 120, size.x, 60))
	draw_rect(Rect2(0, 112, size.x, 8), STONE)
	for x in range(0, int(size.x), 32):
		draw_rect(Rect2(x, 112, 30, 2), Color("52616a"))
	draw_texture(Pixel.COIN, Vector2(16, 130))
	draw_texture(Pixel.EGG, Vector2(16, 152))
	var fight: Dictionary = game.encounter()
	var elapsed := minf(float(game.data.remainder), fight.fight_time)
	var hero_fraction := maxf(0.0, 1.0 - elapsed / fight.death_time)
	var enemy_fraction := maxf(0.0, 1.0 - elapsed / fight.kill_time)
	for entry in [[280, hero_fraction, Color("99cf94")], [368, enemy_fraction, Color("dc9889")]]:
		draw_rect(Rect2(entry[0], 112, 80, 8), Color("52616a"))
		draw_rect(Rect2(entry[0] + 2, 114, 76, 4), INK)
		draw_rect(Rect2(entry[0] + 2, 114, floorf(38 * entry[1]) * 2, 4), entry[2])


func _drag_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = event.pressed
		drag_origin = DisplayServer.mouse_get_position() - get_window().position
		if not dragging:
			_clamp_position()
			_save_settings()
	elif event is InputEventMouseMotion and dragging:
		get_window().position = DisplayServer.mouse_get_position() - drag_origin


func _show_panel() -> void:
	_restore_strip()
	Pixel.fit_window(panel, Vector2i(440, 360))
	panel.show()
	panel.grab_focus()
	var box: VBoxContainer = panel.get_meta("controls")
	box.get_node("Motion").grab_focus()


func _hide_strip() -> void:
	if hide_button.disabled:
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
	set_process(true)


func _reset_position() -> void:
	var area := DisplayServer.screen_get_usable_rect(DisplayServer.get_primary_screen())
	get_window().position = Vector2i(area.position.x + (area.size.x - get_window().size.x) / 2,
		area.end.y - get_window().size.y - 8)
	_clamp_position()
	_save_settings()


func _clamp_position() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var screen := DisplayServer.get_primary_screen()
	for index in DisplayServer.get_screen_count():
		var bounds := DisplayServer.screen_get_usable_rect(index)
		if bounds.has_point(get_window().position + get_window().size / 2):
			screen = index
			break
	var area := DisplayServer.screen_get_usable_rect(screen)
	var maximum := area.end - get_window().size
	get_window().position = Vector2i(
		clampi(get_window().position.x, area.position.x, maxi(area.position.x, maximum.x)),
		clampi(get_window().position.y, area.position.y, maxi(area.position.y, maximum.y)))


func _check_displays() -> void:
	if DisplayServer.get_name() == "headless":
		return
	if indicator != null:
		hide_button.disabled = indicator.get_rect().size == Vector2.ZERO
	var signature := ""
	for index in DisplayServer.get_screen_count():
		signature += str(DisplayServer.screen_get_usable_rect(index))
	if signature != display_signature:
		display_signature = signature
		_clamp_position()


func _apply_transparency() -> void:
	get_window().transparent = transparent_enabled
	get_window().transparent_bg = transparent_enabled
	_update_hit_region()
	queue_redraw()


func _update_hit_region() -> void:
	var y := 16.0 if transparent_enabled else 0.0
	get_window().mouse_passthrough_polygon = PackedVector2Array([
		Vector2(0, y), Vector2(size.x, y), Vector2(size.x, size.y), Vector2(0, size.y)])


func _load_settings() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var result := settings.load(SAVE_PATH)
	if result == OK:
		motion_enabled = bool(settings.get_value("desktop", "motion", true))
		transparent_enabled = bool(settings.get_value("desktop", "transparent", false))
		var position_value: Variant = settings.get_value("desktop", "position", null)
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
	_apply_transparency()
	_clamp_position()


func _save_settings() -> void:
	if DisplayServer.get_name() == "headless" or not settings_writable:
		return
	settings.set_value("desktop", "motion", motion_enabled)
	settings.set_value("desktop", "transparent", transparent_enabled)
	settings.set_value("desktop", "position", get_window().position)
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
	elif result.seconds >= 60:
		game_message = "Welcome back: %d minutes away, +%d gold. %s" % [int(result.seconds / 60), result.gold, store.message]


func _synchronize_game() -> void:
	var now_tick := Time.get_ticks_msec()
	var now_wall := Time.get_unix_time_from_system()
	var elapsed := maxf(0.0, (now_tick - last_tick) / 1000.0)
	var wall_elapsed := maxf(0.0, now_wall - last_wall)
	if can_play:
		var absent := elapsed > 2.0 or wall_elapsed > 2.0
		var result: Dictionary = game.advance(maxf(elapsed, wall_elapsed) if absent else elapsed, absent)
		game.data.checkpoint = now_wall
		if absent and result.gold > 0:
			game_message = "Away progress: +%d gold (up to 8 hours)." % result.gold
		if now_tick - last_save >= 60000 or absent:
			_save_game()
	last_tick = now_tick
	last_wall = now_wall


func _save_game() -> bool:
	if not can_play:
		return false
	var saved: bool = store.save_progress(game)
	last_save = Time.get_ticks_msec()
	if not saved:
		game_message = store.message + " Current session continues; progress is not yet durable."
	return saved


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
		"stage": changed = game.select_stage(int(value))
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
			game_message = "Progress reset. Previous files were preserved." if can_play else store.message
			_refresh_game_ui()
			return
	if changed:
		game.data.checkpoint = Time.get_unix_time_from_system()
		if not _save_game():
			game.data = previous
		else:
			game_message = notice
			if not hatch_result.is_empty():
				progression.show_hatch_result(hatch_result, notice)
	_refresh_game_ui()


func _show_progression() -> void:
	_restore_strip()
	progression.refresh(game, game_message, can_play, owns_lock)
	Pixel.fit_window(progression, Vector2i(620, 620))
	progression.show()
	progression.grab_focus()


func _refresh_game_ui() -> void:
	var fight: Dictionary = game.encounter()
	battle_label.text = "Rat Cellar\nFloor %d / %s" % [game.data.stage,
		"Paused" if game.data.paused else ("Battling" if game.data.remainder < fight.fight_time else "Recovering")]
	gold_label.text = "%d gold\n%d eggs" % [game.data.gold, game.data.eggs]
	gold_label.tooltip_text = gold_label.text
	pause_button.text = "Resume" if game.data.paused else "Pause"
	pause_button.disabled = not can_play
	companion.visible = game.data.equipped != ""
	for pet in Game.PETS:
		if pet.id == game.data.equipped:
			companion.texture = Pixel.PET_TEXTURES[pet.id]
	if not can_play:
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
