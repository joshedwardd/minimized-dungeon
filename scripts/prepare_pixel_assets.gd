extends SceneTree


func _initialize() -> void:
	var source_dir := "res://assets/prototype"
	var output_dir := "res://assets/ui/prototype"
	var error := DirAccess.make_dir_recursive_absolute(output_dir)
	if error != OK:
		push_error("Cannot create normalized asset directory: " + error_string(error))
		quit(1)
		return
	var count := 0
	for filename in DirAccess.get_files_at(source_dir):
		if not filename.ends_with(".png"):
			continue
		var source := Image.load_from_file(ProjectSettings.globalize_path(source_dir.path_join(filename)))
		if source == null or source.get_size() != Vector2i(128, 128):
			push_error("Expected a 128x128 prototype export: " + filename)
			quit(1)
			return
		var normalized := source.duplicate() as Image
		normalized.resize(32, 32, Image.INTERPOLATE_NEAREST)
		var restored := normalized.duplicate() as Image
		restored.resize(128, 128, Image.INTERPOLATE_NEAREST)
		if restored.get_data() != source.get_data():
			push_error("Image is not an exact pre-upscaled 32x32 grid: " + filename)
			quit(1)
			return
		error = normalized.save_png(output_dir.path_join(filename))
		if error != OK:
			push_error("Cannot save normalized image: " + filename)
			quit(1)
			return
		count += 1
	print("Normalized %d images; exact reconstruction checks passed." % count)
	quit()
