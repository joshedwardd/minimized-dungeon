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
	_test_progression()
	_test_storage()
	if failures == 0:
		print("PASS: combat, XP and bosses, upgrades, pets, offline rewards, frame independence, validation, migration, and save recovery.")
	quit(0 if failures == 0 else 1)


func _test_progression() -> void:
	var game = Game.new()
	game.data.upgrades.attack = 8
	for stage in range(1, 5):
		check(game.select_stage(stage), "previous floor unlocks floor %d" % stage)
		check(game.advance(game.encounter().duration).wins == 1, "regular floor victory")
	check(game.select_stage(5), "floor 4 opens the first boss")
	check(game.encounter().hp == game.encounter(true).hp * 1.5, "boss health scales")
	game.data.upgrades.attack = 0
	var defeated: Dictionary = game.advance(game.encounter().duration)
	check(defeated.battles == 1 and defeated.xp == 0 and game.data.unlocked == 5, "boss defeat grants no rewards or unlock")
	check(game.select_stage(1) and game.advance(game.encounter().duration).xp == 1, "retreat earns XP")
	game.data.upgrades.attack = 20
	game.select_stage(5)
	var cleared: Dictionary = game.advance(game.encounter().duration)
	check(cleared.xp == 5 and cleared.eggs >= 1 and game.data.unlocked == 6, "boss clear earns XP and milestone egg")
	var split = Game.new()
	split.data = game.data.duplicate(true)
	var duration: float = game.encounter().duration
	var batch: Dictionary = game.advance(duration * 50, true)
	var split_gold := 0
	for index in 50:
		split_gold += int(split.advance(duration, true).gold)
	check(batch.levels >= 2 and batch.gold == 50 * 40 + int(batch.levels) * Game.LEVEL_GOLD, "one advance awards every level bonus")
	check(batch.gold == split_gold and game.data.xp == split.data.xp, "XP and gold are independent of update size")


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
	var migration = Store.new()
	migration.path = directory.path_join("old-progress.json")
	var old: Dictionary = Game.new().data
	old.version = 1
	old.erase("xp")
	old.erase("hero")
	old.stage = 5
	old.unlocked = 7
	old.remainder = 0.5
	old.gold = 123
	old.pets = {"moss": 2}
	old.equipped = "moss"
	old.milestones = [1, 5]
	var original := JSON.stringify(old)
	for source in [migration.path, migration.path + ".bak"]:
		file = FileAccess.open(source, FileAccess.WRITE)
		file.store_string(original)
		file.close()
		migration.read_progress(restored)
		check(restored.data.version == 2 and restored.data.xp == 0 and restored.data.remainder == 0, "v1 boss encounter resets on migration")
		check(restored.data.unlocked == 7 and restored.data.gold == 123 and restored.data.equipped == "moss" and restored.data.milestones.map(func(floor_number): return int(floor_number)) == [1, 5], "v1 progress preserved")
		check(migration.save_progress(restored) and FileAccess.get_file_as_string(migration.path + ".v1") == original, "v1 primary or backup archived")
		restored.data.upgrades.attack = 20
		check(restored.advance(restored.encounter().duration).eggs == 0, "migrated boss milestone does not award another first-clear egg")
		check(DirAccess.remove_absolute(migration.path) == OK, "remove migration test fixture")
		check(DirAccess.remove_absolute(migration.path + ".v1") == OK, "remove archive test fixture")
	old.stage = 2
	file = FileAccess.open(migration.path, FileAccess.WRITE)
	file.store_string(JSON.stringify(old))
	file.close()
	migration.read_progress(restored)
	check(restored.data.remainder == 0.5, "v1 regular encounter retains elapsed time")
	file = FileAccess.open(migration.path + ".v1", FileAccess.WRITE)
	file.store_string("invalid existing archive")
	file.close()
	check(not migration.save_progress(restored) and JSON.parse_string(FileAccess.get_file_as_string(migration.path)).version == 1, "archive failure preserves the v1 primary")
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
