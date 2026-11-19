extends SceneTree


func _initialize() -> void:
	call_deferred("run_checks")


func run_checks() -> void:
	var scene = load("res://tests/preview_desktop.gd").new()
	root.add_child(scene)
	scene.set_process(false)
	scene.game.data.equipped = "moss"
	scene.game.data.pets = {"moss": 1}
	scene._refresh_game_ui()
	var original: Dictionary = scene.game.data.duplicate(true)
	scene.game.data.remainder = 0.85
	scene._update_combat_presentation()
	assert(scene.knight.position.x < scene.HERO_POSITION.x)
	scene.game.data.remainder = 1.05
	scene._update_combat_presentation()
	assert(scene.slash.visible)
	assert(scene.knight.position.x > scene.HERO_POSITION.x)
	assert(scene.enemy.position.x > scene.ENEMY_POSITION.x)
	var active: Dictionary = scene.game.data.duplicate(true)
	scene._update_combat_presentation()
	assert(scene.game.data == active)
	scene.game.data.paused = true
	scene._update_combat_presentation()
	assert(not scene.slash.visible)
	assert(scene.knight.position == scene.HERO_POSITION)
	scene.game.data.paused = false
	var motion: CheckButton = scene.panel.get_meta("controls").get_node("Motion")
	motion.button_pressed = false
	assert(not scene.slash.visible and scene.knight.position == scene.HERO_POSITION)
	assert(scene.enemy.position == scene.ENEMY_POSITION and scene.companion.position == scene.PET_POSITION)
	scene.game.data.remainder = scene.game.encounter().fight_time
	scene._update_combat_presentation()
	assert(not scene.enemy.visible)
	scene.game.data.stage = 20
	scene.game.data.remainder = scene.game.encounter().fight_time
	scene._update_combat_presentation()
	assert(scene.enemy.visible and scene.knight.modulate != Color.WHITE)
	scene.game.data = original
	scene._update_combat_presentation()
	assert(scene.enemy.visible and scene.knight.modulate == Color.WHITE)
	var used: Rect2i = scene.KNIGHT.get_image().get_used_rect()
	var foot_y: float = scene.knight.position.y + (used.end.y - 24 + scene.knight.offset.y) * 2
	assert(foot_y == 112)
	for texture in scene.Pixel.PET_TEXTURES.values() + [scene.RAT]:
		var image: Image = texture.get_image()
		assert(image.get_size() == Vector2i(32, 32))
		for y in 32:
			for x in 32:
				assert(image.get_pixel(x, y).a == 0.0 or image.get_pixel(x, y).a == 1.0)
	print("PASS: attack/recovery poses, motion-off reset, shared crisp creature assets, grounded knight, and unchanged game state.")
	scene.queue_free()
	await process_frame
	quit()
