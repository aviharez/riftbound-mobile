class_name AcademyOverlays
extends ModalLayer
## Academy modal screens: building details with repair/upgrade, the Rift Gate entrance,
## and the student roster / profile / "a student joined" notice.

signal upgrade_pressed(id: StringName)
signal enter_rift_pressed
signal student_select_pressed(id: StringName)
signal student_upgrade_pressed(id: StringName)


func show_building(id: StringName) -> void:
	var b: BuildingData = Registry.buildings[id]
	var lv := GameState.building_level(id)
	var box := _open()
	box.add_child(_label("Ruined" if lv <= 0 else "Level %d / %d" % [lv, b.max_level], "Eyebrow"))
	box.add_child(_label(b.display_name, "Title"))
	box.add_child(_label(b.description, "", true))

	box.add_child(_label("Run bonus", "Heading"))
	var now := b.bonus_text(lv)
	box.add_child(_label(now if now != "" else "None yet: repair it first.", "" if now != "" else "Small", true))
	if lv < b.max_level:
		var next := b.bonus_text(lv + 1)
		if next != "":
			var nl := _label("Next level: " + next, "Small", true)
			nl.add_theme_color_override("font_color", UiTheme.GEM)
			box.add_child(nl)

	if b.is_rift_gate:
		box.add_child(_button("Enter the Rift", "Primary", func() -> void: enter_rift_pressed.emit()))

	if lv < b.max_level:
		var cost := GameState.next_cost(id)
		box.add_child(_label("Repair cost" if lv <= 0 else "Upgrade cost", "Heading"))
		box.add_child(_resource_row(cost, false, GameState.resources()))
		var action := _button(("Repair" if lv <= 0 else "Upgrade to Lv%d" % (lv + 1)), "" if b.is_rift_gate else "Primary",
			func() -> void: upgrade_pressed.emit(id))
		action.disabled = not GameState.can_afford(cost)
		if action.disabled:
			action.text += " (not enough)"
		box.add_child(action)
	else:
		box.add_child(_label("Fully restored.", "Small"))

	box.add_child(_label("You have", "Heading"))
	box.add_child(_resource_row(GameState.resources(), false, Vector3i(-1, -1, -1), true))
	box.add_child(_button("Close", "", func() -> void: close()))


# ================================================================= students

func show_roster() -> void:
	var box := _open()
	box.add_child(_label("Astralis Academy", "Eyebrow"))
	box.add_child(_label("Students", "Title"))
	box.add_child(_label("Tap a student to see their profile. The selected student enters the Rift.", "Small", true))
	for c: CharacterData in Registry.characters:
		var unlocked := GameState.is_student_unlocked(c.id)
		var lv := GameState.student_level(c.id)
		var status := ""
		if not unlocked:
			status = "Joins when the Dormitory reaches Lv%d" % c.unlock_dormitory_level
		elif GameState.student_busy(c.id):
			status = "Away on an expedition"
		elif c.id == GameState.selected_student:
			status = "Selected · enters the Rift"
		elif GameState.can_upgrade_student(c.id):
			status = "Level up available"
		var id := c.id
		box.add_child(_student_card(c, "%s · Lv%d" % [c.role, lv] if unlocked else c.role, status, unlocked,
			func() -> void: show_profile(id)))
	box.add_child(_button("Close", "", func() -> void: close()))


func show_profile(id: StringName) -> void:
	var c := Registry.character(id)
	var unlocked := GameState.is_student_unlocked(id)
	var lv := GameState.student_level(id)
	var element: ElementData = Registry.elements.get(c.element_id)
	var box := _open()
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	head.add_child(_portrait(c, 52.0, not unlocked))
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", 1)
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.add_child(_label(c.role, "Eyebrow"))
	var title := _label(c.display_name, "Title")
	title.add_theme_font_size_override("font_size", 10)
	names.add_child(title)
	names.add_child(_label(c.personality, "Small", false))
	names.add_child(_label("Level %d / %d" % [lv, c.max_level] if unlocked else "Not yet at the academy", "CardTitle"))
	head.add_child(names)
	box.add_child(head)
	box.add_child(_label(c.bio, "", true))

	box.add_child(_label("Starting ball", "Heading"))
	if element:
		box.add_child(_info_row(element.glow_color, element.display_name + " Ball", element.description))
	box.add_child(_label("Ultimate", "Heading"))
	box.add_child(_info_row(element.glow_color if element else UiTheme.GOLD, c.ultimate_name, c.ultimate_description))

	box.add_child(_label("Level bonuses", "Heading"))
	box.add_child(_label(_bonus_text(c, lv), "", true))

	if not unlocked:
		box.add_child(_label("Restore the Dormitory to Lv%d and %s will join the academy." % [c.unlock_dormitory_level, c.display_name.get_slice(" ", 0)], "Small", true))
	else:
		if lv < c.max_level:
			var next := _label("Next: " + _bonus_text(c, lv + 1), "Small", true)
			next.add_theme_color_override("font_color", UiTheme.GEM)
			box.add_child(next)
			var cost := GameState.student_next_cost(id)
			box.add_child(_resource_row(cost, false, GameState.resources()))
			var up := _button("Level up to %d" % (lv + 1), "", func() -> void: student_upgrade_pressed.emit(id))
			up.disabled = not GameState.can_afford(cost)
			if up.disabled:
				up.text += " (not enough)"
			box.add_child(up)
		if GameState.student_busy(id):
			box.add_child(_label("%s is away on an expedition." % c.display_name.get_slice(" ", 0), "Small", true))
		elif id == GameState.selected_student:
			box.add_child(_label("Selected: %s enters the Rift next." % c.display_name.get_slice(" ", 0), "Small", true))
		else:
			box.add_child(_button("Select for the Rift", "Primary", func() -> void: student_select_pressed.emit(id)))
	box.add_child(_button("Back to students", "", func() -> void: show_roster()))


func show_joined(students: Array[CharacterData]) -> void:
	var box := _open()
	box.add_child(_label("The Dormitory is warm again", "Eyebrow"))
	box.add_child(_label("A new student joins!" if students.size() == 1 else "New students join!", "Title"))
	for c: CharacterData in students:
		var id := c.id
		box.add_child(_student_card(c, c.role, c.personality, true, func() -> void: show_profile(id)))
	box.add_child(_button("Meet them", "Primary", func() -> void: show_profile(students[0].id)))
	box.add_child(_button("Later", "", func() -> void: close()))


func _bonus_text(c: CharacterData, lv: int) -> String:
	var element: ElementData = Registry.elements.get(c.element_id)
	var parts: Array[String] = []
	var hp := c.hp_bonus(lv)
	var dmg := c.start_damage_bonus(lv)
	parts.append("+%d max HP" % hp)
	parts.append("+%d damage on the %s ball" % [dmg, element.display_name if element else "starting"])
	var next_dmg := -1
	for l: int in c.damage_levels:
		if l > lv:
			next_dmg = l
			break
	var s := ", ".join(parts)
	if next_dmg > 0:
		s += " (next damage bonus at Lv%d)" % next_dmg
	return s


func _info_row(color: Color, title: String, desc: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.add_child(_gem_icon(color, 16.0))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 1)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(_label(title, "CardTitle"))
	var d := _label(desc, "", true)
	d.custom_minimum_size.x = PANEL_W - 50.0
	d.add_theme_font_size_override("font_size", 8)
	col.add_child(d)
	row.add_child(col)
	return row


func _student_card(c: CharacterData, subtitle: String, status: String, unlocked: bool, on_press: Callable) -> Control:
	var panel := PanelContainer.new()
	var selected := c.id == GameState.selected_student and unlocked
	var normal := UiTheme.box(Color("1b1b33"), UiTheme.GOLD if selected else Color(UiTheme.GOLD, 0.4), 1, 6)
	var hover := UiTheme.box(Color("222244"), UiTheme.CYAN, 1, 6)
	panel.add_theme_stylebox_override("panel", normal)
	panel.mouse_entered.connect(func() -> void: panel.add_theme_stylebox_override("panel", hover))
	panel.mouse_exited.connect(func() -> void: panel.add_theme_stylebox_override("panel", normal))
	panel.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT and not (ev as InputEventMouseButton).pressed:
			on_press.call())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(row)
	row.add_child(_portrait(c, 36.0, not unlocked))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 1)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(col)
	col.add_child(_label(c.display_name, "CardTitle"))
	col.add_child(_label(subtitle, "Small"))
	if status != "":
		var st := _label(status, "Small", true)
		st.custom_minimum_size.x = PANEL_W - 70.0
		st.add_theme_color_override("font_color", UiTheme.GOLD if unlocked else UiTheme.MUTED)
		col.add_child(st)
	for n: Node in col.get_children():
		(n as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	return panel


## Placeholder portrait: uniform, face and hair in the student's colors (anime art replaces this later).
func _portrait(c: CharacterData, size: float, locked: bool) -> Control:
	var p := Control.new()
	p.custom_minimum_size = Vector2(size, size)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.draw.connect(func() -> void:
		var s := p.custom_minimum_size
		var k := s.x / 36.0
		p.draw_rect(Rect2(Vector2.ZERO, s), Color("0b0b16"))
		var element: ElementData = Registry.elements.get(c.element_id)
		var glow := element.glow_color if element else UiTheme.VIOLET
		p.draw_rect(Rect2(Vector2(0, s.y * 0.55), Vector2(s.x, s.y * 0.45)), Color(glow, 0.18))
		var hair := c.hair_color
		var skin := Color("f1d3bd")
		var uni := Color("24306a")
		if locked:
			hair = Color("2a2838")
			skin = Color("2a2838")
			uni = Color("1d1b28")
		p.draw_rect(Rect2(Vector2(8, 26) * k, Vector2(20, 10) * k), uni)
		p.draw_rect(Rect2(Vector2(16, 26) * k, Vector2(4, 4) * k), c.accent_color if not locked else uni)
		p.draw_rect(Rect2(Vector2(11, 10) * k, Vector2(14, 15) * k), skin)
		p.draw_rect(Rect2(Vector2(9, 6) * k, Vector2(18, 6) * k), hair)
		p.draw_rect(Rect2(Vector2(9, 10) * k, Vector2(4, 14) * k), hair)
		p.draw_rect(Rect2(Vector2(23, 10) * k, Vector2(4, 9) * k), hair)
		if not locked:
			p.draw_rect(Rect2(Vector2(14, 16) * k, Vector2(2, 2) * k), Color("3a2a1e"))
			p.draw_rect(Rect2(Vector2(20, 16) * k, Vector2(2, 2) * k), Color("3a2a1e"))
		else:
			p.draw_string(UiTheme.pixel_font(), Vector2(0, s.y * 0.6), "?", HORIZONTAL_ALIGNMENT_CENTER, s.x, int(14 * k), UiTheme.MUTED)
		p.draw_rect(Rect2(Vector2.ZERO, s), Color(glow, 0.7) if not locked else UiTheme.LINE, false, 1.0))
	return p
