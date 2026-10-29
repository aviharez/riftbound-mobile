extends Node
## Core-loop flow: title → academy → building panel → repair → Rift → result → back at the academy.
## Saves a screenshot of each step (run-and-observe evidence). Loaded at runtime by tools/run_runner.gd
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
	prefix += "-loop"


func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := "%s/%s-%s-%dx%d.png" % [out_dir, prefix, name, img.get_width(), img.get_height()]
	img.save_png(path if path.begins_with("/") else ProjectSettings.globalize_path("res://" + path))
	print("SHOT ", path, " resources=", GameState.resources(), " library=", GameState.building_level(&"library"))


func _process(delta: float) -> void:
	t += delta
	if wait > 0.0:
		wait -= delta
		return
	var scene := get_tree().current_scene
	match phase:
		0:
			if t > 0.8 and scene is TitleScreen:
				shot("01-title"); wait = 0.3; phase = 1
		1:
			(scene as TitleScreen)._on_new_game(); phase = 2; t = 0.0
		2:
			if t > 1.0 and scene is AcademyScreen:
				shot("02-academy"); wait = 0.2; phase = 3
		3:
			GameState.add_resources(Vector3i(400, 160, 2))
			var lib: BuildingData = Registry.buildings[&"library"]
			(scene as AcademyScreen).map.tap(lib.map_rect.get_center())
			phase = 4; t = 0.0
		4:
			if (scene as AcademyScreen).overlays.is_open():
				shot("03-building-panel"); wait = 0.3; phase = 5
			elif t > 12.0:
				printerr("academy_runner: never arrived at the library"); get_tree().quit(1)
		5:
			(scene as AcademyScreen)._on_upgrade(&"library"); wait = 0.2; phase = 6
		6:
			shot("04-repaired"); wait = 0.2; phase = 7
		7:
			(scene as AcademyScreen).overlays.close(); phase = 8; t = 0.0
		8:
			if t > 0.4:
				shot("05-academy-restored"); wait = 0.2; phase = 9
		9:
			(scene as AcademyScreen)._enter_rift(); phase = 10; t = 0.0
		10:
			if t > 2.5 and scene is BattleScreen:
				shot("06-battle"); wait = 0.2; phase = 11; t = 0.0
		11:
			# Fight for a while at x3 so the result screen has rewards to show.
			var bs := scene as BattleScreen
			bs.battle.speed = 3
			if bs.state == BattleScreen.State.PLAYING:
				bs.battle.aim_at(Vector2(135.0 + sin(t) * 100.0, 150.0))
			elif bs.state == BattleScreen.State.LEVEL_UP:
				bs._on_card_chosen(bs.battle.offer_cards()[0])
			elif bs.state == BattleScreen.State.FUSION:
				bs._on_fusion_kept()
			if t > 10.0 and bs.state == BattleScreen.State.PLAYING:
				bs._retreat(); phase = 12; t = 0.0
		12:
			if t > 0.5:
				shot("07-result"); wait = 0.2; phase = 13
		13:
			(scene as BattleScreen).overlays.academy_pressed.emit(); phase = 14; t = 0.0
		14:
			if t > 1.0 and scene is AcademyScreen:
				shot("08-back-at-academy"); wait = 0.3; phase = 15
		15:
			print("LOOP OK runs=", GameState.runs, " resources=", GameState.resources())
			get_tree().quit(0)
