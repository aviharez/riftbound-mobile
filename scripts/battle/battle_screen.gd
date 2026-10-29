class_name BattleScreen
extends Node
## Rift battle screen and its flow. Hosts the pixel-perfect world SubViewport and the native-resolution UI layer,
## routes touch input to the Battle, and switches between playing / paused / level-up / fusion / result.
## A run starts as soon as the screen opens, with the academy's building bonuses (GameState.run_bonuses()).
##
## Display pipeline (docs/art-spec.md §2): stretch canvas_items + expand + integer, base 270x560.
## The SubViewport matches the visible area in base units; the fixed 270x560 playfield is centered
## horizontally and anchored to the bottom. Input arrives in root coordinates: convert with screen_to_world().

enum State { PLAYING, PAUSED, LEVEL_UP, FUSION, OVER }

@onready var world: World = $WorldContainer/WorldViewport/World
@onready var battle: Battle = $WorldContainer/WorldViewport/World/Battle
@onready var hud: Hud = $UI/Root/Hud
@onready var overlays: Overlays = $UI/Root/Overlays

## Top-left of the playfield inside the visible area, in base units.
var world_offset: Vector2 = Vector2.ZERO
var settings: PlayerSettings
var state: State = State.PLAYING
## Active touches: index -> {pos: Vector2 (playfield coords), role: StringName}.
var _touches: Dictionary = {}


func _ready() -> void:
	settings = PlayerSettings.create(Registry.balance)
	battle.setup(settings, UiTheme.pixel_font())
	hud.battle = battle
	hud.settings = settings
	hud.touches = _touches
	battle.level_up_ready.connect(_on_level_up_ready)
	battle.fusion_ready.connect(_on_fusion_ready)
	battle.run_ended.connect(_on_run_ended)
	overlays.again_pressed.connect(_start_run)
	overlays.academy_pressed.connect(func() -> void: GameState.go_to(GameState.SCENE_ACADEMY))
	overlays.retreat_pressed.connect(_retreat)
	overlays.resume_pressed.connect(_resume)
	overlays.card_chosen.connect(_on_card_chosen)
	overlays.reroll_pressed.connect(func() -> void: overlays.show_level_up(battle, battle.reroll_cards()))
	overlays.fusion_chosen.connect(_on_fusion_chosen)
	overlays.fusion_kept.connect(_on_fusion_kept)
	overlays.open_fusion_pressed.connect(_open_fusion)
	overlays.debug_action.connect(_on_debug_action)
	get_viewport().size_changed.connect(_layout)
	_layout()
	_start_run()


## Converts a position from root/UI coordinates to playfield (world) coordinates.
func screen_to_world(screen_pos: Vector2) -> Vector2:
	return screen_pos - world_offset


func _process(_delta: float) -> void:
	world.position = world_offset + battle.shake_offset()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and state == State.PLAYING:
		_pause()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if state == State.PLAYING:
			_pause()
		elif state == State.PAUSED:
			_resume()


func _layout() -> void:
	var visible := get_viewport().get_visible_rect().size
	var playfield := Vector2(Registry.balance.world_size)
	world_offset = Vector2(floorf((visible.x - playfield.x) * 0.5), floorf(visible.y - playfield.y))
	world.position = world_offset
	world.set_visible_rect(Rect2(-world_offset, visible))
	hud.offset = world_offset
	hud.visible_size = visible


func _set_state(s: State) -> void:
	state = s
	battle.active = s == State.PLAYING
	if s != State.PLAYING:
		_touches.clear()


# ================================================================= flow

func _start_run() -> void:
	overlays.close()
	battle.start_run(GameState.current_student(), GameState.run_bonuses())
	_set_state(State.PLAYING)


func _pause() -> void:
	_set_state(State.PAUSED)
	overlays.show_pause(battle, settings)


func _resume() -> void:
	settings.save()
	overlays.close()
	_set_state(State.PLAYING)


func _retreat() -> void:
	settings.save()
	_end_run(true)


func _on_level_up_ready() -> void:
	_set_state(State.LEVEL_UP)
	overlays.show_level_up(battle, battle.offer_cards())


func _on_card_chosen(card: LevelCard) -> void:
	battle.apply_card(card)
	if battle.pending_levels > 0:
		overlays.show_level_up(battle, battle.offer_cards())
	else:
		overlays.close()
		_set_state(State.PLAYING)


func _on_fusion_ready() -> void:
	_open_fusion()


func _open_fusion() -> void:
	_set_state(State.FUSION)
	overlays.show_fusion(battle)


func _on_fusion_chosen(pair: Vector2i) -> void:
	overlays.close()
	_set_state(State.PLAYING)
	battle.apply_fusion(pair)


func _on_fusion_kept() -> void:
	battle.snooze_fusion()
	overlays.close()
	_set_state(State.PLAYING)


func _on_run_ended() -> void:
	_set_state(State.OVER)
	await get_tree().create_timer(0.5).timeout
	if state == State.OVER:
		_end_run(false)


## Banks the run's rewards and shows the result screen.
func _end_run(retreated: bool) -> void:
	_set_state(State.OVER)
	battle.over = true
	var rewards := GameState.finish_run(battle.kills, battle.wave, battle.bosses, battle.shards, retreated)
	overlays.show_result(battle, rewards, retreated)


func _on_debug_action(action: StringName) -> void:
	match action:
		&"baby": battle.debug_add_baby_balls(10)
		&"level":
			battle.debug_add_level()
			_resume()
			return
		&"max_balls": battle.debug_max_balls()
		&"prism": battle.debug_add_prism()
		&"ultimate": battle.energy = Registry.balance.energy_max
		&"restart":
			_start_run()
			return
	overlays.show_pause(battle, settings)


# ================================================================= input

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var k := event as InputEventKey
		if k.pressed and not k.echo:
			if k.physical_keycode == KEY_ESCAPE:
				if state == State.PLAYING:
					_pause()
				elif state == State.PAUSED:
					_resume()
			elif k.physical_keycode == KEY_SPACE:
				battle.cast_ultimate()
		return
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			_touch_down(t.index, screen_to_world(t.position))
		else:
			_touches.erase(t.index)
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		_touch_move(d.index, screen_to_world(d.position))


## The touch role is decided by where it starts and kept for the whole drag (combat-spec §2).
func _touch_down(index: int, p: Vector2) -> void:
	if state != State.PLAYING:
		return
	if hud.speed_rect().grow(4.0).has_point(p):
		battle.speed = battle.speed % 3 + 1
		return
	if hud.pause_rect().grow(4.0).has_point(p):
		_pause()
		return
	if p.distance_to(hud.ult_center()) < Hud.ULT_RADIUS + 6.0:
		battle.cast_ultimate()
		_touches[index] = {"pos": p, "role": &"skill"}
		return
	var role := &"move" if p.y >= Registry.balance.rune_line_y - settings.zone_tolerance else &"aim"
	_touches[index] = {"pos": p, "role": role}
	if role == &"aim" and settings.aim_mode == PlayerSettings.AIM_ABSOLUTE:
		battle.aim_at(p)


func _touch_move(index: int, p: Vector2) -> void:
	if not _touches.has(index):
		return
	var t: Dictionary = _touches[index]
	var delta: Vector2 = p - t.pos
	t.pos = p
	if state != State.PLAYING:
		return
	match t.role:
		&"move":
			battle.move_by(delta)
		&"aim":
			if settings.aim_mode == PlayerSettings.AIM_ABSOLUTE:
				battle.aim_at(p)
			else:
				battle.rotate_aim(delta.x)
