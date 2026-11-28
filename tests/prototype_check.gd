extends SceneTree

const Pixel = preload("res://ui/pixel_ui.gd")
var failures := 0


func _initialize() -> void:
	call_deferred("run_checks")


func run_checks() -> void:
	var scene = load("res://scenes/desktop.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.store.path = ProjectSettings.globalize_path("res://.godot/md-ui-" + str(Time.get_ticks_usec()) + ".json")
	scene.can_play = true
	scene.owns_lock = true
	scene.game.data.checkpoint = Time.get_unix_time_from_system()
	scene.game.advance(6)
	scene._show_progression()
	await process_frame
	scene.progression.tabs.current_tab = 1
	await process_frame
	await process_frame
	scene.motion_enabled = false
	scene.progression.hatch_button.pressed.emit()
	check(scene.game.data.pets.size() == 1, "hatch UI creates a pet")
	check(scene.progression.result_icon.visible, "instant hatch result includes pet icon")
	check(not scene.motion_enabled and scene.game_message.contains("Equip"), "motion-off hatch is immediate and informative")
	var pet_id: String = scene.game.data.pets.keys()[0]
	scene.progression.pet_rows[pet_id].equip.pressed.emit()
	check(scene.game.data.equipped == pet_id, "equip UI activates hatched pet")
	scene.game.data.gold = 200
	scene.progression.refresh(scene.game, "", true)
	scene.progression.hero_buttons.attack.pressed.emit()
	check(scene.game.data.upgrades.attack == 1, "hero upgrade UI purchases once")
	scene.progression.pet_rows[pet_id].upgrade.pressed.emit()
	check(scene.game.data.pets[pet_id] == 2, "pet upgrade UI purchases once")
	scene.progression.stage_choice.item_selected.emit(1)
	check(scene.game.data.stage == 2, "dungeon UI changes stage")
	scene.actions_menu.id_pressed.emit(scene.MENU_PAUSE)
	check(scene.game.data.paused, "pause UI")
	scene.actions_menu.id_pressed.emit(scene.MENU_PAUSE)
	check(not scene.game.data.paused, "resume UI")
	var saved: Variant = JSON.parse_string(FileAccess.get_file_as_string(scene.store.path))
	check(saved != null and saved.equipped == pet_id and saved.pets[pet_id] == 2, "UI progress persisted")
	var copied_path: String = scene.store.path + ".copied"
	check(DirAccess.copy_absolute(scene.store.path, copied_path) == OK, "existing-format save copied")
	var copied_store = load("res://scripts/progress_store.gd").new()
	copied_store.path = copied_path
	var copied_game = scene.Game.new()
	copied_store.read_progress(copied_game)
	check(copied_game.data == saved, "existing-format save remains compatible with restyled UI")
	var before_absence: int = scene.game.data.gold
	scene.last_wall = Time.get_unix_time_from_system() - 60.0
	scene._synchronize_game()
	check(scene.game.data.gold > before_absence, "resume credits elapsed wall time")
	scene._refresh_game_ui()
	check(scene.return_summary.visible and scene.return_summary.text.contains("XP"), "durable absence shows XP and gold")
	scene.dismiss_summary.pressed.emit()
	check(not scene.return_summary.visible, "return summary dismisses")
	var after_absence: int = scene.game.data.gold
	scene._synchronize_game()
	check(scene.game.data.gold == after_absence, "resume does not double credit")
	var save_path: String = scene.store.path
	scene.store.path = save_path + "/invalid/progress.json"
	scene.last_wall = Time.get_unix_time_from_system() - 61.0
	scene._synchronize_game()
	scene._refresh_game_ui()
	check(not scene.return_summary.visible, "failed save defers the return summary")
	scene.store.path = save_path
	check(scene._save_game(), "retry saves the offline reward")
	scene._refresh_game_ui()
	check(scene.return_summary.visible, "successful retry shows the pending summary")
	scene.dismiss_summary.pressed.emit()

	for pet in scene.Game.PETS:
		scene.game.data.pets[pet.id] = 1
	scene.game.data.remainder = 0.0
	scene.game.data.eggs = 1
	scene._game_action("hatch", null)
	check(scene.game_message.contains("Duplicate: +1 pet level.") and scene.progression.result_icon.visible, "duplicate result is explicit")
	var pet_levels: Dictionary = scene.game.data.pets.duplicate(true)
	scene.game.data.paused = true
	scene.progression.hide()
	scene._show_progression()
	check(scene.game.data.pets == pet_levels and scene.game.data.eggs == 0, "reopening result never grants another hatch")
	scene.game.data.paused = false
	await process_frame
	check(scene.progression.size.x <= 640, "progression window remains compact")
	check(scene.progression.size.y <= 660, "progression window fits intended height")
	check(scene.theme == Pixel.THEME and scene.panel.theme == Pixel.THEME and scene.progression.theme == Pixel.THEME, "separate windows share pixel theme")
	check(scene.progression.reset_dialog.theme == Pixel.THEME and scene.progression.stage_choice.get_popup().theme == Pixel.THEME, "dialog and dropdown are themed")
	scene.progression.stage_choice.set_item_metadata(0, "preserve-popup-items")
	scene.progression.refresh(scene.game, scene.game_message, true)
	check(scene.progression.stage_choice.get_item_metadata(0) == "preserve-popup-items", "HUD refresh does not rebuild an unchanged floor dropdown")
	check(root.theme == Pixel.THEME, "root tooltips inherit pixel theme")
	check(Pixel.THEME.default_font.fixed_size_scale_mode == TextServer.FIXED_SIZE_SCALE_INTEGER_ONLY, "font uses integer bitmap scaling")
	check(Pixel.THEME.default_font.get_height(16) == 20 and Pixel.THEME.default_font.get_height(24) == 30, "font native metrics preserved")
	for type in ["Button", "CheckButton", "OptionButton"]:
		for state in ["normal", "hover", "pressed", "disabled", "focus"]:
			check(Pixel.THEME.has_stylebox(state, type), type + " style: " + state)
	for type in ["TabContainer", "TabBar"]:
		check(Pixel.THEME.has_stylebox("tab_selected", type) and Pixel.THEME.has_stylebox("tab_focus", type), type + " selection and focus")
	check(Pixel.THEME.has_stylebox("panel", "TooltipPanel") and Pixel.THEME.has_stylebox("panel", "AcceptDialog"), "tooltip and confirmation frames")
	for pet in scene.Game.PETS:
		check(Pixel.PET_TEXTURES[pet.id].get_size() == Vector2(32, 32), "pet assets share 32-pixel grid: " + pet.id)
		check(scene.progression.pet_rows[pet.id].icon.texture == Pixel.PET_TEXTURES[pet.id], "pet list shares companion artwork: " + pet.id)
	check(scene.enemy.texture.get_size() == Vector2(32, 32) and scene.enemy.scale == Vector2(2, 2), "enemy scales on integer grid")
	var odds_total := 0
	for odds in scene.Game.ODDS:
		odds_total += odds
	check(odds_total == 100, "styling preserves hatch odds")
	var menu: MenuButton = scene.actions_menu.get_parent()
	check(menu.get_rect().end.x <= 760 and menu.visible and scene.actions_menu.item_count == 5,
		"ambient strip keeps all actions behind a visible menu")
	scene.game.data.unlocked = 5
	scene.progression.refresh(scene.game, "", true)
	check(scene.progression.stage_choice.get_item_text(4).contains("Boss"), "floor picker labels boss")
	check(scene.progression.hero_xp.text.contains("XP"), "hero panel shows level progress")
	scene.game.data.gold = 0
	scene.game_message = "Save failed. Previous progress retained."
	scene._refresh_game_ui()
	check(scene.progression.hero_buttons.attack.disabled, "unaffordable action remains disabled")
	check(not scene.progression.result_icon.visible and scene.progression.notice.modulate == Color.WHITE, "errors clear stale rarity feedback")
	scene.game.data.gold = 1000000000000
	scene.game.data.eggs = 1000000000000
	scene.progression.refresh(scene.game, "Unable to save progress. Close the game and preserve the original file before resetting.", true)
	Pixel.fit_window(scene.progression, Vector2i(620, 620), Rect2i(0, 0, 1280, 640))
	Pixel.fit_window(scene.panel, Vector2i(440, 360), Rect2i(0, 0, 1280, 640))
	await process_frame
	await process_frame
	check(scene.progression.position.y >= 0 and scene.progression.position.y + scene.progression.size.y <= 640, "progression fits constrained work area")
	check(scene.panel.position.y >= 0 and scene.panel.position.y + scene.panel.size.y <= 640, "settings fits constrained work area")
	check(scene.progression.reset_button.get_global_rect().end.y <= scene.progression.size.y, "reset action remains inside panel")
	var settings_controls: VBoxContainer = scene.panel.get_meta("controls")
	check(settings_controls.get_node("Motion").text == "Combat animation", "settings controls retain readable labels")
	check(scene.progression.notice.text.contains("preserve the original"), "recovery instructions retain complete text")
	check(scene.progression.summary.text.contains("1000000000000"), "full resource value remains available")
	var catalog: Control = scene.progression.tabs.get_node("Items")
	scene.progression.tabs.current_tab = scene.progression.tabs.get_tab_idx_from_control(catalog)
	await process_frame
	var icons := catalog.find_children("ItemIcon", "TextureRect", true, false)
	check(catalog.visible and icons.size() == 18, "Items tab displays all 18 item icons")
	var atlas_cells := {}
	for icon: TextureRect in icons:
		var sprite := icon.texture as AtlasTexture
		check(sprite != null and sprite.get_size() == Vector2(24, 24), "item icon uses one 24-pixel cell")
		if sprite != null:
			var cell := sprite.atlas.get_image().get_region(Rect2i(sprite.region))
			check(cell.get_used_rect().has_area() and cell.get_pixel(0, 0).a == 0.0,
				"item art has an opaque foreground and transparent padding")
			atlas_cells[[sprite.atlas, sprite.region]] = true
	check(atlas_cells.size() == 18, "every item uses its own atlas cell")
	scene.progression.tabs.current_tab = 0
	await process_frame
	await process_frame
	var old_health: int = scene.game.data.upgrades.health
	scene.progression.hero_buttons.health.grab_focus()
	var accept := InputEventAction.new()
	accept.action = "ui_accept"
	accept.pressed = true
	scene.progression.push_input(accept)
	accept = InputEventAction.new()
	accept.action = "ui_accept"
	accept.pressed = false
	scene.progression.push_input(accept)
	check(scene.game.data.upgrades.health == old_health + 1, "keyboard activation reaches hero upgrade")
	if failures == 0:
		print("PASS: prototype UI hatch, equip, upgrades, stage, pause/resume, persistence, and compact layout.")
	scene.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)


func check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + label)
