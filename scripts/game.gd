extends RefCounted

const SAVE_VERSION := 2
const XP_PER_LEVEL := 100
const LEVEL_GOLD := 50
const MAX_STAGE := 20
const MAX_LEVEL := 10000
const OFFLINE_CAP := 28800.0
const LIMIT := 1000000000000
const ATTRIBUTES := ["attack", "health", "defense", "speed"]
const RARITIES := ["Common", "Uncommon", "Rare", "Epic", "Legendary"]
const ODDS := [55, 25, 13, 6, 1]
const DEFAULT_HERO := "iron_warden"
const HEROES := {
	"iron_warden": {"name": "Iron Warden", "tint": Color.WHITE,
		"description": "Slate plate, a brass visor, and a steady guard."},
	"moss_runner": {"name": "Moss Runner", "tint": Color("aad294"),
		"description": "A moss cloak and a curved blade for tight tunnels."},
	"cinder_keeper": {"name": "Cinder Keeper", "tint": Color("fbaf81"),
		"description": "An ash cloak and a lantern for the lowest floors."},
}
const PETS := [
	{"id": "moss", "name": "Moss Turtle", "stat": "health", "bonus": 8.0, "icon": "turtle-shell-charm"},
	{"id": "ember", "name": "Ember Finch", "stat": "attack", "bonus": 2.0, "icon": "phoenix-feather"},
	{"id": "swift", "name": "Swift Rabbit", "stat": "speed", "bonus": 0.15, "icon": "rabbits-foot"},
	{"id": "stone", "name": "Stone Owl", "stat": "defense", "bonus": 4.0, "icon": "owl-totem"},
	{"id": "wisp", "name": "Astral Wisp", "stat": "attack", "bonus": 10.0, "icon": "mind-sigil"},
]

var data: Dictionary


func _init() -> void:
	data = {
		"version": SAVE_VERSION, "gold": 0, "xp": 0, "hero": DEFAULT_HERO, "stage": 1, "unlocked": 1, "eggs": 0,
		"wins": 0, "remainder": 0.0, "paused": false, "checkpoint": 0.0,
		"upgrades": {"attack": 0, "health": 0, "defense": 0, "speed": 0},
		"pets": {}, "equipped": "", "milestones": [], "seed": 73517,
	}


func attributes() -> Dictionary:
	var upgrades: Dictionary = data.upgrades
	var result := {"attack": 8.0 + upgrades.attack * 2.0,
		"health": 40.0 + upgrades.health * 10.0,
		"defense": 1.0 + upgrades.defense, "speed": 1.0 + upgrades.speed * 0.1}
	for pet in PETS:
		if pet.id == data.equipped:
			result[pet.stat] += pet.bonus * int(data.pets[pet.id])
	return result


static func is_boss(stage: int) -> bool:
	return stage % 5 == 0


func hero_level() -> int:
	return 1 + floori(float(data.xp) / XP_PER_LEVEL)


func encounter(legacy: bool = false) -> Dictionary:
	var stats := attributes()
	var hp := 16.0 + int(data.stage) * 12.0
	var armor := floori(int(data.stage) / 3.0)
	var base_damage := 3.0 + int(data.stage) * 2.0
	if not legacy and is_boss(int(data.stage)):
		hp *= 1.5
		base_damage *= 1.25
	var enemy_damage := maxf(1.0, base_damage - stats.defense)
	var hero_damage := maxf(1.0, stats.attack - armor)
	var kill_time: float = ceilf(hp / hero_damage) / stats.speed
	var death_time := ceilf(stats.health / enemy_damage) / 0.8
	var won: bool = kill_time <= death_time
	var fight_time: float = kill_time if won else death_time
	return {"won": won, "duration": fight_time + (1.0 if won else 3.0),
		"fight_time": fight_time, "hp": hp, "kill_time": kill_time,
		"death_time": death_time, "reward": int(data.stage) * 8}


func advance(seconds: float, offline: bool = false) -> Dictionary:
	var result := {"gold": 0, "eggs": 0, "wins": 0, "battles": 0, "xp": 0, "levels": 0, "seconds": 0.0}
	if data.paused or seconds <= 0.0 or not is_finite(seconds):
		return result
	result.seconds = minf(seconds, OFFLINE_CAP)
	var fight := encounter()
	var total := float(data.remainder) + float(result.seconds)
	var count := floori((total + 0.000001) / fight.duration)
	data.remainder = maxf(0.0, total - count * fight.duration)
	result.battles = count
	if count == 0 or not fight.won:
		return result
	result.wins = count
	var previous_level := hero_level()
	result.xp = mini(LIMIT - int(data.xp), count * int(data.stage))
	data.xp += result.xp
	result.levels = hero_level() - previous_level
	result.gold = mini(LIMIT - int(data.gold), count * int(fight.reward) + int(result.levels) * LEVEL_GOLD)
	data.gold += result.gold
	data.wins = mini(LIMIT, int(data.wins) + count)
	if not offline:
		data.unlocked = maxi(int(data.unlocked), mini(MAX_STAGE, int(data.stage) + 1))
		var stage := int(data.stage)
		if stage == 1 or is_boss(stage):
			if not data.milestones.any(func(cleared): return int(cleared) == stage):
				data.milestones.append(stage)
				result.eggs += 1
		for _index in count:
			if _roll() < 0.1:
				result.eggs += 1
		data.eggs = mini(LIMIT, int(data.eggs) + result.eggs)
	return result


func settle(now: float) -> Dictionary:
	var elapsed := clampf(now - float(data.checkpoint), 0.0, OFFLINE_CAP) if data.checkpoint > 0 else 0.0
	var result := advance(elapsed, true)
	data.checkpoint = now
	result.seconds = elapsed
	return result


func upgrade_cost(stat: String) -> int:
	return 24 * (int(data.upgrades.get(stat, 0)) + 1)


func upgrade_hero(stat: String) -> bool:
	if not ATTRIBUTES.has(stat) or int(data.upgrades[stat]) >= MAX_LEVEL or data.gold < upgrade_cost(stat):
		return false
	data.gold -= upgrade_cost(stat)
	data.upgrades[stat] += 1
	data.remainder = 0.0
	return true


func pet_cost(id: String) -> int:
	return 20 * (int(data.pets.get(id, 0)) + 1)


func upgrade_pet(id: String) -> bool:
	if not data.pets.has(id) or int(data.pets[id]) >= MAX_LEVEL or data.gold < pet_cost(id):
		return false
	data.gold -= pet_cost(id)
	data.pets[id] += 1
	if data.equipped == id:
		data.remainder = 0.0
	return true


func equip(id: String) -> bool:
	if not data.pets.has(id):
		return false
	if data.equipped != id:
		data.equipped = id
		data.remainder = 0.0
	return true


func select_stage(stage: int) -> bool:
	if stage < 1 or stage > data.unlocked:
		return false
	data.stage = stage
	data.remainder = 0.0
	return true


func hatch() -> Dictionary:
	if data.eggs < 1:
		return {}
	data.eggs -= 1
	var roll := _roll() * 100.0
	var chosen := PETS.size() - 1
	for index in ODDS.size():
		roll -= ODDS[index]
		if roll < 0:
			chosen = index
			break
	var pet: Dictionary = PETS[chosen]
	var duplicate: bool = data.pets.has(pet.id)
	data.pets[pet.id] = mini(MAX_LEVEL, int(data.pets.get(pet.id, 0)) + 1)
	if data.equipped == pet.id:
		data.remainder = 0.0
	return {"id": pet.id, "name": pet.name, "rarity": RARITIES[chosen], "duplicate": duplicate}


func _roll() -> float:
	data.seed = (int(data.seed) * 48271) % 2147483647
	return float(data.seed) / 2147483647.0


static func valid(raw: Variant) -> bool:
	if not raw is Dictionary:
		return false
	for key in ["version", "gold", "stage", "unlocked", "eggs", "wins", "remainder", "paused",
		"checkpoint", "upgrades", "pets", "equipped", "milestones", "seed"]:
		if not raw.has(key):
			return false
	if not _integer(raw.version, 1, SAVE_VERSION) or not _integer(raw.gold, 0, LIMIT) or not _integer(raw.eggs, 0, LIMIT):
		return false
	if not HEROES.has(raw.get("hero", DEFAULT_HERO)):
		return false
	if raw.version == SAVE_VERSION and not _integer(raw.get("xp"), 0, LIMIT):
		return false
	if not _integer(raw.stage, 1, MAX_STAGE) or not _integer(raw.unlocked, raw.stage, MAX_STAGE):
		return false
	if not _integer(raw.wins, 0, LIMIT) or not _integer(raw.seed, 1, 2147483646):
		return false
	if not _number(raw.remainder, 0.0, OFFLINE_CAP) or not _number(raw.checkpoint, 0.0, 100000000000.0):
		return false
	if not raw.paused is bool or not raw.equipped is String or not raw.upgrades is Dictionary or not raw.pets is Dictionary:
		return false
	if raw.upgrades.size() != ATTRIBUTES.size():
		return false
	for stat in ATTRIBUTES:
		if not raw.upgrades.has(stat) or not _integer(raw.upgrades[stat], 0, MAX_LEVEL):
			return false
	var ids := []
	for pet in PETS:
		ids.append(pet.id)
	for id in raw.pets:
		if not ids.has(id) or not _integer(raw.pets[id], 1, MAX_LEVEL):
			return false
	if raw.equipped != "" and not raw.pets.has(raw.equipped):
		return false
	if not raw.milestones is Array or raw.milestones.size() > MAX_STAGE:
		return false
	var seen := []
	for stage in raw.milestones:
		if not _integer(stage, 1, MAX_STAGE) or seen.has(int(stage)):
			return false
		seen.append(int(stage))
	var game = load("res://scripts/game.gd").new()
	game.data = raw.duplicate(true)
	return float(raw.remainder) < float(game.encounter(raw.version == 1).duration) + 0.00001


static func _number(value: Variant, minimum: float, maximum: float) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value >= minimum and value <= maximum


static func _integer(value: Variant, minimum: float, maximum: float) -> bool:
	return _number(value, minimum, maximum) and float(value) == floorf(float(value))
