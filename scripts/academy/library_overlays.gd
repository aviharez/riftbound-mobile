class_name LibraryOverlays
extends ModalLayer
## Library screens: research (permanent passives bought once) and the fusion recipe codex.
## Opened from the Library's building panel. See docs/library-spec.md.

signal back_pressed


func show_research() -> void:
	var box := _open()
	var lib := GameState.building_level(&"library")
	box.add_child(_label("Library · Lv%d" % lib, "Eyebrow"))
	box.add_child(_label("Research", "Title"))
	box.add_child(_label("Permanent bonuses for every run. Restoring the Library opens deeper shelves.", "Small", true))
	for r: ResearchData in Registry.research:
		box.add_child(_research_card(r))
	box.add_child(_label("You have", "Heading"))
	box.add_child(_resource_row(GameState.resources(), false, Vector3i(-1, -1, -1), true))
	box.add_child(_button("Back to the Library", "", func() -> void: back_pressed.emit()))


func show_codex() -> void:
	var box := _open()
	var total := Registry.evolutions.size()
	box.add_child(_label("Library", "Eyebrow"))
	box.add_child(_label("Recipe codex", "Title"))
	box.add_child(_label("Discovered %d / %d. Fuse two level-3 balls with a Rift Prism in the Rift to record a recipe. Pairs without a recipe make a generic fusion with both effects." % [GameState.recipes_discovered.size(), total], "Small", true))
	box.add_child(_label("Evolutions", "Heading"))
	for r: EvolutionRecipe in Registry.evolutions:
		if r.duo_bond == &"":
			box.add_child(_recipe_card(r))
	box.add_child(_label("Duo evolutions", "Heading"))
	for r: EvolutionRecipe in Registry.evolutions:
		if r.duo_bond != &"":
			box.add_child(_recipe_card(r))
	box.add_child(_button("Back to the Library", "", func() -> void: back_pressed.emit()))


func _research_card(r: ResearchData) -> Control:
	var problem := GameState.research_problem(r)
	var done := GameState.research_done.has(r.id)
	var locked := problem.begins_with("Needs")
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.box(Color("1b1b33"), UiTheme.GEM if done else Color(UiTheme.GOLD, 0.15 if locked else 0.4), 1, 6))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	panel.add_child(col)
	var top := HBoxContainer.new()
	var name := _label(r.display_name, "CardTitle")
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if locked:
		name.add_theme_color_override("font_color", UiTheme.MUTED)
	top.add_child(name)
	top.add_child(_label("Lv%d" % r.library_level, "Eyebrow"))
	col.add_child(top)
	var eff := _label(r.effect_text, "Small", true)
	eff.custom_minimum_size.x = PANEL_W - 40.0
	eff.add_theme_color_override("font_color", UiTheme.GEM if not locked else UiTheme.MUTED)
	col.add_child(eff)
	var d := _label(r.description, "Tiny", true)
	d.custom_minimum_size.x = PANEL_W - 40.0
	col.add_child(d)
	if done:
		col.add_child(_label("Researched", "Small"))
	elif locked:
		col.add_child(_label(problem, "Small"))
	else:
		col.add_child(_resource_row(r.cost, false, GameState.resources()))
		var id := r.id
		var b := _button("Research" if problem == "" else "Research (not enough)", "Primary", func() -> void:
			if GameState.buy_research(id):
				show_research())
		b.disabled = problem != ""
		col.add_child(b)
	return panel


func _recipe_card(r: EvolutionRecipe) -> Control:
	var known := GameState.recipes_discovered.has(r.result_id)
	var bond := Registry.bond(r.duo_bond) if r.duo_bond != &"" else null
	var duo_open := bond != null and GameState.duo_unlocked(bond)
	var show_name := known or duo_open
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.box(Color("1b1b33"), Color(r.glow_color, 0.7) if known else Color(UiTheme.GOLD, 0.2), 1, 6))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	panel.add_child(row)
	row.add_child(_gem_icon(r.glow_color if show_name else UiTheme.LINE, 16.0))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 1)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	col.add_child(_label(r.display_name if show_name else "???", "CardTitle"))
	var inputs := "%s + %s" % [_element_name(r.element_a), _element_name(r.element_b)] if show_name else "? + ?"
	col.add_child(_label(inputs, "Small"))
	var text := ""
	if known:
		text = r.description
	elif bond:
		text = ("Unlocked by %s. Not fused yet." % bond.display_name()) if duo_open else ("Needs %s at bond Lv%d." % [bond.display_name(), Registry.economy.duo_bond_level])
	else:
		text = "Not discovered yet."
	var d := _label(text, "Tiny", true)
	d.custom_minimum_size.x = PANEL_W - 60.0
	col.add_child(d)
	if known and (r.bonus_damage > 0 or r.bonus_power > 0):
		col.add_child(_label("Duo bonus: +%d damage, +%d power" % [r.bonus_damage, r.bonus_power], "Tiny"))
	return panel


func _element_name(id: StringName) -> String:
	var el: ElementData = Registry.elements.get(id)
	return el.display_name if el else String(id)
