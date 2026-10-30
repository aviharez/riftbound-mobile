class_name StoriesOverlays
extends ModalLayer
## Stories tab: student bonds (level, progress, duo evolution), watched scenes to replay, and expedition clues.
## Also the "bond grew" result after a Dormitory scene. See docs/relationship-spec.md.

signal replay_pressed(dialogue_id: StringName)
signal dormitory_pressed


func show_stories() -> void:
	var box := _open()
	box.add_child(_label("Astralis Academy", "Eyebrow"))
	box.add_child(_label("Stories", "Title"))
	box.add_child(_label("Bonds grow from Dormitory scenes and from expeditions taken together. At bond Lv%d a pair unlocks a duo evolution in the Rift." % Registry.economy.duo_bond_level, "Small", true))

	box.add_child(_label("Bonds", "Heading"))
	for b: BondData in Registry.bonds:
		box.add_child(_bond_card(b))

	box.add_child(_label("Scenes", "Heading"))
	var any := false
	for d: DialogueData in Registry.dialogues:
		if not GameState.scenes_seen.has(d.id):
			continue
		any = true
		var bond := Registry.bond(d.bond_id)
		var id := d.id
		var b := _button("Replay: %s (%s)" % [d.title, bond.display_name() if bond else ""], "", func() -> void: replay_pressed.emit(id))
		b.add_theme_font_size_override("font_size", 8)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(b)
	if not any:
		box.add_child(_label("No scenes yet. Visit the Dormitory once two students live there.", "Small", true))

	box.add_child(_label("Clues", "Heading"))
	for e: ExpeditionData in Registry.expeditions:
		var found: int = GameState.clues_found.get(e.id, 0)
		box.add_child(_label("%s  %d / %d" % [e.display_name, found, e.clues.size()], "CardTitle"))
		for i in e.clues.size():
			var l := _label(("\"%s\"" % e.clues[i]) if i < found else "??? (found on a successful expedition)", "Small", true)
			if i >= found:
				l.add_theme_color_override("font_color", UiTheme.LINE.lightened(0.3))
			box.add_child(l)
	box.add_child(_button("Close", "", func() -> void: close()))


## After a new scene: points gained, level up, duo evolution unlocked.
func show_bond_result(d: DialogueData, result: Dictionary) -> void:
	var bond := Registry.bond(d.bond_id)
	var box := _open()
	box.add_child(_label(d.title, "Eyebrow"))
	box.add_child(_label("Bond grew", "Title"))
	if bond:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		row.add_child(Portrait.make(Registry.character(bond.student_a), 36.0))
		row.add_child(Portrait.make(Registry.character(bond.student_b), 36.0))
		var col := VBoxContainer.new()
		col.add_child(_label(bond.display_name(), "CardTitle"))
		col.add_child(_label("+%d bond points" % int(result.get("points", 0)), "Small"))
		row.add_child(col)
		box.add_child(row)
		box.add_child(_bond_bar(bond))
	var old_lv: int = result.get("old_level", 0)
	var new_lv: int = result.get("new_level", 0)
	if new_lv > old_lv:
		var up := _label("Bond level %d reached!" % new_lv, "CardTitle")
		up.add_theme_color_override("font_color", UiTheme.GOLD)
		box.add_child(up)
	var duo: StringName = result.get("duo", &"")
	if duo != &"":
		box.add_child(_duo_unlocked(duo))
	box.add_child(_button("Back to the Dormitory", "Primary", func() -> void: dormitory_pressed.emit()))
	box.add_child(_button("Close", "", func() -> void: close()))


## A duo evolution unlock notice (also used by the expedition result).
func _duo_unlocked(recipe_id: StringName) -> Control:
	var r := Registry.recipe(recipe_id)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.INK_3, UiTheme.GOLD, 1, 6))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	panel.add_child(col)
	col.add_child(_label("Duo evolution unlocked", "Eyebrow"))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.add_child(_gem_icon(r.glow_color if r else UiTheme.GOLD, 16.0))
	row.add_child(_label(r.display_name if r else String(recipe_id), "CardTitle"))
	col.add_child(row)
	if r:
		var how := "Fuse %s + %s in the Rift." % [_element_name(r.element_a), _element_name(r.element_b)]
		var d := _label("%s %s" % [r.description, how], "Small", true)
		d.custom_minimum_size.x = PANEL_W - 40.0
		col.add_child(d)
	return panel


func _bond_card(b: BondData) -> Control:
	var active := GameState.bond_active(b)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.box(Color("1b1b33"), Color(UiTheme.GOLD, 0.4 if active else 0.15), 1, 6))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 3)
	panel.add_child(col)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.add_child(Portrait.make(Registry.character(b.student_a), 28.0, not GameState.is_student_unlocked(b.student_a)))
	row.add_child(Portrait.make(Registry.character(b.student_b), 28.0, not GameState.is_student_unlocked(b.student_b)))
	var names := VBoxContainer.new()
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.add_child(_label(b.display_name(), "CardTitle"))
	names.add_child(_label("Bond Lv%d / %d" % [GameState.bond_level(b.id), GameState.bond_max_level()] if active else "Not both at the academy yet", "Small"))
	row.add_child(names)
	col.add_child(row)
	if not active:
		return panel
	col.add_child(_bond_bar(b))
	var r := Registry.recipe(b.duo_recipe)
	var duo_text := "Duo: %s" % (r.display_name if r else String(b.duo_recipe))
	var duo := _label(duo_text + (" (unlocked)" if GameState.duo_unlocked(b) else " (bond Lv%d)" % Registry.economy.duo_bond_level), "Small", true)
	duo.add_theme_color_override("font_color", UiTheme.GEM if GameState.duo_unlocked(b) else UiTheme.MUTED)
	col.add_child(duo)
	var reason := GameState.scene_lock_reason(b)
	var st := _label("New scene ready in the Dormitory" if reason == "" else reason, "Small", true)
	st.add_theme_color_override("font_color", UiTheme.GOLD if reason == "" else UiTheme.MUTED)
	col.add_child(st)
	return panel


func _bond_bar(b: BondData) -> Control:
	var prog := GameState.bond_progress(b.id)
	var bar := Control.new()
	bar.custom_minimum_size = Vector2(PANEL_W - 30.0, 10.0)
	bar.draw.connect(func() -> void:
		var s := bar.size
		bar.draw_rect(Rect2(Vector2(0, 2), Vector2(s.x, 6)), UiTheme.INK_3)
		var f := 1.0 if prog.y == 0 else float(prog.x) / float(prog.y)
		bar.draw_rect(Rect2(Vector2(0, 2), Vector2(s.x * f, 6)), Color("f08fb4"))
		bar.draw_rect(Rect2(Vector2(0, 2), Vector2(s.x, 6)), UiTheme.LINE, false, 1.0))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	col.add_child(bar)
	col.add_child(_label("Max bond" if prog.y == 0 else "%d / %d to the next level" % [prog.x, prog.y], "Tiny"))
	return col


func _element_name(id: StringName) -> String:
	var el: ElementData = Registry.elements.get(id)
	return el.display_name if el else String(id)
