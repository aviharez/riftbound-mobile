extends Node
## Students flow: roster → Lyra profile → repair Dormitory → Selene joins → select Selene → Frost Nova in battle
## → back → Dormitory Lv2 → Noah joins → Verdant Bloom. Screenshots each step. Loaded by tools/run_runner.gd
## with --scene=res://scenes/title/title_screen.tscn. Uses a throwaway save.

var out_dir := "docs/qa/evidence"
var prefix := "flow"
var t := 0.0
var wait := 0.0
var phase := 0


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out_dir = arg.trim_prefix("--out=")
		elif arg.begins_with("--prefix="):
			prefix = arg.trim_prefix("--prefix=")
	prefix += "-students"


func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := "%s/%s-%s-%dx%d.png" % [out_dir, prefix, name, img.get_width(), img.get_height()]
	img.save_png(path if path.begins_with("/") else ProjectSettings.globalize_path("res://" + path))
	print("SHOT ", path, " student=", GameState.selected_student, " dorm=", GameState.building_level(&"dormitory"))


func _process(delta: float) -> void:
	t += delta
	if wait > 0.0:
		wait -= delta
		return
	var scene := get_tree().current_scene
	match phase:
		0:
			if t > 0.6 and scene is TitleScreen:
				(scene as TitleScreen)._on_new_game(); phase = 1; t = 0.0
		1:
			if t > 0.8 and scene is AcademyScreen:
				GameState.add_resources(Vector3i(600, 300, 3))
				(scene as AcademyScreen)._on_nav(&"characters"); wait = 0.3; phase = 2
		2:
			shot("01-roster"); wait = 0.2; phase = 3
		3:
			(scene as AcademyScreen).overlays.show_profile(&"lyra"); wait = 0.3; phase = 4
		4:
			shot("02-profile-lyra"); wait = 0.2; phase = 5
		5:
			(scene as AcademyScreen)._on_upgrade(&"dormitory"); wait = 0.3; phase = 6
		6:
			shot("03-selene-joins"); wait = 0.2; phase = 7
		7:
			(scene as AcademyScreen).overlays.student_select_pressed.emit(&"selene"); wait = 0.3; phase = 8
		8:
			shot("04-profile-selene"); wait = 0.2; phase = 9
		9:
			(scene as AcademyScreen).overlays.close()
			(scene as AcademyScreen)._enter_rift(); phase = 10; t = 0.0
		10:
			if t > 2.0 and scene is BattleScreen:
				var bs := scene as BattleScreen
				bs.battle.energy = Registry.balance.energy_max
				bs.battle.cast_ultimate(); phase = 11; t = 0.0
		11:
			if t > 0.2:
				shot("05-frost-nova"); wait = 0.2; phase = 12
		12:
			(scene as BattleScreen)._retreat(); phase = 13; t = 0.0
		13:
			if t > 0.4:
				(scene as BattleScreen).overlays.academy_pressed.emit(); phase = 14; t = 0.0
		14:
			if t > 0.8 and scene is AcademyScreen:
				(scene as AcademyScreen)._on_upgrade(&"dormitory"); wait = 0.3; phase = 15
		15:
			shot("06-noah-joins"); wait = 0.2; phase = 16
		16:
			GameState.select_student(&"noah")
			(scene as AcademyScreen).overlays.close()
			(scene as AcademyScreen)._enter_rift(); phase = 17; t = 0.0
		17:
			if t > 6.0 and scene is BattleScreen:
				var bs := scene as BattleScreen
				bs.battle.energy = Registry.balance.energy_max
				bs.battle.cast_ultimate(); phase = 18; t = 0.0
			elif scene is BattleScreen:
				var bs2 := scene as BattleScreen
				if bs2.state == BattleScreen.State.LEVEL_UP:
					bs2._on_card_chosen(bs2.battle.offer_cards()[0])
		18:
			if t > 0.2:
				shot("07-verdant-bloom"); wait = 0.3; phase = 19
		19:
			print("STUDENTS OK selected=", GameState.selected_student, " levels=", GameState.student_levels)
			get_tree().quit(0)
