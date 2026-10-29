class_name AcademyScreen
extends Node
## Astralis Academy hub: walkable map in a pixel-perfect SubViewport, HUD and building panels on the UI layer.
## Tap the ground to walk, tap a building to walk to its door and open it. The Rift Gate starts a battle.

@onready var map: AcademyMap = $WorldContainer/WorldViewport/AcademyMap
@onready var hud: AcademyHud = $UI/Root/AcademyHud
@onready var overlays: AcademyOverlays = $UI/Root/AcademyOverlays

var _press_pos: Vector2 = Vector2.INF


func _ready() -> void:
	map.arrived_at_building.connect(_open_building)
	hud.prompt_pressed.connect(_open_building)
	hud.nav_pressed.connect(_on_nav)
	overlays.upgrade_pressed.connect(_on_upgrade)
	overlays.enter_rift_pressed.connect(_enter_rift)
	get_viewport().size_changed.connect(_layout)
	_layout()


func _layout() -> void:
	map.set_view_size(get_viewport().get_visible_rect().size)


func _process(_delta: float) -> void:
	hud.set_prompt(&"" if overlays.is_open() else map.building_in_reach())


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if overlays.is_open():
			overlays.close()
		else:
			GameState.go_to(GameState.SCENE_TITLE)


func _unhandled_input(event: InputEvent) -> void:
	if overlays.is_open():
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
	overlays.show_building(id)


func _on_upgrade(id: StringName) -> void:
	if GameState.upgrade_building(id):
		map.flash_building(id)
	overlays.show_building(id)


func _enter_rift() -> void:
	GameState.academy_spawn = Registry.buildings[&"rift_gate"].door_point()
	GameState.go_to(GameState.SCENE_BATTLE)


func _on_nav(tab: StringName) -> void:
	match tab:
		&"rift":
			_enter_rift()
		&"academy":
			overlays.close()
