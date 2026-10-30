extends Node
## Expeditions flow: board → detail (team rule) → Selene joins → send her to Whispering Woods → away → back → result
## with a clue → board. Screenshots each step. Loaded by tools/run_runner.gd with --scene=res://scenes/title/title_screen.tscn.

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
	prefix += "-expeditions"


func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := "%s/%s-%s-%dx%d.png" % [out_dir, prefix, name, img.get_width(), img.get_height()]
	img.save_png(path if path.begins_with("/") else ProjectSettings.globalize_path("res://" + path))
	print("SHOT ", path, " active=", GameState.expeditions_active.keys(), " clues=", GameState.clues_found, " res=", GameState.resources())


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
				GameState.add_resources(Vector3i(300, 150, 0))
				GameState.upgrade_building(&"library")
				(scene as AcademyScreen)._on_nav(&"expeditions"); wait = 0.3; phase = 2
		2:
			shot("01-board"); wait = 0.2; phase = 3
		3:
			var empty: Array[StringName] = [&"lyra"]
			(scene as AcademyScreen).expeditions.show_detail(&"whispering_woods", empty); wait = 0.3; phase = 4
		4:
			shot("02-detail-needs-someone-home"); wait = 0.2; phase = 5
		5:
			GameState.upgrade_building(&"dormitory")
			var team: Array[StringName] = [&"selene"]
			(scene as AcademyScreen).expeditions.show_detail(&"whispering_woods", team); wait = 0.3; phase = 6
		6:
			shot("03-detail-team"); wait = 0.2; phase = 7
		7:
			var team2: Array[StringName] = [&"selene"]
			if not GameState.start_expedition(&"whispering_woods", team2):
				printerr("expeditions_runner: could not start"); get_tree().quit(1); return
			(scene as AcademyScreen).expeditions.show_detail(&"whispering_woods"); wait = 1.2; phase = 8
		8:
			shot("04-away"); wait = 0.2; phase = 9
		9:
			(scene as AcademyScreen).expeditions.close(); wait = 1.2; phase = 10
		10:
			shot("05-academy-badge"); wait = 0.2; phase = 11
		11:
			GameState.debug_finish_expedition(&"whispering_woods")
			# Force a success for a deterministic screenshot of the clue.
			GameState.expeditions_active[&"whispering_woods"].success = true
			(scene as AcademyScreen).expeditions._claim(&"whispering_woods"); wait = 0.3; phase = 12
		12:
			shot("06-result"); wait = 0.2; phase = 13
		13:
			(scene as AcademyScreen).expeditions.show_board(); wait = 0.3; phase = 14
		14:
			shot("07-board-after"); wait = 0.2; phase = 15
		15:
			print("EXPEDITIONS OK clues=", GameState.clues_found, " resources=", GameState.resources())
			get_tree().quit(0)
