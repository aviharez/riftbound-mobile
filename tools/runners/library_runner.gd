extends Node
## Library and quests flow (M12): Library panel → research (buy one, bonus reaches the run) → codex before and
## after a fusion is recorded → quest journal with a claimable quest → claim. Asserts the rules and screenshots
## each step. Loaded by tools/run_runner.gd with --scene=res://scenes/title/title_screen.tscn.

var out_dir := "docs/qa/evidence"
var prefix := "flow"
var t := 0.0
var wait := 0.0
var phase := 0
var failures: Array[String] = []


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out_dir = arg.trim_prefix("--out=")
		elif arg.begins_with("--prefix="):
			prefix = arg.trim_prefix("--prefix=")
	prefix += "-library"


func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := "%s/%s-%s-%dx%d.png" % [out_dir, prefix, name, img.get_width(), img.get_height()]
	img.save_png(path if path.begins_with("/") else ProjectSettings.globalize_path("res://" + path))
	print("SHOT ", path, " research=", GameState.research_done, " recipes=", GameState.recipes_discovered, " claimed=", GameState.quests_claimed.size())


func check(ok: bool, what: String) -> void:
	if not ok:
		failures.append(what)
		printerr("LIBRARY CHECK FAILED: ", what)


func _process(delta: float) -> void:
	t += delta
	if wait > 0.0:
		wait -= delta
		return
	var scene := get_tree().current_scene
	var ac := scene as AcademyScreen
	match phase:
		0:
			if t > 0.6 and scene is TitleScreen:
				(scene as TitleScreen)._on_new_game(); phase = 1; t = 0.0
		1:
			if t > 0.8 and ac:
				var topic := Registry.research_topic(&"ley_line_theory")
				check(GameState.research_problem(topic) == "Needs Library Lv1", "research needs the Library")
				GameState.add_resources(Vector3i(500, 200, 1))
				GameState.upgrade_building(&"library")
				ac._open_building(&"library"); wait = 0.4; phase = 2
		2:
			shot("01-library-panel"); wait = 0.2; phase = 3
		3:
			ac.overlays.research_pressed.emit(); wait = 0.4; phase = 4
		4:
			shot("02-research"); wait = 0.2; phase = 5
		5:
			var before: float = GameState.run_bonuses()[&"xp_mult"]
			var shards_before := GameState.mana_shards
			check(GameState.buy_research(&"ley_line_theory"), "buy Ley Line Theory")
			check(not GameState.buy_research(&"ley_line_theory"), "research can't be bought twice")
			check(not GameState.buy_research(&"battery_wards"), "Lv2 research locked at Library Lv1")
			check(is_equal_approx(GameState.run_bonuses()[&"xp_mult"], before + 0.1), "research adds to run XP")
			check(GameState.mana_shards == shards_before - 60, "research costs its price")
			GameState.buy_research(&"salvage_ledgers")
			var plain := Registry.economy.run_rewards(40, 4, 0, 0)
			var got := GameState.finish_run(40, 4, 0, 0, false)
			check(got.x == roundi(plain.x * 1.15) and got.y == roundi(plain.y * 1.15), "Salvage Ledgers adds 15% to run rewards")
			ac.library.show_research(); wait = 0.4; phase = 6
		6:
			shot("03-research-bought"); wait = 0.2; phase = 7
		7:
			ac.library.show_codex(); wait = 0.4; phase = 8
		8:
			shot("04-codex-empty"); wait = 0.2; phase = 9
		9:
			# A real fusion in a Battle must reach the codex through the fused signal.
			var b := Battle.new()
			b.fused.connect(func(r: BallSlot) -> void:
				if r.evolved:
					GameState.discover_recipe(r.id))
			var fxn := Fx.new()
			fxn.name = "Fx"
			b.add_child(fxn)  # Battle expects its Fx child, as in battle_screen.tscn
			b.visible = false  # logic only: drawing needs the battle screen's player settings
			add_child(b)
			b.start_run(Registry.character(&"lyra"), GameState.run_bonuses())
			b.loadout.balls[1] = BallSlot.from_element(Registry.elements[&"frost"], 1)
			b.loadout.balls[0].level = Registry.balance.max_level
			b.loadout.balls[1].level = Registry.balance.max_level
			b.prisms = 1
			b.apply_fusion(Vector2i(0, 1))
			b.queue_free()
			check(GameState.recipes_discovered.has(&"steam_burst"), "fusing Ember + Frost records Steam Burst")
			GameState.discover_recipe(&"steam_burst")
			check(GameState.recipes_discovered.size() == 1, "a recipe is recorded once")
			ac.library.show_codex(); wait = 0.4; phase = 10
		10:
			shot("05-codex-discovered"); wait = 0.2; phase = 11
		11:
			ac.library.close()
			wait = 1.2; phase = 12  # let the HUD badge refresh
		12:
			shot("06-academy-journal-badge"); wait = 0.2; phase = 13
		13:
			ac._on_nav(&"stories"); wait = 0.4; phase = 14
		14:
			var first := Registry.quest(&"first_steps")
			check(GameState.quest_complete(first), "one run completes First Steps")
			check(not GameState.quest_complete(Registry.quest(&"hold_the_line")) or GameState.best_wave >= 5, "Hold the Line needs wave 5")
			shot("07-journal-quests"); wait = 0.2; phase = 15
		15:
			var shards := GameState.mana_shards
			var claimable := GameState.claimable_quest_count()
			check(GameState.claim_quest(&"first_steps"), "claim First Steps")
			check(not GameState.claim_quest(&"first_steps"), "a quest is claimed once")
			check(GameState.mana_shards == shards + 30, "quest reward paid")
			check(GameState.claimable_quest_count() == claimable - 1, "claimable count drops")
			ac.stories.show_stories(&"quests"); wait = 0.4; phase = 16
		16:
			shot("08-journal-claimed"); wait = 0.2; phase = 17
		17:
			var snapshot := [GameState.research_done.duplicate(), GameState.recipes_discovered.duplicate(), GameState.quests_claimed.duplicate()]
			GameState.load_game()
			check(snapshot == [GameState.research_done, GameState.recipes_discovered, GameState.quests_claimed], "library and quests survive save/load")
			if failures.is_empty():
				print("LIBRARY OK research=", GameState.research_done, " recipes=", GameState.recipes_discovered, " claimed=", GameState.quests_claimed)
				get_tree().quit(0)
			else:
				print("LIBRARY FAIL ", failures)
				get_tree().quit(1)
