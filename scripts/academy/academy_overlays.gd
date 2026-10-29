class_name AcademyOverlays
extends ModalLayer
## Academy modal screens: building details with repair/upgrade, and the Rift Gate entrance.

signal upgrade_pressed(id: StringName)
signal enter_rift_pressed


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
