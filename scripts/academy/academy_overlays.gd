class_name AcademyOverlays
extends ModalLayer
## Academy modal screens: building details with repair/upgrade, the Rift Gate entrance,
## and the student roster / profile / "a student joined" notice.

signal upgrade_pressed(id: StringName)
signal enter_rift_pressed
signal student_select_pressed(id: StringName)
signal student_upgrade_pressed(id: StringName)
signal talk_pressed(dialogue_id: StringName)
signal research_pressed
signal codex_pressed


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
	if id == &"dormitory" and lv >= 1:
		_add_bond_rows(box)
	if id == &"library":
		var n := GameState.available_research_count()
		var rb := _button("Research" + (" (%d available)" % n if n > 0 else ""), "Primary" if n > 0 else "", func() -> void: research_pressed.emit())
		rb.disabled = lv <= 0
		box.add_child(rb)
		box.add_child(_button("Recipe codex (%d / %d)" % [GameState.recipes_discovered.size(), Registry.evolutions.size()], "", func() -> void: codex_pressed.emit()))
		if lv <= 0:
			box.add_child(_label("Repair the Library to start research.", "Small", true))

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


## Dormitory: one row per pair of students, with a "Talk" button when a new scene is ready.
func _add_bond_rows(box: VBoxContainer) -> void:
	box.add_child(_label("Spend time together", "Heading"))
	for bo: BondData in Registry.bonds:
		if not GameState.bond_active(bo):
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		row.add_child(_portrait(Registry.character(bo.student_a), 22.0, false))
		row.add_child(_portrait(Registry.character(bo.student_b), 22.0, false))
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 0)
		col.add_child(_label("%s · bond Lv%d" % [bo.display_name(), GameState.bond_level(bo.id)], "CardTitle"))
		var reason := GameState.scene_lock_reason(bo)
		var scene := GameState.next_scene(bo)
		var st := _label(("New: " + scene.title) if reason == "" and scene else reason, "Tiny", true)
		st.custom_minimum_size.x = PANEL_W - 120.0
		st.add_theme_color_override("font_color", UiTheme.GOLD if reason == "" else UiTheme.MUTED)
		col.add_child(st)
		row.add_child(col)
		if reason == "" and scene:
			var sid := scene.id
			var talk := _button("Talk", "Primary", func() -> void: talk_pressed.emit(sid))
			talk.custom_minimum_size = Vector2(48, 22)
			row.add_child(talk)
		box.add_child(row)
	var any := false
	for bo: BondData in Registry.bonds:
		any = any or GameState.bond_active(bo)
	if not any:
		box.add_child(_label("Scenes start when a second student moves in.", "Small", true))


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


func _portrait(c: CharacterData, px: float, locked: bool) -> Control:
	return Portrait.make(c, px, locked)
