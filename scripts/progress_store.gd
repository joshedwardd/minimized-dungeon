extends RefCounted

const Game = preload("res://scripts/game.gd")
const LOCK_PORT := 43871

var path := "user://progress.json"
var writable := true
var message := ""
var lock := TCPServer.new()


func acquire_lock() -> bool:
	return lock.listen(LOCK_PORT, "127.0.0.1") == OK


func read_progress(game: RefCounted) -> void:
	if not FileAccess.file_exists(path):
		if FileAccess.file_exists(path + ".bak"):
			_restore_backup(game)
		return
	var raw: Variant = _read(path)
	var version: Variant = raw.get("version", 1) if raw is Dictionary else 1
	if version != 1 and version != Game.SAVE_VERSION:
		writable = false
		message = "Save version is unsupported. Original retained. Close the game and back up progress.json before resetting."
		return
	if Game.valid(raw):
		_load_progress(game, raw)
		return
	_restore_backup(game)


func _restore_backup(game: RefCounted) -> void:
	var raw: Variant = _read(path + ".bak")
	if Game.valid(raw):
		var retained := path + ".invalid-" + str(Time.get_ticks_usec())
		if FileAccess.file_exists(path) and DirAccess.rename_absolute(path, retained) != OK:
			writable = false
			message = "Cannot preserve the invalid save. Close the game and back up progress.json before resetting."
			return
		_load_progress(game, raw)
		message = "Recovered backup. The invalid save was retained separately."
	else:
		writable = false
		message = "No valid save found. Original files retained. Close the game and back them up before resetting."


func _load_progress(game: RefCounted, raw: Dictionary) -> void:
	if raw.version == 1:
		raw.version = Game.SAVE_VERSION
		raw.xp = 0
		if Game.is_boss(int(raw.stage)):
			raw.remainder = 0.0
	game.data = raw


func _archive_v1(source: String) -> bool:
	var archive := path + ".v1"
	if FileAccess.file_exists(archive):
		var retained: Variant = _read(archive)
		return Game.valid(retained) and retained.version == 1
	var temporary := archive + ".tmp"
	return DirAccess.copy_absolute(source, temporary) == OK and DirAccess.rename_absolute(temporary, archive) == OK


func save_progress(game: RefCounted) -> bool:
	if not writable:
		return false
	if not Game.valid(game.data) or game.data.version != Game.SAVE_VERSION:
		message = "Progress validation failed; previous save retained."
		return false
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		message = "Cannot write progress: " + error_string(FileAccess.get_open_error())
		return false
	file.store_string(JSON.stringify(game.data))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK or not Game.valid(_read(temporary)):
		message = "Progress write failed; previous save retained."
		return false
	var has_primary := FileAccess.file_exists(path)
	var source := path if has_primary else path + ".bak"
	var previous: Variant = _read(source)
	if has_primary and not Game.valid(previous):
		writable = false
		message = "Save changed unexpectedly. Original retained; restart to recover."
		return false
	if previous is Dictionary and previous.get("version") == 1 and Game.valid(previous) and not _archive_v1(source):
		message = "Cannot preserve the version 1 save. Previous progress retained."
		return false
	if has_primary:
		error = DirAccess.copy_absolute(path, path + ".bak")
		if error != OK:
			message = "Cannot preserve previous progress: " + error_string(error)
			return false
	error = DirAccess.rename_absolute(temporary, path)
	if error != OK:
		message = "Cannot replace progress: " + error_string(error)
		return false
	return true


func reset_progress(game: RefCounted) -> bool:
	var tag := ".reset-" + str(Time.get_unix_time_from_system()).replace(".", "-")
	for suffix in ["", ".bak"]:
		if FileAccess.file_exists(path + suffix):
			if DirAccess.rename_absolute(path + suffix, path + suffix + tag) != OK:
				writable = false
				message = "Cannot preserve existing saves. Reset cancelled."
				return false
	game.data = Game.new().data
	game.data.checkpoint = Time.get_unix_time_from_system()
	writable = true
	return save_progress(game)


func _read(filename: String) -> Variant:
	var file := FileAccess.open(filename, FileAccess.READ)
	if file == null or file.get_length() > 65536:
		return null
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return null
	return parser.data
