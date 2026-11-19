extends SceneTree

const Game = preload("res://scripts/game.gd")
const Store = preload("res://scripts/progress_store.gd")
var failures := 0


func _initialize() -> void:
	var game = Game.new()
	check(Game.valid(game.data), "new state validates")
	check(game.advance(6).gold > 0, "fresh knight wins")
	check(game.data.eggs >= 1, "first milestone egg")
	var golden := int(game.data.gold)
	game.data.stage = 20
	game.data.unlocked = 20
	game.data.remainder = 0.0
	check(game.advance(60).gold == 0 and game.data.gold == golden, "defeat grants nothing")
	game = Game.new()
	check(not game.upgrade_hero("attack"), "reject unaffordable hero upgrade")
	game.data.gold = 100
	check(game.upgrade_hero("attack") and game.data.gold == 76 and game.data.upgrades.attack == 1, "purchase once")
	check(not game.upgrade_hero("invalid"), "reject unknown attribute")
	game.data.pets = {"moss": 2, "ember": 1}
	game.equip("moss")
	var original: Dictionary = game.attributes()
	for index in 20:
		game.equip("ember")
		game.equip("moss")
	check(game.attributes() == original and game.data.pets.moss == 2, "swaps never stack")
	check(game.upgrade_pet("ember") and game.attributes() == original, "unequipped upgrade")
	game.data.eggs = 1000
	var found := {}
	for index in 1000:
		var result: Dictionary = game.hatch()
		found[result.rarity] = true
	check(found.size() == 5 and game.data.eggs == 0 and game.hatch().is_empty(), "all rarities hatch and eggs consumed")
	check(Game.valid(game.data), "duplicate hatches preserve valid state")
	game = Game.new()
	game.data.paused = true
	game.advance(1000)
	check(game.data.gold == 0 and game.data.remainder == 0, "paused game earns nothing")
	game.data.checkpoint = 100.0
	check(game.settle(200).gold == 0, "paused offline earns nothing")
	game.data.paused = false
	game.data.checkpoint = 100.0
	check(game.settle(50).gold == 0, "negative clock earns nothing")
	game.data.checkpoint = 100.0
	var started := Time.get_ticks_usec()
	var offline: Dictionary = game.settle(43300.0)
	check(Time.get_ticks_usec() - started < 100000, "eight hour catchup under 100ms")
	check(offline.seconds == 28800.0 and offline.gold > 0 and game.data.unlocked == 1 and game.data.eggs == 0, "offline cap, no auto unlocks or eggs")
	check(game.settle(43300.0).gold == 0, "no duplicate settlement")
	game.data.pets = {"moss": 1, "ember": 1}
	game.equip("moss")
	var settled_gold: int = game.data.gold
	game.equip("ember")
	check(game.settle(43300).gold == 0 and game.data.gold == settled_gold, "swap cannot alter settled rewards")
	var slow = Game.new()
	var fast = Game.new()
	for index in 900:
		slow.advance(1.0 / 15)
	for index in 1800:
		fast.advance(1.0 / 30)
	check(slow.data.gold == fast.data.gold and slow.data.eggs == fast.data.eggs and slow.data.seed == fast.data.seed, "15 and 30 FPS equivalent")
	check(absf(slow.data.remainder - fast.data.remainder) < 0.001, "frame remainder equivalent")
	var invalid: Dictionary = game.data.duplicate(true)
	invalid.pets["alien"] = 1
	check(not Game.valid(invalid), "invalid pet rejected")
	invalid = Game.new().data
	invalid.equipped = "moss"
	check(not Game.valid(invalid), "unowned pet rejected")
	invalid = Game.new().data
	invalid.gold = -1
	check(not Game.valid(invalid), "negative gold rejected")
	invalid = Game.new().data
	invalid.upgrades.attack = INF
	check(not Game.valid(invalid), "nonfinite data rejected")
	check(not Game.valid({"version": 99}), "unsupported save rejected")
	_test_storage()
	if failures == 0:
		print("PASS: combat, purchases, pet swaps, all rarities, offline cap/idempotence, frame independence, validation, and save recovery.")
	quit(0 if failures == 0 else 1)


func _test_storage() -> void:
	var directory := ProjectSettings.globalize_path("res://.godot/md-check-" + str(Time.get_ticks_usec()))
	check(DirAccess.make_dir_recursive_absolute(directory) == OK, "test directory created")
	var store = Store.new()
	store.path = directory.path_join("progress.json")
	var game = Game.new()
	game.data.gold = 100
	game.data.pets = {"moss": 2}
	game.equip("moss")
	check(store.save_progress(game), "initial save")
	game.data.gold = 125
	check(store.save_progress(game), "replacement save with backup")
	var restored = Game.new()
	store.read_progress(restored)
	check(restored.data.gold == 125 and restored.data.equipped == "moss" and restored.data.pets.moss == 2, "save roundtrip")
	var file := FileAccess.open(store.path + ".tmp", FileAccess.WRITE)
	file.store_string("partial interrupted write")
	file.close()
	store.read_progress(restored)
	check(restored.data.gold == 125, "interrupted temp write preserves primary")
	file = FileAccess.open(store.path, FileAccess.WRITE)
	file.store_string("invalid")
	file.close()
	store.read_progress(restored)
	check(restored.data.gold == 100 and store.writable, "backup recovery")
	check(store.save_progress(restored), "recovered checkpoint durable")
	restored.data.checkpoint = 100.0
	var settled: Dictionary = restored.settle(160.0)
	check(settled.gold > 0 and store.save_progress(restored), "short absence persisted")
	var reopened = Game.new()
	store.read_progress(reopened)
	check(reopened.data.gold == restored.data.gold and reopened.settle(160.0).gold == 0, "settlement followed by restart is idempotent")
	file = FileAccess.open(store.path, FileAccess.WRITE)
	file.store_string('{"version":99}')
	file.close()
	store.read_progress(restored)
	check(not store.writable and not store.save_progress(restored), "future save preserved")
	check(FileAccess.get_file_as_string(store.path) == '{"version":99}', "future save unchanged")
	check(store.reset_progress(restored) and restored.data.gold == 0, "explicit reset preserves old files")
	var missing = Store.new()
	missing.path = directory.path_join("missing/progress.json")
	check(not missing.save_progress(game), "write failure reported")
	var first = Store.new()
	var second = Store.new()
	if first.acquire_lock():
		check(not second.acquire_lock(), "concurrent instance rejected")
		first.lock.stop()
	else:
		print("SKIP: loopback binding unavailable; single-instance OS check pending.")


func check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + label)
