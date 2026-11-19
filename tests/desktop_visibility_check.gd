extends SceneTree


func _initialize() -> void:
	call_deferred("run_checks")


func run_checks() -> void:
	var scene = load("res://tests/preview_desktop.gd").new()
	root.add_child(scene)
	scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scene.hide_button.disabled = false
	scene._hide_strip()
	assert(not scene.is_processing())
	assert(not RenderingServer.render_loop_enabled)
	scene._restore_strip()
	assert(scene.is_processing())
	assert(RenderingServer.render_loop_enabled)
	print("PASS: hide/restore suspends and resumes presentation without changing main-window visibility.")
	scene.queue_free()
	await process_frame
	quit()
