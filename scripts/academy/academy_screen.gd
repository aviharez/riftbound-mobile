class_name AcademyScreen
extends Node
## Astralis Academy hub: walkable map in a pixel-perfect SubViewport, HUD and building panels on the UI layer.
## Tap the ground to walk, tap a building to walk to its door and open it. The Rift Gate starts a battle.

@onready var map: AcademyMap = $WorldContainer/WorldViewport/AcademyMap
@onready var hud: AcademyHud = $UI/Root/AcademyHud
@onready var overlays: AcademyOverlays = $UI/Root/AcademyOverlays
@onready var expeditions: ExpeditionOverlays = $UI/Root/ExpeditionOverlays
@onready var stories: StoriesOverlays = $UI/Root/StoriesOverlays
@onready var dialogue: DialoguePlayer = $UI/Root/DialoguePlayer

var _press_pos: Vector2 = Vector2.INF
## Scene being played and whether it is a replay (replays pay no bond points).
var _playing: StringName = &""
var _replay: bool = false


func _ready() -> void:
	map.arrived_at_building.connect(_open_building)
	hud.prompt_pressed.connect(_open_building)
	hud.nav_pressed.connect(_on_nav)
	overlays.upgrade_pressed.connect(_on_upgrade)
	overlays.enter_rift_pressed.connect(_enter_rift)
	overlays.student_select_pressed.connect(func(id: StringName) -> void:
		GameState.select_student(id)
		overlays.show_profile(id))
	overlays.student_upgrade_pressed.connect(func(id: StringName) -> void:
		GameState.upgrade_student(id)
		overlays.show_profile(id))
	overlays.talk_pressed.connect(func(id: StringName) -> void: _play_scene(id, false))
	stories.replay_pressed.connect(func(id: StringName) -> void: _play_scene(id, true))
	stories.dormitory_pressed.connect(func() -> void: _open_building(&"dormitory"))
	dialogue.finished.connect(_on_scene_finished)
	get_viewport().size_changed.connect(_layout)
	_layout()


func _layout() -> void:
	map.set_view_size(get_viewport().get_visible_rect().size)


func _process(_delta: float) -> void:
	hud.set_prompt(&"" if _modal_open() else map.building_in_reach())


func _modal_open() -> bool:
	return overlays.is_open() or expeditions.is_open() or stories.is_open() or dialogue.is_open()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if dialogue.is_open():
			dialogue.close()  # leaving a scene early doesn't count it as watched
			_playing = &""
		elif _modal_open():
			_close_modals()
		else:
			GameState.go_to(GameState.SCENE_TITLE)


func _unhandled_input(event: InputEvent) -> void:
	if _modal_open():
		return
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			_press_pos = t.position
		elif _press_pos != Vector2.INF:
			# A tap (not a drag) on the map, outside the HUD.
			if t.position.distance_to(_press_pos) < 8.0 and not hud.covers(t.position):
				map.tap(map.screen_to_world(t.position))
			_press_pos = Vector2.INF
	elif event is InputEventKey:
		var k := event as InputEventKey
		if k.pressed and not k.echo and k.physical_keycode == KEY_ESCAPE:
			GameState.go_to(GameState.SCENE_TITLE)


func _open_building(id: StringName) -> void:
	if id == &"":
		return
	_close_modals()
	overlays.show_building(id)


func _on_upgrade(id: StringName) -> void:
	if GameState.upgrade_building(id):
		map.flash_building(id)
		if id == &"dormitory":
			var joined := GameState.students_joining_at(GameState.building_level(id))
			if not joined.is_empty():
				overlays.show_joined(joined)
				return
	overlays.show_building(id)


func _enter_rift() -> void:
	GameState.academy_spawn = Registry.buildings[&"rift_gate"].door_point()
	GameState.go_to(GameState.SCENE_BATTLE)


func _on_nav(tab: StringName) -> void:
	match tab:
		&"rift":
			_enter_rift()
		&"academy":
			_close_modals()
		&"characters":
			_close_modals()
			overlays.show_roster()
		&"expeditions":
			_close_modals()
			expeditions.show_board()
		&"stories":
			_close_modals()
			stories.show_stories()


func _close_modals() -> void:
	overlays.close()
	expeditions.close()
	stories.close()


func _play_scene(id: StringName, replay: bool) -> void:
	var d := Registry.dialogue(id)
	if d == null:
		return
	_close_modals()
	_playing = id
	_replay = replay
	dialogue.play(d)


func _on_scene_finished(choice_index: int) -> void:
	var id := _playing
	_playing = &""
	if id == &"":
		return
	if _replay:
		stories.show_stories()
		return
	var result := GameState.finish_scene(id, choice_index)
	if result.is_empty():
		_open_building(&"dormitory")
	else:
		stories.show_bond_result(Registry.dialogue(id), result)
