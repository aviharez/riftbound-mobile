class_name Overlays
extends ModalLayer
## Battle modal screens: pause/settings, level up, fusion, run result.
## Emits signals; BattleScreen owns the flow.

signal resume_pressed
signal retreat_pressed
signal academy_pressed
signal card_chosen(card: LevelCard)
signal reroll_pressed
signal fusion_chosen(pair: Vector2i)
signal fusion_kept
signal open_fusion_pressed
signal again_pressed
signal debug_action(action: StringName)


# ================================================================= screens

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
	var previews: Array[String] = ["Crosshair only", "To first contact", "+1 bounce", "+3 bounces"]
	var preview_values: Array[int] = [-1, 0, 1, 3]
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
	box.add_child(_button("Retreat to Academy (keep rewards)", "", func() -> void: retreat_pressed.emit()))
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
		var rec := Registry.recipe(r.id) if r.evolved else null
		var kind := "Fusion · combined effects"
		if rec and rec.duo_bond != &"":
			kind = "Duo evolution · bond"
		elif r.evolved:
			kind = "Evolution · recipe"
		box.add_child(_card(r.glow_color, kind, r.display_name, r.description, recipe, r.evolved,
			func() -> void: fusion_chosen.emit(pair)))
	box.add_child(_button("Keep prism for later", "", func() -> void: fusion_kept.emit()))


func show_result(battle: Battle, rewards: Vector3i, retreated: bool) -> void:
	var box := _open()
	box.add_child(_label("Retreated" if retreated else "Run over", "Eyebrow"))
	box.add_child(_label("Back to the Academy" if retreated else "The line has fallen", "Title"))
	if battle.character and battle.character.sprite_sheet:
		var p := Portrait.make(battle.character, 96.0, false, false)
		p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		box.add_child(p)
		var ribbon := _label("Wave %d reached" % battle.wave, "CardTitle")
		ribbon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(ribbon)
	box.add_child(_label("Rewards", "Heading"))
	box.add_child(_reward_tiles(rewards))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	var t := int(battle.run_time)
	for row: Array in [["Wave reached", str(battle.wave)], ["Level", str(battle.level)], ["Enemies defeated", str(battle.kills)],
			["Bosses defeated", str(battle.bosses)], ["Perfect catches", str(battle.catches)], ["Fusions", str(battle.fusions)],
			["Duration", "%d:%02d" % [floori(battle.run_time / 60.0), t % 60]], ["Best wave", str(GameState.best_wave)]]:
		var k := _label(row[0], "")
		k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(k)
		var v := _label(row[1], "Eyebrow")
		v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		grid.add_child(v)
	box.add_child(grid)
	box.add_child(_slots_view(battle.loadout))
	box.add_child(_button("Return to Academy", "Primary", func() -> void: academy_pressed.emit()))
	box.add_child(_button("Fight again", "", func() -> void: again_pressed.emit()))
