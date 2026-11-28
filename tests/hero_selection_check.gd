extends SceneTree

const Preview = preload("res://tests/preview_desktop.gd")


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var timeout := create_timer(12)
	timeout.timeout.connect(func(): quit(1))
	var scene := Preview.new()
	root.add_child(scene)
	scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var path := ProjectSettings.globalize_path("res://.godot/hero-check-%d.json" % Time.get_ticks_usec())
	scene.store.path = path + "/invalid"
	scene.can_play = false
	scene.first_run = true
	scene._open_hero_selection()
	await process_frame
	var picker = scene.hero_selection
	var hero_textures := {}
	for id: String in scene.Game.HEROES:
		var texture: Texture2D = scene.HeroSelection.art(id)
		assert(texture != scene.KNIGHT and texture.get_size() == Vector2(48, 48))
		var sprite := texture.get_image()
		assert(sprite.get_used_rect().end.y == 45 and sprite.get_pixel(0, 0).a == 0.0)
		assert(not hero_textures.has(texture))
		hero_textures[texture] = true
	assert(picker.visible and picker.welcome.visible and not picker.picker.visible)
	assert(not FileAccess.file_exists(path) and scene.game.data.wins == 0)
	picker.start.pressed.emit()
	await process_frame
	assert(picker.picker.visible and not picker.welcome.visible and picker.back.visible)
	if DisplayServer.get_name() != "headless":
		assert(picker.choices.iron_warden.has_focus())
		assert(scene._work_area().encloses(Rect2i(picker.position, picker.size)))
		assert(picker.enter.get_global_rect().end.y <= picker.size.y)
	picker.back.pressed.emit()
	picker.start.pressed.emit()
	picker.choices.cinder_keeper.pressed.emit()
	assert(picker.choices.cinder_keeper.button_pressed and not picker.choices.iron_warden.button_pressed)
	var original: Dictionary = scene.game.attributes()
	picker.enter.pressed.emit()
	assert(picker.visible and scene.first_run and not scene.can_play and picker.announcement.text.contains("Cannot write"))
	scene.store.path = path
	picker.enter.pressed.emit()
	assert(not picker.visible and not scene.first_run and scene.can_play)
	assert(scene.game.data.hero == "cinder_keeper" and scene.game.attributes() == original)
	var restored = scene.Game.new()
	scene.store.read_progress(restored)
	assert(restored.data.hero == "cinder_keeper")
	scene._open_hero_selection()
	assert(picker.picker.visible and not picker.back.visible)
	picker.choices.moss_runner.pressed.emit()
	picker.enter.pressed.emit()
	assert(scene.game.data.hero == "moss_runner" and scene.game.attributes() == original)
	assert(scene.knight.texture == picker.preview.texture)
	assert(DirAccess.remove_absolute(path) == OK)
	assert(DirAccess.remove_absolute(path + ".bak") == OK)
	scene.queue_free()
	await process_frame
	print("PASS: welcome, picker, save failure and retry, reload, and appearance-only changes.")
	quit()
