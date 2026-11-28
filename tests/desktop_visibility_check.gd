extends SceneTree


func _initialize() -> void:
	call_deferred("run_checks")


func run_checks() -> void:
	var scene = load("res://tests/preview_desktop.gd").new()
	root.add_child(scene)
	scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scene.actions_menu.set_item_disabled(scene.MENU_HIDE, false)
	scene._hide_strip()
	assert(not scene.is_processing())
	assert(not RenderingServer.render_loop_enabled)
	scene._restore_strip()
	assert(scene.is_processing())
	assert(RenderingServer.render_loop_enabled)
	scene.strip_scale = 2
	scene.placement = 6
	var wide := Rect2i(-1920, 0, 1920, 1040)
	scene._apply_strip_layout(wide)
	assert(root.size == Vector2i(1520, 360) and root.position == Vector2i(-1528, 8))
	scene.transparent_enabled = true
	scene.use_transparency = true
	scene._update_hit_region()
	assert(root.mouse_passthrough_polygon[0] == Vector2(0, 32))
	var small := Rect2i(0, 0, 640, 480)
	scene._apply_strip_layout(small)
	assert(root.size.x == 640 and scene.scale_choice.is_item_disabled(1))
	assert(small.encloses(Rect2i(root.position, root.size)))
	print("PASS: hide/restore suspends and resumes presentation without changing main-window visibility.")
	scene.queue_free()
	await process_frame
	quit()
