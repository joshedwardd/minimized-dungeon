extends Window

signal action_requested(action: String, value: Variant)

const Game = preload("res://scripts/game.gd")
const Pixel = preload("res://ui/pixel_ui.gd")
const COLORS = Pixel.RARITIES
const ITEM_ICON_SIZE := 24
const ITEM_GROUPS := [
	{
		"title": "Equipment",
		"atlas": preload("res://assets/gemini/items-equipment-atlas.png"),
		"items": ["Iron sword", "Bronze shield", "Knight helmet", "Leather coat", "Ember ring", "Bell charm"],
	},
	{
		"title": "Consumables",
		"atlas": preload("res://assets/gemini/items-consumables-atlas.png"),
		"items": ["Healing flask", "Focus vial", "Speed tonic", "Recall scroll", "Ember lantern", "Cave mushrooms"],
	},
	{
		"title": "Crafting materials",
		"atlas": preload("res://assets/gemini/items-crafting-materials-atlas.png"),
		"items": ["Iron ore", "Copper shard", "Wisp crystal", "Moss fiber", "Rat fang", "Ember core"],
	},
]

var summary: Label
var hero_xp: Label
var notice: Label
var hero_buttons: Dictionary = {}
var pet_rows: Dictionary = {}
var hatch_button: Button
var stage_choice: OptionButton
var stage_note: Label
var reset_button: Button
var updating := false
var tabs: TabContainer
var reset_dialog: ConfirmationDialog
var result_icon: TextureRect
var result_row: HBoxContainer
var result_message := ""


func build(ui_theme: Theme) -> void:
	title = "Minimized Dungeon - Upgrades"
	size = Vector2i(620, 620)
	min_size = Vector2i(300, 200)
	theme = ui_theme
	unresizable = true
	always_on_top = true
	visible = false
	close_requested.connect(hide)
	var background := Panel.new()
	background.theme = ui_theme
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 20)
	add_child(margin)
	var box := VBoxContainer.new()
	box.theme = ui_theme
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)
	summary = _label(box, "", 24)
	var notice_scroll := ScrollContainer.new()
	notice_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	notice_scroll.custom_minimum_size.y = 64
	box.add_child(notice_scroll)
	result_row = HBoxContainer.new()
	result_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	notice_scroll.add_child(result_row)
	result_icon = TextureRect.new()
	result_icon.custom_minimum_size = Vector2(32, 32)
	result_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	result_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	result_icon.visible = false
	result_row.add_child(result_icon)
	notice = _label(result_row, "", 16)
	notice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice.custom_minimum_size.y = 44
	tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(tabs)
	var hero := _tab(tabs, "Hero")
	hero_xp = _label(hero, "", 24)
	_label(hero, "Each purchase improves one attribute. New stats start a new encounter.")
	for stat in Game.ATTRIBUTES:
		hero_buttons[stat] = _button(hero, "", func(): action_requested.emit("hero", stat))
		hero_buttons[stat].icon = Pixel.ATTRIBUTE_ICONS[stat]
	var pets := _tab(tabs, "Pets")
	_label(pets, "Hatch and choose a companion", 24)
	_label(pets, "One active pet. Duplicates add one pet level.")
	hatch_button = _button(pets, "", func(): action_requested.emit("hatch", null))
	hatch_button.icon = Pixel.EGG
	_label(pets, "Odds: Common 55% / Uncommon 25% / Rare 13% / Epic 6% / Legendary 1%", 16)
	for index in Game.PETS.size():
		var pet: Dictionary = Game.PETS[index]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		pets.add_child(row)
		var icon := TextureRect.new()
		icon.texture = Pixel.PET_TEXTURES[pet.id]
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(32, 32)
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		row.add_child(icon)
		var label := _label(row, "")
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.modulate = COLORS[index]
		var equip := _button(row, "Equip", func(): action_requested.emit("equip", pet.id))
		var upgrade := _button(row, "", func(): action_requested.emit("pet", pet.id))
		pet_rows[pet.id] = {"icon": icon, "label": label, "equip": equip, "upgrade": upgrade}
	var dungeon := _tab(tabs, "Dungeon")
	_label(dungeon, "The Rat Cellar", 24)
	_label(dungeon, "Clear a floor to unlock the next. Select harder floors manually.")
	stage_choice = OptionButton.new()
	stage_choice.custom_minimum_size.y = 40
	tabs.set_tab_icon(2, Pixel.DUNGEON_ICON)
	stage_choice.item_selected.connect(func(index: int):
		if not updating:
			action_requested.emit("stage", index + 1)
	)
	dungeon.add_child(stage_choice)
	stage_choice.get_popup().theme = ui_theme
	stage_choice.get_popup().prefer_native_menu = false
	stage_note = _label(dungeon, "")
	_label(dungeon, "Eggs: first clear of floor 1 and every fifth floor.\nRepeat victories: 10% egg chance.\nOffline: up to 8 hours of gold and XP; no eggs or floor unlocks.")
	_build_item_catalog(_tab(tabs, "Items"))
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	box.add_child(actions)
	_button(actions, "Close", hide)
	var reset := ConfirmationDialog.new()
	reset_dialog = reset
	reset.theme = ui_theme
	reset.title = "Reset local progress?"
	reset.dialog_text = "Start over? Existing saves will be kept as separate backup files."
	reset.get_label().autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reset.get_label().custom_minimum_size = Vector2(280, 0)
	reset.confirmed.connect(func(): action_requested.emit("reset", null))
	add_child(reset)
	reset_button = _button(actions, "Reset local progress...", func():
		Pixel.fit_window(reset, Vector2i(420, 240))
		reset.show()
	)


func _build_item_catalog(catalog: VBoxContainer) -> void:
	for group: Dictionary in ITEM_GROUPS:
		_label(catalog, group.title, 24)
		var entries := HFlowContainer.new()
		entries.add_theme_constant_override("h_separation", 12)
		entries.add_theme_constant_override("v_separation", 8)
		catalog.add_child(entries)
		for index: int in group.items.size():
			var entry := HBoxContainer.new()
			entry.custom_minimum_size.x = 148
			entry.add_theme_constant_override("separation", 8)
			entries.add_child(entry)

			var texture := AtlasTexture.new()
			texture.atlas = group.atlas
			texture.region = Rect2(
				index % 3 * ITEM_ICON_SIZE,
				floori(index / 3.0) * ITEM_ICON_SIZE,
				ITEM_ICON_SIZE,
				ITEM_ICON_SIZE
			)
			var icon := TextureRect.new()
			icon.name = "ItemIcon"
			icon.texture = texture
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.custom_minimum_size = Vector2(48, 48)
			entry.add_child(icon)

			var caption := _label(entry, group.items[index])
			caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func refresh(game: RefCounted, message: String, can_change: bool, can_reset: bool = true) -> void:
	reset_button.disabled = not can_reset
	var stats: Dictionary = game.attributes()
	summary.text = "%d gold  /  %d eggs  /  Floor %d" % [game.data.gold, game.data.eggs, game.data.stage]
	hero_xp.text = "Level %d  /  %d of %d XP" % [game.hero_level(), int(game.data.xp) % Game.XP_PER_LEVEL, Game.XP_PER_LEVEL]
	notice.text = message
	if message != result_message:
		clear_result()
	var gains := {"attack": "+2", "health": "+10", "defense": "+1", "speed": "+0.1/s"}
	for stat in hero_buttons:
		var cost: int = game.upgrade_cost(stat)
		hero_buttons[stat].text = "%s %.1f  |  %s  |  %d gold" % [stat.capitalize(), stats[stat], gains[stat], cost]
		hero_buttons[stat].disabled = not can_change or game.data.gold < cost or game.data.upgrades[stat] >= Game.MAX_LEVEL
	for index in Game.PETS.size():
		var pet: Dictionary = Game.PETS[index]
		var row: Dictionary = pet_rows[pet.id]
		var level := int(game.data.pets.get(pet.id, 0))
		row.label.text = "%s / %s\n%s" % [pet.name, Game.RARITIES[index],
			"Lv.%d  +%.2f %s" % [level, pet.bonus * level, pet.stat] if level > 0 else "Not hatched"]
		row.equip.text = "Active" if game.data.equipped == pet.id else "Equip"
		row.equip.disabled = not can_change or level == 0 or game.data.equipped == pet.id
		row.upgrade.text = "%d gold" % game.pet_cost(pet.id)
		row.upgrade.disabled = not can_change or level == 0 or game.data.gold < game.pet_cost(pet.id) or level >= Game.MAX_LEVEL
	hatch_button.text = "Hatch egg (%d available)" % game.data.eggs
	hatch_button.disabled = not can_change or game.data.eggs == 0
	updating = true
	if stage_choice.item_count != int(game.data.unlocked):
		stage_choice.clear()
		for stage in range(1, int(game.data.unlocked) + 1):
			stage_choice.add_item("Floor %d%s" % [stage, " · Boss" if Game.is_boss(stage) else ""])
	if stage_choice.selected != int(game.data.stage) - 1:
		stage_choice.select(int(game.data.stage) - 1)
	stage_choice.disabled = not can_change
	updating = false
	var fight: Dictionary = game.encounter()
	stage_note.text = "%s. Each victory earns %d gold and %d XP.\n%s" % [
		"Victory expected" if fight.won else "Defeat expected. Upgrade or farm an easier floor",
		fight.reward, game.data.stage,
		"Clear floor %d to unlock floor %d." % [game.data.unlocked, int(game.data.unlocked) + 1] if game.data.unlocked < Game.MAX_STAGE else "All floors unlocked."]


func show_hatch_result(result: Dictionary, message: String) -> void:
	result_message = message
	result_icon.texture = Pixel.PET_TEXTURES[result.id]
	result_icon.visible = true
	var index := Game.RARITIES.find(result.rarity)
	notice.modulate = COLORS[index]


func clear_result() -> void:
	result_message = ""
	result_icon.visible = false
	notice.modulate = Color.WHITE


func _tab(tabs: TabContainer, title_text: String) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.name = title_text
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 12)
	tabs.add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 12)
	scroll.add_child(box)
	return box


func _label(parent: Node, text: String, font_size: int = 16) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label


func _button(parent: Node, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 38
	button.pressed.connect(action)
	parent.add_child(button)
	return button
