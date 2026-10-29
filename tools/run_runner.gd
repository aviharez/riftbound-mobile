extends SceneTree
## Launches the main scene plus a test runner node: godot -s res://tools/run_runner.gd -- --runner=res://tools/runners/<name>.gd
## Game scripts use the Registry autoload, which only exists once startup has registered it, so the typed
## runner is loaded here at runtime instead of being referenced statically (a static reference fails to compile).


func _initialize() -> void:
	var runner_path := ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--runner="):
			runner_path = arg.trim_prefix("--runner=")
	if runner_path == "":
		printerr("run_runner: pass --runner=res://tools/runners/<name>.gd after --")
		quit(2)
		return
	var scene: Node = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	var runner: Node = (load(runner_path) as GDScript).new()
	runner.name = "TestRunner"
	root.add_child(runner)
