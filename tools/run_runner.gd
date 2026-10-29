extends SceneTree
## Launches a scene plus a test runner node:
##   godot -s res://tools/run_runner.gd -- --runner=res://tools/runners/<name>.gd [--scene=res://...tscn]
## The default scene is the battle screen. Runners use a throwaway save (GameState.use_test_save()).
## Game scripts use the Registry autoload, which only exists once startup has registered it, so the typed
## runner is loaded here at runtime instead of being referenced statically (a static reference fails to compile).


func _initialize() -> void:
	var runner_path := ""
	var scene_path := "res://scenes/battle/battle_screen.tscn"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--runner="):
			runner_path = arg.trim_prefix("--runner=")
		elif arg.begins_with("--scene="):
			scene_path = arg.trim_prefix("--scene=")
	if runner_path == "":
		printerr("run_runner: pass --runner=res://tools/runners/<name>.gd after --")
		quit(2)
		return
	root.get_node("GameState").call("use_test_save")
	var scene: Node = (load(scene_path) as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	var runner: Node = (load(runner_path) as GDScript).new()
	runner.name = "TestRunner"
	root.add_child(runner)
