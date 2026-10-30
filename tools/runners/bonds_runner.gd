extends Node
## Bonds flow (M11): Dormitory "Spend time together" → dialogue scene (line, choice, reply) → bond result →
## two more scenes unlock the duo evolution → fusion uses it → expedition together adds bond points → Stories tab.
## Asserts the rules and screenshots each step. Loaded by tools/run_runner.gd with --scene=res://scenes/title/title_screen.tscn.

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
	prefix += "-bonds"


func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := "%s/%s-%s-%dx%d.png" % [out_dir, prefix, name, img.get_width(), img.get_height()]
	img.save_png(path if path.begins_with("/") else ProjectSettings.globalize_path("res://" + path))
	print("SHOT ", path, " bonds=", GameState.bond_points, " seen=", GameState.scenes_seen.size())


func check(ok: bool, what: String) -> void:
	if not ok:
		failures.append(what)
		printerr("BONDS CHECK FAILED: ", what)


func fused_id(a: StringName, b: StringName) -> BallSlot:
	var l := Loadout.create(Registry.balance, null, GameState.run_bonuses())
	var sa := BallSlot.from_element(Registry.elements[a], Registry.balance.new_ball_damage)
	var sb := BallSlot.from_element(Registry.elements[b], Registry.balance.new_ball_damage)
	sa.level = Registry.balance.max_level
	sb.level = Registry.balance.max_level
	l.balls[0] = sa
	l.balls[1] = sb
	return l.fusion_result(Vector2i(0, 1))


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
				GameState.add_resources(Vector3i(800, 400, 2))
				GameState.upgrade_building(&"dormitory")
				GameState.upgrade_building(&"dormitory")
				GameState.upgrade_building(&"library")
				var bo := Registry.bond(&"lyra_selene")
				check(GameState.scene_lock_reason(bo) == "Come back after your next Rift run", "no scene before the first run")
				GameState.runs = 1
				check(GameState.scene_lock_reason(bo) == "", "scene ready after a run")
				check(fused_id(&"ember", &"frost").id == &"steam_burst", "locked duo keeps the normal recipe")
				ac._open_building(&"dormitory"); wait = 0.4; phase = 2
		2:
			shot("01-dormitory"); wait = 0.2; phase = 3
		3:
			ac.overlays.talk_pressed.emit(&"lyra_selene_1"); wait = 2.8; phase = 4
		4:
			check(ac.dialogue.is_open(), "dialogue opened")
			shot("02-scene-line"); wait = 0.2; phase = 5
		5:
			# Tap through the lines until the choice.
			for i in 20:
				if ac.dialogue._choices.visible:
					break
				if ac.dialogue._typing:
					ac.dialogue._finish_typing()
				ac.dialogue._next()
			wait = 0.3; phase = 6
		6:
			check(ac.dialogue._choices.visible, "choice shown")
			shot("03-scene-choice"); wait = 0.2; phase = 7
		7:
			ac.dialogue._choose(0); wait = 2.0; phase = 8
		8:
			shot("04-scene-reply"); wait = 0.2; phase = 9
		9:
			ac.dialogue._skip(); wait = 0.4; phase = 10
		10:
			check(not ac.dialogue.is_open(), "dialogue closed")
			check(GameState.bond_points.get(&"lyra_selene", 0) == 4, "scene + best choice = 4 points")
			check(GameState.bond_level(&"lyra_selene") == 1, "4 points = bond Lv1")
			check(GameState.scene_lock_reason(Registry.bond(&"lyra_noah")) == "Come back after your next Rift run", "one new scene per run")
			shot("05-bond-result"); wait = 0.2; phase = 11
		11:
			# Two more runs and scenes: 4 + 4 + 4 = 12 points = Lv3, the duo level.
			GameState.runs = 2
			GameState.finish_scene(&"lyra_selene_2", 0)
			GameState.runs = 3
			var r := GameState.finish_scene(&"lyra_selene_3", 0)
			check(r.get("duo", &"") == &"frostfire_waltz", "bond Lv3 unlocks Frostfire Waltz")
			check(GameState.finish_scene(&"lyra_selene_1", 0).is_empty(), "replays pay nothing")
			var duo := fused_id(&"ember", &"frost")
			check(duo.id == &"frostfire_waltz", "unlocked duo replaces Steam Burst")
			var plain := fused_id(&"ember", &"verdant")
			check(plain.id == &"wildfire", "other pairs keep their recipe")
			check(duo.damage == plain.damage + 1 and duo.power == plain.power + 1, "duo bonus damage and power")
			ac.stories.show_bond_result(Registry.dialogue(&"lyra_selene_3"), r); wait = 0.4; phase = 12
		12:
			shot("06-duo-unlocked"); wait = 0.2; phase = 13
		13:
			var team: Array[StringName] = [&"selene", &"noah"]
			check(GameState.start_expedition(&"sunken_archives", team), "expedition with two students")
			GameState.debug_finish_expedition(&"sunken_archives")
			GameState.expeditions_active[&"sunken_archives"].success = true
			ac.stories.close()
			ac.expeditions._claim(&"sunken_archives"); wait = 0.4; phase = 14
		14:
			check(GameState.bond_points.get(&"selene_noah", 0) == 1, "expedition together = +1 bond")
			shot("07-expedition-bond"); wait = 0.2; phase = 15
		15:
			ac._on_nav(&"stories")
			ac.stories.show_stories(&"bonds"); wait = 0.4; phase = 16
		16:
			shot("08-stories"); wait = 0.2; phase = 17
		17:
			GameState.runs = 4
			ac._close_modals()
			ac._open_building(&"dormitory"); wait = 0.4; phase = 18
		18:
			shot("09-dormitory-after"); wait = 0.2; phase = 19
		19:
			GameState.save_game()
			var points := GameState.bond_points.duplicate()
			GameState.load_game()
			check(GameState.bond_points == points and GameState.scenes_seen.size() == 3, "bonds and scenes survive save/load")
			if failures.is_empty():
				print("BONDS OK bonds=", GameState.bond_points, " duos=", GameState.unlocked_duo_recipes())
				get_tree().quit(0)
			else:
				print("BONDS FAIL ", failures)
				get_tree().quit(1)
