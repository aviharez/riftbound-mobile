class_name Overlays
extends Control
## Modal screens on the UI layer: start, pause/settings, level up, fusion, game over.
## Built in code from UiTheme so layout stays consistent. Emits signals; Main owns the game flow.

signal start_pressed
signal resume_pressed
signal restart_pressed
signal card_chosen(card: LevelCard)
signal reroll_pressed
signal fusion_chosen(pair: Vector2i)
signal fusion_kept
signal open_fusion_pressed
signal again_pressed
signal settings_changed
signal debug_action(action: StringName)

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


# ================================================================= screens

func show_start() -> void:
	var box := _open()
	box.add_child(_label("Combat prototype · v0.4", "Eyebrow"))
	box.add_child(_label("Riftbound: Arcane Academy", "Title"))
	for line: String in [
		"Drag below the rune line to move. The finger doesn't need to touch Lyra.",
		"Touch or drag in the arena to aim. The angle stays locked when you let go.",
		"Balls fire on their own and come back. Catch a falling ball for a Perfect Catch.",
		"Balls absorb green gems (XP) and rainbow Rift Prisms on their way and deliver them when they return.",
		"4 ball slots + 4 item slots. Two Lv3 balls + a prism fuse into one, freeing a slot.",
		"Flame button: ultimate. II: pause, slots, settings.",
	]:
		box.add_child(_label("• " + line, "", true))
	box.add_child(_label("Desktop: WASD/arrows move, Q/E aim, Space ultimate, Esc pause.", "Small", true))
	box.add_child(_button("Start", "Primary", func() -> void: start_pressed.emit()))


func show_pause(battle: Battle, s: PlayerSettings) -> void:
	var box := _open()
	box.add_child(_label("Paused", "Title"))
	box.add_child(_slots_view(battle.loadout))
	var pairs := battle.fusion_pairs().size()
	var info := "Rift Prisms: %d" % battle.prisms
	if battle.prisms > 0:
		info += " · Lv3 balls ready to fuse" if pairs > 0 else " · needs two Lv3 balls to fuse"
	info += " · Mana Shards: %d" % battle.shards
	box.add_child(_label(info, "Small", true))
	if battle.can_fuse():
		box.add_child(_button("Open fusion", "", func() -> void: open_fusion_pressed.emit()))

	box.add_child(_label("Controls", "Heading"))
	box.add_child(_slider("Move sensitivity", 0.6, 2.5, 0.1, s.move_sensitivity, "%.1fx", func(v: float) -> void: s.move_sensitivity = v))
	var aim_modes: Array[String] = ["Absolute: aim at the touched spot", "Relative: drag left/right to rotate"]
	box.add_child(_option("Aim mode", aim_modes, 0 if s.aim_mode == PlayerSettings.AIM_ABSOLUTE else 1,
		func(i: int) -> void: s.aim_mode = PlayerSettings.AIM_ABSOLUTE if i == 0 else PlayerSettings.AIM_RELATIVE))
	box.add_child(_slider("Relative aim sensitivity", 0.2, 1.6, 0.1, s.aim_sensitivity, "%.1fx", func(v: float) -> void: s.aim_sensitivity = v))
	box.add_child(_slider("Zone line tolerance", 0.0, 30.0, 1.0, s.zone_tolerance, "%d px", func(v: float) -> void: s.zone_tolerance = v))
	var previews: Array[String] = ["To first contact", "+1 bounce", "+3 bounces"]
	var preview_values: Array[int] = [0, 1, 3]
	box.add_child(_option("Aim line", previews, maxi(0, preview_values.find(s.aim_preview_bounces)),
		func(i: int) -> void: s.aim_preview_bounces = preview_values[i]))
	box.add_child(_check("Show touches and zones", s.show_touches, func(on: bool) -> void: s.show_touches = on))
	box.add_child(_check("Screen shake", s.screen_shake, func(on: bool) -> void: s.screen_shake = on))
	box.add_child(_check("Damage numbers", s.damage_numbers, func(on: bool) -> void: s.damage_numbers = on))

	box.add_child(_label("Debug", "Heading"))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	for pair: Array in [["+10 baby balls", &"baby"], ["+1 level", &"level"], ["All balls Lv3", &"max_balls"], ["+1 prism", &"prism"], ["Fill ultimate", &"ultimate"], ["Restart run", &"restart"]]:
		var b := _button(pair[0], "", func() -> void: debug_action.emit(pair[1]))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(b)
	box.add_child(grid)
	box.add_child(_button("Resume", "Primary", func() -> void: resume_pressed.emit()))


func show_level_up(battle: Battle, cards: Array[LevelCard]) -> void:
	var box := _open()
	var eyebrow := _label("Level %d" % (battle.level - battle.pending_levels + 1), "Eyebrow")
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(eyebrow)
	var title := _label("Arcane Evolution", "Title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	box.add_child(_slots_view(battle.loadout))
	for card: LevelCard in cards:
		box.add_child(_card(card.color(), card.tag(), card.title(), card.description(Registry.balance), "", false,
			func() -> void: card_chosen.emit(card)))
	var reroll := _button("Reroll (%d)" % battle.rerolls, "", func() -> void: reroll_pressed.emit())
	reroll.disabled = battle.rerolls <= 0
	box.add_child(reroll)


func show_fusion(battle: Battle) -> void:
	var box := _open()
	var eyebrow := _label("Rift Prism", "Eyebrow")
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(eyebrow)
	var title := _label("Fusion", "Title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	box.add_child(_label("Merge two Lv3 balls. The result restarts at Lv1 and only gains stats. One slot becomes empty.", "Small", true))
	box.add_child(_slots_view(battle.loadout))
	for pair: Vector2i in battle.fusion_pairs():
		var a := battle.loadout.balls[pair.x]
		var b := battle.loadout.balls[pair.y]
		var r := battle.loadout.fusion_result(pair)
		var recipe := "%s Lv%d + %s Lv%d · becomes %d ball(s), Lv1" % [a.display_name, a.level, b.display_name, b.level, r.count]
		box.add_child(_card(r.glow_color, "Evolution · recipe" if r.evolved else "Fusion · combined effects", r.display_name, r.description, recipe, r.evolved,
			func() -> void: fusion_chosen.emit(pair)))
	box.add_child(_button("Keep prism for later", "", func() -> void: fusion_kept.emit()))


func show_game_over(battle: Battle) -> void:
	var box := _open()
	box.add_child(_label("Run over", "Eyebrow"))
	box.add_child(_label("The line has fallen", "Title"))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	var t := int(battle.run_time)
	for row: Array in [["Wave reached", str(battle.wave)], ["Level", str(battle.level)], ["Enemies defeated", str(battle.kills)],
			["Bosses defeated", str(battle.bosses)], ["Perfect catches", str(battle.catches)], ["Fusions", str(battle.fusions)],
			["Mana Shards", str(battle.shards)], ["Duration", "%d:%02d" % [floori(battle.run_time / 60.0), t % 60]]]:
		var k := _label(row[0], "")
		k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(k)
		var v := _label(row[1], "Eyebrow")
		v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		grid.add_child(v)
	box.add_child(grid)
	box.add_child(_slots_view(battle.loadout))
	box.add_child(_button("Play again", "Primary", func() -> void: again_pressed.emit()))


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
	var l := Label.new()
	l.text = text
	if variation != "":
		l.theme_type_variation = variation
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
	var tag_l := _label(tag.to_upper(), "Heading")
	tag_l.add_theme_font_size_override("font_size", 6)
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
	var l := _label(title, "Heading")
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
		var lv := _label(level_text, "Heading")
		lv.add_theme_font_size_override("font_size", 6)
		lv.add_theme_color_override("font_color", UiTheme.GOLD if maxed else UiTheme.CYAN)
		lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(lv)
	return cell
