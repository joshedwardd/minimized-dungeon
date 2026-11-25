extends SceneTree

const FRAME = preload("res://assets/ui/frame.svg")
const PANEL_FRAME = preload("res://assets/gemini/panel-frame.png")
const TAB_FRAME = preload("res://assets/gemini/tab-frame.png")
const SELECTED_TAB_FRAME = preload("res://assets/gemini/selected-tab-frame.png")
const TOOLTIP_FRAME = preload("res://assets/gemini/tooltip-frame.png")
const FOCUS = preload("res://assets/ui/focus.svg")
const CHECK = preload("res://assets/ui/check.svg")
const ARROW = preload("res://assets/ui/arrow.svg")
const UP = preload("res://assets/ui/arrow-up.svg")
const LEFT = preload("res://assets/ui/arrow-left.svg")
const RIGHT = preload("res://assets/ui/arrow-right.svg")
const PAPER = Color("f0e6ce")
const GOLD = Color("e8c477")


func _initialize() -> void:
	var theme := Theme.new()
	theme.default_font = load("res://assets/ui/font/dungeon-pixel.fnt").duplicate()
	theme.default_font.fixed_size_scale_mode = TextServer.FIXED_SIZE_SCALE_INTEGER_ONLY
	var font_error := ResourceSaver.save(theme.default_font, "res://ui/pixel_font.tres", ResourceSaver.FLAG_CHANGE_PATH)
	if font_error != OK:
		push_error("Pixel font resource could not be saved.")
		quit(1)
		return
	theme.default_font_size = 16
	var normal := frame(TAB_FRAME)
	var hover := frame(TAB_FRAME, Color(1.25, 1.25, 1.2))
	var pressed := frame(SELECTED_TAB_FRAME)
	pressed.content_margin_top = 10
	pressed.content_margin_bottom = 6
	var disabled := frame(TAB_FRAME, Color(0.65, 0.7, 0.75))
	var focus := frame(FOCUS, Color.WHITE, 10, 4)
	var panel := frame(PANEL_FRAME, Color.WHITE, 16, 8)
	for type in ["Button", "OptionButton", "CheckButton", "CheckBox", "MenuButton"]:
		for state in ["normal", "hover", "pressed", "disabled", "focus", "hover_pressed"]:
			var styles := {"normal": normal, "hover": hover, "pressed": pressed,
				"disabled": disabled, "focus": focus, "hover_pressed": hover}
			theme.set_stylebox(state, type, styles[state])
		for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
			theme.set_color(key, type, PAPER)
		theme.set_color("font_disabled_color", type, Color("a3b1b5"))
		theme.set_constant("outline_size", type, 0)
		theme.set_constant("h_separation", type, 10)
	for type in ["CheckButton", "CheckBox"]:
		for state in ["checked", "checked_disabled", "radio_checked", "radio_checked_disabled"]:
			theme.set_icon(state, type, CHECK)
		for state in ["unchecked", "unchecked_disabled", "radio_unchecked", "radio_unchecked_disabled"]:
			theme.set_icon(state, type, FRAME)
	theme.set_icon("arrow", "OptionButton", ARROW)
	for type in ["Label", "RichTextLabel", "TooltipLabel"]:
		theme.set_color("font_color", type, PAPER)
		theme.set_color("default_color", type, PAPER)
		theme.set_constant("outline_size", type, 0)
		theme.set_constant("line_spacing", type, 4)
	for type in ["Panel", "PanelContainer", "TooltipPanel", "PopupPanel", "PopupMenu", "AcceptDialog"]:
		theme.set_stylebox("panel", type, panel)
	theme.set_stylebox("panel", "TooltipPanel", frame(TOOLTIP_FRAME))
	theme.set_stylebox("embedded_border", "Window", panel)
	theme.set_stylebox("embedded_unfocused_border", "Window", panel)
	theme.set_color("title_color", "Window", PAPER)
	theme.set_color("title_outline_modulate", "Window", Color.TRANSPARENT)
	theme.set_constant("title_height", "Window", 28)
	for type in ["TabBar", "TabContainer"]:
		for state in ["tab_unselected", "tab_hovered", "tab_selected", "tab_disabled", "tab_focus"]:
			theme.set_stylebox(state, type, {"tab_unselected": normal, "tab_hovered": hover,
				"tab_selected": pressed, "tab_disabled": disabled, "tab_focus": focus}[state])
		for key in ["font_selected_color", "font_unselected_color", "font_hovered_color", "font_focus_color"]:
			theme.set_color(key, type, PAPER)
		theme.set_color("font_disabled_color", type, Color("a3b1b5"))
		theme.set_constant("outline_size", type, 0)
		theme.set_constant("side_margin", type, 4)
	theme.set_stylebox("panel", "TabContainer", panel)
	theme.set_stylebox("hover", "PopupMenu", hover)
	theme.set_stylebox("separator", "PopupMenu", normal)
	for key in ["font_color", "font_hover_color", "font_accelerator_color"]:
		theme.set_color(key, "PopupMenu", PAPER)
	theme.set_color("font_disabled_color", "PopupMenu", Color("a3b1b5"))
	theme.set_constant("v_separation", "PopupMenu", 12)
	for type in ["VScrollBar", "HScrollBar"]:
		theme.set_stylebox("scroll", type, panel)
		theme.set_stylebox("scroll_focus", type, focus)
		theme.set_stylebox("grabber", type, normal)
		theme.set_stylebox("grabber_highlight", type, hover)
		theme.set_stylebox("grabber_pressed", type, pressed)
		for key in ["increment", "increment_highlight", "increment_pressed", "decrement", "decrement_highlight", "decrement_pressed"]:
			var increment: bool = key.begins_with("increment")
			var icon: Texture2D = (ARROW if increment else UP) if type == "VScrollBar" else (RIGHT if increment else LEFT)
			theme.set_icon(key, type, icon)
	theme.set_stylebox("focus", "ScrollContainer", focus)
	theme.set_constant("scrollbar_h_separation", "ScrollContainer", 8)
	theme.set_constant("scrollbar_v_separation", "ScrollContainer", 8)
	var error := ResourceSaver.save(theme, "res://ui/pixel_theme.tres")
	if error != OK:
		push_error("Theme build failed: " + error_string(error))
		quit(1)
		return
	for code in range(32, 127):
		assert(theme.default_font.has_char(code))
	print("Pixel theme built; all printable ASCII glyphs are available.")
	quit()


func frame(texture: Texture2D, tint := Color.WHITE, padding := 10.0, edge := 5.0) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.modulate_color = tint
	style.texture_margin_left = edge
	style.texture_margin_right = edge
	style.texture_margin_top = edge
	style.texture_margin_bottom = edge
	style.content_margin_left = padding
	style.content_margin_right = padding
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style
