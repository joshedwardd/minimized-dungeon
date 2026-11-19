extends SceneTree

const Preview = preload("res://tests/preview_desktop.gd")
const Pixel = preload("res://ui/pixel_ui.gd")
var directory := "res://.godot/pixel-preview"
var captures: Array[String] = []
var failed := false


func _initialize() -> void:
	call_deferred("capture_preview")


func capture_preview() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Native rendering is required for screenshots.")
		quit(1)
		return
	if DirAccess.make_dir_recursive_absolute(directory) != OK:
		push_error("Cannot create screenshot directory.")
		quit(1)
		return
	create_timer(30.0).timeout.connect(func():
		push_error("Native capture exceeded 30 seconds.")
		quit(1)
	)
	var desktop := Preview.new()
	root.add_child(desktop)
	desktop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	OS.low_processor_usage_mode = false
	desktop.game.data.gold = 240
	desktop.game.data.eggs = 2
	desktop.game.data.unlocked = 6
	desktop.game.data.stage = 2
	desktop.game.data.pets = {"moss": 2, "ember": 1, "swift": 1, "stone": 1, "wisp": 1}
	desktop.game.data.equipped = "moss"
	desktop.set_process(false)
	desktop._refresh_game_ui()
	await capture(root, "strip")
	desktop.game.data.remainder = desktop.game.encounter().fight_time + 0.25
	desktop._refresh_game_ui()
	desktop.queue_redraw()
	await capture(root, "strip-recovering")
	desktop.transparent_enabled = true
	desktop._apply_transparency()
	await capture(root, "strip-transparent")
	desktop._show_progression()
	desktop.set_process(false)
	for index in 3:
		desktop.progression.tabs.current_tab = index
		await capture(desktop.progression, ["hero", "pets", "dungeon"][index])
	var popup: PopupMenu = desktop.progression.stage_choice.get_popup()
	popup.popup(Rect2i(desktop.progression.position + Vector2i(40, 120), Vector2i(260, 220)))
	await capture(popup, "floor-popup")
	popup.hide()
	for index in desktop.Game.PETS.size():
		var pet: Dictionary = desktop.Game.PETS[index]
		desktop.game_message = "%s %s! Duplicate: +1 pet level." % [desktop.Game.RARITIES[index], pet.name]
		desktop.progression.show_hatch_result({"id": pet.id, "rarity": desktop.Game.RARITIES[index]}, desktop.game_message)
		desktop.progression.tabs.current_tab = 1
		desktop._refresh_game_ui()
		await capture(desktop.progression, "hatch-" + desktop.Game.RARITIES[index].to_lower())
	desktop.game_message = "Rare Swift Rabbit! Select Equip to activate its bonus."
	desktop.progression.show_hatch_result({"id": "swift", "rarity": "Rare"}, desktop.game_message)
	desktop._refresh_game_ui()
	await capture(desktop.progression, "hatch-new-pet")
	desktop.progression.pet_rows.moss.label.text = "Moss Turtle With A Deliberately Long Companion Name / Common\nLv.2 +16 health"
	await capture(desktop.progression, "pets-long-name")
	desktop.game.data.gold = 0
	desktop.game.data.eggs = 0
	desktop.game.data.pets = {}
	desktop.game.data.equipped = ""
	desktop.game_message = "No companions yet. Earn an egg in the Rat Cellar."
	desktop._refresh_game_ui()
	await capture(desktop.progression, "pets-empty")
	desktop.progression.tabs.current_tab = 0
	await capture(desktop.progression, "hero-disabled")
	desktop.game.data.gold = desktop.Game.LIMIT
	desktop.game.data.eggs = desktop.Game.LIMIT
	desktop.game_message = "Welcome back: 480 minutes away, +46080 gold."
	desktop._refresh_game_ui()
	await capture(desktop.progression, "offline-large-values")
	desktop.game_message = "Cannot replace progress. Previous save retained. Current session continues; progress is not yet durable."
	desktop._refresh_game_ui()
	await capture(desktop.progression, "save-error")
	desktop._show_panel()
	desktop.set_process(false)
	await capture(desktop.panel, "settings")
	desktop.panel.hide()
	var dialog: ConfirmationDialog = desktop.progression.reset_dialog
	Pixel.fit_window(dialog, Vector2i(420, 240))
	dialog.show()
	await capture(dialog, "confirmation")
	dialog.hide()
	Pixel.fit_window(desktop.progression, Vector2i(620, 620), Rect2i(0, 0, 1280, 640))
	await capture(desktop.progression, "constrained-panel")
	var gallery := build_gallery()
	root.add_child(gallery)
	gallery.show()
	var focus_button: Button = gallery.get_meta("focus_button")
	focus_button.grab_focus()
	await capture(gallery, "control-states")
	if failed:
		quit(1)
		return
	var manifest := {"engine": Engine.get_version_info().string, "os": OS.get_name(),
		"os_version": OS.get_version(), "screen_scale": DisplayServer.screen_get_scale(),
		"screen_dpi": DisplayServer.screen_get_dpi(), "captures": captures,
		"fixture": "Preview state; no player saves read or written.",
		"scope": "Current OS/display scale only. Inspect images before marking visual checks complete."}
	var file := FileAccess.open(directory.path_join("manifest.json"), FileAccess.WRITE)
	if file == null:
		push_error("Cannot write capture manifest.")
		quit(1)
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()
	print("Native captures written: ", captures.size(), " to ", ProjectSettings.globalize_path(directory))
	quit()


func build_gallery() -> Window:
	var window := Window.new()
	window.title = "Pixel control state sample"
	window.theme = Pixel.THEME
	window.size = Vector2i(540, 540)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	window.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var heading := Label.new()
	heading.text = "Pixel control states"
	heading.add_theme_font_size_override("font_size", 24)
	box.add_child(heading)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var row := HBoxContainer.new()
		box.add_child(row)
		var label := Label.new()
		label.text = state.capitalize()
		label.custom_minimum_size.x = 140
		row.add_child(label)
		var button := Button.new()
		button.text = "Upgrade / 24 gold"
		button.disabled = state == "disabled"
		button.add_theme_stylebox_override("normal", Pixel.THEME.get_stylebox("normal" if state == "focus" else state, "Button"))
		row.add_child(button)
		if state == "focus":
			button.add_theme_stylebox_override("focus", Pixel.THEME.get_stylebox("focus", "Button"))
			window.set_meta("focus_button", button)
	for selected in [false, true]:
		var toggle := CheckButton.new()
		toggle.text = "Motion " + ("on" if selected else "off")
		toggle.button_pressed = selected
		box.add_child(toggle)
	var tooltip := PanelContainer.new()
	tooltip.add_theme_stylebox_override("panel", Pixel.THEME.get_stylebox("panel", "TooltipPanel"))
	box.add_child(tooltip)
	var tooltip_text := Label.new()
	tooltip_text.text = "Tooltip sample: 1000000000000 gold"
	tooltip.add_child(tooltip_text)
	return window


func capture(window: Window, name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image := window.get_texture().get_image()
	if image == null or image.is_empty():
		failed = true
		push_error("Empty native capture: " + name)
		quit(1)
		return
	if image.save_png(directory.path_join(name + ".png")) != OK:
		failed = true
		push_error("Cannot write native capture: " + name)
		quit(1)
		return
	captures.append(name + ".png")
