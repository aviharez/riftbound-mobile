class_name AcademyHud
extends Control
## Academy UI layer: resource bar on top, building prompt, and the bottom navigation bar.
## Built from UiTheme. Emits signals; AcademyScreen decides what they do.

signal nav_pressed(tab: StringName)
signal prompt_pressed(building_id: StringName)

const TOP_H := 24.0
const NAV_H := 34.0

var _resources: HBoxContainer
var _prompt: Button
var _prompt_id: StringName = &""


func _ready() -> void:
	theme = UiTheme.theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var top := PanelContainer.new()
	top.add_theme_stylebox_override("panel", UiTheme.box(Color(UiTheme.INK, 0.92), Color(UiTheme.GOLD, 0.5), 0, 4))
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.custom_minimum_size.y = TOP_H
	add_child(top)
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 10)
	top.add_child(top_row)
	_resources = HBoxContainer.new()
	_resources.add_theme_constant_override("separation", 10)
	_resources.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(_resources)
	var title := Label.new()
	title.text = "ASTRALIS ACADEMY"
	title.theme_type_variation = "Heading"
	top_row.add_child(title)

	_prompt = Button.new()
	_prompt.theme_type_variation = "Primary"
	_prompt.custom_minimum_size = Vector2(160, 22)
	_prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.offset_top = -NAV_H - 34.0
	_prompt.offset_bottom = -NAV_H - 12.0
	_prompt.offset_left = -80.0
	_prompt.offset_right = 80.0
	_prompt.visible = false
	_prompt.pressed.connect(func() -> void: prompt_pressed.emit(_prompt_id))
	add_child(_prompt)

	var nav := PanelContainer.new()
	nav.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.INK, Color(UiTheme.GOLD, 0.5), 0, 2))
	nav.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	nav.offset_top = -NAV_H
	add_child(nav)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	nav.add_child(row)
	for tab: Array in [[&"academy", "Academy", true], [&"rift", "Rift", true], [&"characters", "Students", true], [&"expeditions", "Expedition", false], [&"stories", "Stories", false]]:
		var b := Button.new()
		b.text = tab[1] if tab[2] else "%s\nsoon" % tab[1]
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size.y = NAV_H - 4.0
		b.add_theme_font_size_override("font_size", 7)
		b.disabled = not tab[2]
		if tab[0] == &"academy":
			b.add_theme_stylebox_override("normal", UiTheme.box(Color("2b2b4a"), UiTheme.CYAN, 1, 2))
		var id: StringName = tab[0]
		b.pressed.connect(func() -> void: nav_pressed.emit(id))
		row.add_child(b)

	GameState.resources_changed.connect(refresh)
	refresh()


func refresh() -> void:
	for c: Node in _resources.get_children():
		c.queue_free()
	var colors := UiTheme.resource_colors()
	var amounts := GameState.resources()
	for i in 3:
		var chip := HBoxContainer.new()
		chip.add_theme_constant_override("separation", 3)
		var icon := Control.new()
		icon.custom_minimum_size = Vector2(9, 9)
		var col := colors[i]
		icon.draw.connect(func() -> void:
			var m := icon.size * 0.5
			icon.draw_colored_polygon(PackedVector2Array([m + Vector2(0, -4), m + Vector2(4, 0), m + Vector2(0, 4), m + Vector2(-4, 0)]), col))
		chip.add_child(icon)
		var l := Label.new()
		l.text = str(amounts[i])
		l.theme_type_variation = "CardTitle"
		l.add_theme_color_override("font_color", UiTheme.PARCH)
		l.tooltip_text = UiTheme.RESOURCE_NAMES[i]
		chip.add_child(l)
		_resources.add_child(chip)


## Shows "Enter <building>" above the nav bar while the avatar stands at a door.
func set_prompt(building_id: StringName) -> void:
	if building_id == _prompt_id:
		return
	_prompt_id = building_id
	if building_id == &"":
		_prompt.visible = false
		return
	var b: BuildingData = Registry.buildings[building_id]
	_prompt.text = ("Enter the Rift" if b.is_rift_gate else "Open %s" % b.display_name)
	_prompt.visible = true


## True when a screen position lands on the HUD (taps there must not move the avatar).
func covers(screen_pos: Vector2) -> bool:
	if screen_pos.y <= TOP_H or screen_pos.y >= size.y - NAV_H:
		return true
	return _prompt.visible and _prompt.get_global_rect().has_point(screen_pos)
