class_name ExpeditionOverlays
extends ModalLayer
## Expedition screens: board, detail with team select and success chance, running expedition, result.
## Talks to GameState directly; AcademyScreen only opens the board. See docs/expedition-spec.md.

var _live: Array = []  # [Label, expedition id] pairs updated every frame while open
var _team: Array[StringName] = []
var _current: StringName = &""


func _process(_delta: float) -> void:
	if not is_open():
		return
	for pair: Array in _live:
		var l: Label = pair[0]
		if is_instance_valid(l):
			l.text = _status_text(Registry.expedition(pair[1]))


# ================================================================= screens

func show_board() -> void:
	var box := _open()
	_live.clear()
	box.add_child(_label("Beyond the walls", "Eyebrow"))
	box.add_child(_label("Expeditions", "Title"))
	box.add_child(_label("Send students out for a while. They come back with resources and clues about the Riftfall. Students away can't enter the Rift.", "Small", true))
	for e: ExpeditionData in Registry.expeditions:
		box.add_child(_board_card(e))
	box.add_child(_button("Close", "", func() -> void: close()))


func show_detail(id: StringName, team: Array[StringName] = []) -> void:
	var e := Registry.expedition(id)
	_current = id
	_team = team
	_live.clear()
	var box := _open()
	box.add_child(_label("Threat: %s  ·  %s" % [_threat(e.threat), _duration(e.duration_seconds)], "Eyebrow"))
	box.add_child(_label(e.display_name, "Title"))
	box.add_child(_label(e.description, "", true))
	box.add_child(_label("Rewards on success", "Heading"))
	box.add_child(_resource_row(e.rewards))
	var rare := _label("Rare find: %d%% chance of an extra Ancient Relic" % roundi(e.rare_chance * 100.0), "Small", true)
	box.add_child(rare)
	var found: int = GameState.clues_found.get(id, 0)
	box.add_child(_label("Clues found: %d / %d" % [found, e.clues.size()], "Small"))

	if GameState.expeditions_active.has(id):
		var rec: Dictionary = GameState.expeditions_active[id]
		box.add_child(_label("Team", "Heading"))
		var names: Array[String] = []
		for m: StringName in rec.team:
			names.append(Registry.character(m).display_name)
		box.add_child(_label(", ".join(names), "", true))
		var status := _label(_status_text(e), "CardTitle")
		_live.append([status, id])
		box.add_child(status)
		box.add_child(_label("The outcome is revealed when they return.", "Small", true))
		if GameState.is_expedition_ready(id):
			box.add_child(_button("Welcome them back", "Primary", func() -> void: _claim(id)))
		elif OS.is_debug_build():
			box.add_child(_button("Finish now (debug)", "", func() -> void:
				GameState.debug_finish_expedition(id)
				show_detail(id)))
	elif not GameState.expedition_unlocked(e):
		var lock := _label("Locked: " + GameState.expedition_lock_reason(e), "CardTitle")
		lock.add_theme_color_override("font_color", UiTheme.MUTED)
		box.add_child(lock)
	else:
		box.add_child(_label("Team (up to %d)" % e.max_team, "Heading"))
		box.add_child(_label("%s students (marked +) are stronger here." % _element_name(e.preferred_element), "Small", true))
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 4)
		grid.add_theme_constant_override("v_separation", 4)
		for c: CharacterData in Registry.characters:
			if not GameState.is_student_unlocked(c.id):
				continue
			grid.add_child(_team_chip(e, c))
		box.add_child(grid)
		var power := GameState.team_power(e, _team)
		var chance := GameState.success_chance(e, _team)
		var pl := _label("Team power %d / recommended %d\nSuccess chance %d%%" % [roundi(power), roundi(e.recommended_power), roundi(chance * 100.0)], "CardTitle", true)
		pl.add_theme_color_override("font_color", UiTheme.GEM if chance >= 0.99 else (UiTheme.GOLD if chance >= 0.6 else UiTheme.DANGER))
		box.add_child(pl)
		var problem := GameState.expedition_team_problem(e, _team)
		if problem != "":
			box.add_child(_label(problem, "Small", true))
		var start := _button("Send the team (%s)" % _duration(e.duration_seconds), "Primary", func() -> void:
			if GameState.start_expedition(id, _team):
				show_detail(id))
		start.disabled = problem != ""
		box.add_child(start)
	box.add_child(_button("Back to expeditions", "", func() -> void: show_board()))


func show_result(id: StringName, result: Dictionary) -> void:
	var e := Registry.expedition(id)
	_live.clear()
	var box := _open()
	var ok: bool = result.success
	box.add_child(_label(e.display_name, "Eyebrow"))
	box.add_child(_label("Expedition complete" if ok else "They came back early", "Title"))
	box.add_child(_label("The team found what they were looking for." if ok else "It was too dangerous. They saved what they could.", "", true))
	box.add_child(_label("Rewards", "Heading"))
	box.add_child(_resource_row(result.rewards, true))
	if result.rare:
		var r := _label("Rare find: an Ancient Relic!", "CardTitle")
		r.add_theme_color_override("font_color", UiTheme.RELIC)
		box.add_child(r)
	box.add_child(_label("Clue", "Heading"))
	var clue: String = result.clue
	if clue != "":
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.INK_3, Color(UiTheme.GOLD, 0.6), 1, 6))
		var l := _label("\"%s\"" % clue, "", true)
		l.custom_minimum_size.x = PANEL_W - 40.0
		panel.add_child(l)
		box.add_child(panel)
	else:
		box.add_child(_label("No new clues this time." if ok else "No clues: the team had to turn back.", "Small", true))
	box.add_child(_button("Back to expeditions", "Primary", func() -> void: show_board()))
	box.add_child(_button("Close", "", func() -> void: close()))


# ================================================================= pieces

func _claim(id: StringName) -> void:
	var result := GameState.claim_expedition(id)
	if result.is_empty():
		show_detail(id)
	else:
		show_result(id, result)


func _board_card(e: ExpeditionData) -> Control:
	var panel := PanelContainer.new()
	var ready := GameState.is_expedition_ready(e.id)
	var normal := UiTheme.box(Color("1b1b33"), UiTheme.GOLD if ready else Color(UiTheme.GOLD, 0.4), 1, 6)
	var hover := UiTheme.box(Color("222244"), UiTheme.CYAN, 1, 6)
	panel.add_theme_stylebox_override("panel", normal)
	panel.mouse_entered.connect(func() -> void: panel.add_theme_stylebox_override("panel", hover))
	panel.mouse_exited.connect(func() -> void: panel.add_theme_stylebox_override("panel", normal))
	var id := e.id
	panel.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT and not (ev as InputEventMouseButton).pressed:
			show_detail(id))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(col)
	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var name := _label(e.display_name, "CardTitle")
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(name)
	top.add_child(_label(_threat(e.threat).to_upper(), "Eyebrow"))
	col.add_child(top)
	col.add_child(_label("%s · recommended power %d · up to %d students" % [_duration(e.duration_seconds), roundi(e.recommended_power), e.max_team], "Small"))
	col.add_child(_resource_row(e.rewards))
	var status := _label(_status_text(e), "Small")
	status.add_theme_color_override("font_color", UiTheme.GOLD if ready else (UiTheme.MUTED if not GameState.expedition_unlocked(e) else UiTheme.CYAN))
	_live.append([status, e.id])
	col.add_child(status)
	for n: Node in col.get_children():
		(n as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for n: Node in top.get_children():
		(n as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	return panel


func _team_chip(e: ExpeditionData, c: CharacterData) -> Control:
	var busy := GameState.student_busy(c.id)
	var picked := _team.has(c.id)
	var b := Button.new()
	var match_mark := " +" if c.element_id == e.preferred_element else ""
	b.text = "%s Lv%d%s%s" % [c.display_name.get_slice(" ", 0), GameState.student_level(c.id), match_mark, "\n(away)" if busy else ""]
	b.toggle_mode = true
	b.button_pressed = picked
	b.disabled = busy
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size.y = 24.0
	b.add_theme_font_size_override("font_size", 8)
	if picked:
		b.add_theme_stylebox_override("pressed", UiTheme.box(Color("2b2b4a"), UiTheme.GOLD, 1, 4))
	var id := c.id
	b.toggled.connect(func(on: bool) -> void:
		var t := _team.duplicate()
		if on and not t.has(id):
			t.append(id)
		elif not on:
			t.erase(id)
		show_detail(_current, t))
	return b


func _status_text(e: ExpeditionData) -> String:
	if GameState.expeditions_active.has(e.id):
		if GameState.is_expedition_ready(e.id):
			return "Back! Tap to welcome the team."
		return "Away · back in " + _clock(GameState.expedition_time_left(e.id))
	if not GameState.expedition_unlocked(e):
		return "Locked · " + GameState.expedition_lock_reason(e)
	return "Available"


func _element_name(id: StringName) -> String:
	var el: ElementData = Registry.elements.get(id)
	return el.display_name if el else String(id)


static func _threat(level: int) -> String:
	return ["low", "medium", "high"][clampi(level - 1, 0, 2)]


static func _duration(seconds: float) -> String:
	var m := roundi(seconds / 60.0)
	if m < 60:
		return "%d min" % m
	return "%dh %02dm" % [m / 60, m % 60]


static func _clock(seconds: float) -> String:
	var s := ceili(seconds)
	if s >= 3600:
		return "%d:%02d:%02d" % [s / 3600, (s % 3600) / 60, s % 60]
	return "%d:%02d" % [s / 60, s % 60]
