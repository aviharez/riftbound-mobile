class_name ModalLayer
extends Control
## Base for modal screens on the UI layer: a dimmer + centered scrolling panel, and themed building blocks
## (labels, buttons, sliders, options, checks, tappable cards, gem icons, loadout slots). Built in code from UiTheme.

signal settings_changed

const PANEL_W := 246.0

var _root: Control


func _ready() -> void:
	theme = UiTheme.theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func is_open() -> bool:
	return _root != null


func close() -> void:
	if _root:
		_root.queue_free()
		_root = null


# ================================================================= building blocks

## Opens a fresh modal: dimmer + centered scrolling panel. Returns the content VBox.
func _open() -> VBoxContainer:
	close()
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	_root = root
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.03, 0.07, 0.8)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(PANEL_W, 0)
	panel.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 6)
	scroll.add_child(box)
	# Fit the panel to its content, capped to the screen height.
	box.resized.connect(func() -> void:
		var cap := get_viewport_rect().size.y - 24.0
		scroll.custom_minimum_size.y = minf(box.size.y, cap))
	return box


func _label(text: String, variation: String, wrap: bool = false) -> Label:
	# Titles and section headings are centred with gold flourishes (reference panels).
	var l: Label = FlourishLabel.new() if variation == "Heading" or variation == "Title" else Label.new()
	l.text = text
	if variation != "":
		l.theme_type_variation = variation
	if variation == "Eyebrow" or variation == "Title" or variation == "Heading":
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = PANEL_W - 24.0
	return l


func _button(text: String, variation: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	if variation != "":
		b.theme_type_variation = variation
	b.custom_minimum_size.y = 22.0
	b.pressed.connect(on_press)
	return b


func _slider(title: String, min_v: float, max_v: float, step: float, value: float, fmt: String, apply: Callable) -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 1)
	var row := HBoxContainer.new()
	var l := _label(title, "")
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	var out := _label(fmt % value, "Eyebrow")
	row.add_child(out)
	col.add_child(row)
	var s := HSlider.new()
	s.min_value = min_v
	s.max_value = max_v
	s.step = step
	s.value = value
	s.custom_minimum_size.y = 14.0
	s.value_changed.connect(func(v: float) -> void:
		out.text = fmt % v
		apply.call(v)
		settings_changed.emit())
	col.add_child(s)
	return col


func _option(title: String, items: Array[String], selected: int, apply: Callable) -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 1)
	col.add_child(_label(title, ""))
	var o := OptionButton.new()
	for it: String in items:
		o.add_item(it)
	o.select(selected)
	o.custom_minimum_size.y = 20.0
	o.item_selected.connect(func(i: int) -> void:
		apply.call(i)
		settings_changed.emit())
	col.add_child(o)
	return col


func _check(title: String, on: bool, apply: Callable) -> CheckBox:
	var c := CheckBox.new()
	c.text = title
	c.button_pressed = on
	c.toggled.connect(func(v: bool) -> void:
		apply.call(v)
		settings_changed.emit())
	return c


## A tappable card (level-up choice or fusion option).
func _card(color: Color, tag: String, title: String, desc: String, recipe: String, highlight: bool, on_press: Callable) -> Control:
	var panel := PanelContainer.new()
	var normal := UiTheme.box(Color("1b1b33"), UiTheme.GOLD if highlight else Color(UiTheme.GOLD, 0.55), 1, 6)
	var hover := UiTheme.box(Color("222244"), UiTheme.CYAN, 1, 6)
	panel.add_theme_stylebox_override("panel", normal)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.mouse_entered.connect(func() -> void: panel.add_theme_stylebox_override("panel", hover))
	panel.mouse_exited.connect(func() -> void: panel.add_theme_stylebox_override("panel", normal))
	panel.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT and not (ev as InputEventMouseButton).pressed:
			on_press.call())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(row)
	row.add_child(_gem_icon(color, 18.0))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 1)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(col)
	var tag_l := _label(tag.to_upper(), "Eyebrow")
	tag_l.add_theme_font_size_override("font_size", 6)
	tag_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	col.add_child(tag_l)
	col.add_child(_label(title, "CardTitle"))
	if recipe != "":
		var r := _label(recipe, "Small", true)
		r.custom_minimum_size.x = PANEL_W - 60.0
		col.add_child(r)
	var d := _label(desc, "", true)
	d.custom_minimum_size.x = PANEL_W - 60.0
	d.add_theme_font_size_override("font_size", 8)
	col.add_child(d)
	for c: Node in col.get_children():
		(c as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	return panel


## A resource icon (crystal / stone / medallion) on a small dark tile.
func _res_icon(i: int, size: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(size, size)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func() -> void:
		Icons.resource(c, i, c.custom_minimum_size * 0.5, c.custom_minimum_size.x / 12.0))
	return c


## Reward tiles (reference: "Victory rewards"): a framed tile per resource with a big icon, "+N" and its name.
func _reward_tiles(r: Vector3i) -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	var any := false
	for i in 3:
		if r[i] <= 0:
			continue
		any = true
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 1)
		var tile := PanelContainer.new()
		tile.add_theme_stylebox_override("panel", UiTheme.card(false, UiTheme.resource_colors()[i]))
		tile.custom_minimum_size = Vector2(52, 50)
		var inner := VBoxContainer.new()
		inner.alignment = BoxContainer.ALIGNMENT_CENTER
		var ic := _res_icon(i, 24.0)
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		inner.add_child(ic)
		var n := _label("+%d" % r[i], "CardTitle")
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		n.add_theme_color_override("font_color", UiTheme.PARCH)
		n.add_theme_font_size_override("font_size", 9)
		inner.add_child(n)
		tile.add_child(inner)
		col.add_child(tile)
		var name := _label(UiTheme.RESOURCE_NAMES[i], "Tiny")
		name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name.add_theme_color_override("font_color", UiTheme.MUTED)
		col.add_child(name)
		row.add_child(col)
	if not any:
		row.add_child(_label("Nothing this time", "Small"))
	return row


## A small diamond on a dark tile, drawn with a Control so it stays crisp at any scale.
func _gem_icon(color: Color, size: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(size, size)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func() -> void:
		c.draw_rect(Rect2(Vector2.ZERO, c.custom_minimum_size), UiTheme.INK_3)
		c.draw_rect(Rect2(Vector2.ZERO, c.custom_minimum_size), UiTheme.LINE, false, 1.0)
		var m := c.custom_minimum_size * 0.5
		var r := c.custom_minimum_size.x * 0.28
		c.draw_colored_polygon(PackedVector2Array([m + Vector2(0, -r), m + Vector2(r, 0), m + Vector2(0, r), m + Vector2(-r, 0)]), color))
	return c


## 4 ball slots + 4 item slots.
func _slots_view(loadout: Loadout) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.INK_3, UiTheme.LINE, 1, 4))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 3)
	panel.add_child(col)
	var ball_row := _slot_row("BALLS")
	for s: BallSlot in loadout.balls:
		if s:
			var lv := ("F·LV%d" % s.level) if s.fused else ("LV%d ×%d" % [s.level, s.count])
			ball_row.add_child(_slot_cell(s.glow_color, s.display_name, lv, s.level >= Registry.balance.max_level, s.fused))
		else:
			ball_row.add_child(_slot_cell(Color(0, 0, 0, 0), "empty", "", false, false))
	col.add_child(ball_row)
	var item_row := _slot_row("ITEMS")
	for it: ItemSlot in loadout.items:
		if it:
			item_row.add_child(_slot_cell(it.data.color, it.data.display_name, "LV%d" % it.level, it.level >= it.data.max_level, false))
		else:
			item_row.add_child(_slot_cell(Color(0, 0, 0, 0), "empty", "", false, false))
	col.add_child(item_row)
	return panel


func _slot_row(title: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	var l := _label(title, "Eyebrow")
	l.add_theme_font_size_override("font_size", 6)
	l.custom_minimum_size.x = 28.0
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(l)
	return row


func _slot_cell(color: Color, title: String, level_text: String, maxed: bool, fused: bool) -> Control:
	var cell := PanelContainer.new()
	var empty := color.a == 0.0
	var border := UiTheme.GOLD if fused else (Color(UiTheme.LINE, 0.6) if empty else UiTheme.LINE)
	cell.add_theme_stylebox_override("panel", UiTheme.box(Color("0b0b16"), border, 1, 2))
	cell.custom_minimum_size = Vector2(48, 32)
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 1)
	cell.add_child(col)
	if not empty:
		var icon := Control.new()
		icon.custom_minimum_size = Vector2(0, 8)
		icon.draw.connect(func() -> void:
			var m := Vector2(icon.size.x * 0.5, 4.0)
			icon.draw_colored_polygon(PackedVector2Array([m + Vector2(0, -3.5), m + Vector2(3.5, 0), m + Vector2(0, 3.5), m + Vector2(-3.5, 0)]), color))
		col.add_child(icon)
	var n := _label(title, "Tiny")
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	n.clip_text = true
	n.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	n.custom_minimum_size.x = 40.0
	if empty:
		n.add_theme_color_override("font_color", UiTheme.MUTED)
	col.add_child(n)
	if level_text != "":
		var lv := _label(level_text, "Eyebrow")
		lv.add_theme_font_size_override("font_size", 6)
		lv.add_theme_color_override("font_color", UiTheme.GOLD if maxed else UiTheme.CYAN)
		lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(lv)
	return cell


## Resource amounts as icon chips (Mana Shards, Ruins Materials, Ancient Relics). Zero amounts are hidden
## unless `show_zero`. With `have`, amounts the player can't afford turn red.
func _resource_row(r: Vector3i, plus: bool = false, have: Vector3i = Vector3i(-1, -1, -1), show_zero: bool = false) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var colors := UiTheme.resource_colors()
	var shown := 0
	for i in 3:
		var amount := r[i]
		if amount == 0 and not show_zero:
			continue
		shown += 1
		var chip := HBoxContainer.new()
		chip.add_theme_constant_override("separation", 3)
		chip.add_child(_res_icon(i, 12.0))
		var l := _label(("+%d" if plus else "%d") % amount, "CardTitle")
		if have.x >= 0 and have[i] < amount:
			l.add_theme_color_override("font_color", UiTheme.DANGER)
		else:
			l.add_theme_color_override("font_color", UiTheme.PARCH)
		l.tooltip_text = UiTheme.RESOURCE_NAMES[i]
		chip.add_child(l)
		var n := _label(UiTheme.RESOURCE_NAMES[i], "Tiny")
		n.add_theme_color_override("font_color", UiTheme.MUTED)
		n.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		chip.add_child(n)
		row.add_child(chip)
	if shown == 0:
		row.add_child(_label("Nothing", "Small"))
	return row
