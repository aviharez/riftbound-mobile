class_name AcademyMap
extends Node2D
## The walkable academy hub (placeholder art): ground, paths, fountain, buildings (ruined or restored by level)
## and the student avatar. Tap-to-walk; tapping a building walks to its door and reports arrival.
## Coordinates are hub world units; this node is offset by -camera_topleft so the camera follows the avatar.

signal arrived_at_building(id: StringName)

const AVATAR_RADIUS := 4.0

var avatar: Vector2 = Vector2(150, 400)
var camera_topleft: Vector2 = Vector2.ZERO
var view_size: Vector2 = Vector2(270, 560)
var font: Font
var _target: Vector2 = Vector2.INF
var _pending_building: StringName = &""
var _facing: float = 1.0
var _walk_t: float = 0.0
var _time: float = 0.0
var _highlight: StringName = &""
var _highlight_t: float = 0.0


func _ready() -> void:
	font = UiTheme.pixel_font()
	var eco := Registry.economy
	avatar = GameState.academy_spawn if GameState.academy_spawn != Vector2.INF else eco.hub_spawn
	_update_camera()


func set_view_size(s: Vector2) -> void:
	view_size = s
	_update_camera()


func screen_to_world(screen_pos: Vector2) -> Vector2:
	return screen_pos + camera_topleft


## Handles a tap at a hub-world position.
func tap(p: Vector2) -> void:
	var id := building_at(p)
	if id != &"":
		_target = Registry.buildings[id].door_point()
		_pending_building = id
	else:
		_target = _clamp_to_bounds(p)
		_pending_building = &""


func building_at(p: Vector2) -> StringName:
	for id: StringName in Registry.buildings:
		var b: BuildingData = Registry.buildings[id]
		if b.map_rect.grow(4.0).has_point(p):
			return id
	return &""


## Building whose door the avatar is standing at, or &"".
func building_in_reach() -> StringName:
	for id: StringName in Registry.buildings:
		if avatar.distance_to(Registry.buildings[id].door_point()) <= Registry.economy.interact_distance * 2.0:
			return id
	return &""


func flash_building(id: StringName) -> void:
	_highlight = id
	_highlight_t = 0.8


func _process(delta: float) -> void:
	_time += delta
	_highlight_t = maxf(0.0, _highlight_t - delta)
	if _target != Vector2.INF:
		var to := _target - avatar
		var step := Registry.economy.walk_speed * delta
		if to.length() <= step:
			_move_to(_target)
			_target = Vector2.INF
			_walk_t = 0.0
			if _pending_building != &"":
				var id := _pending_building
				_pending_building = &""
				arrived_at_building.emit(id)
		else:
			var dir := to.normalized()
			if absf(dir.x) > 0.2:
				_facing = signf(dir.x)
			if not _move_to(avatar + dir * step):
				_target = Vector2.INF  # blocked: stop
				_pending_building = &""
			_walk_t += delta
	_update_camera()
	queue_redraw()


## Moves the avatar with simple sliding collision against building footprints. Returns false if fully blocked.
func _move_to(p: Vector2) -> bool:
	p = _clamp_to_bounds(p)
	if not _blocked(p):
		avatar = p
		return true
	var slide_x := Vector2(p.x, avatar.y)
	if not _blocked(slide_x):
		avatar = slide_x
		return true
	var slide_y := Vector2(avatar.x, p.y)
	if not _blocked(slide_y):
		avatar = slide_y
		return true
	return false


func _blocked(p: Vector2) -> bool:
	for id: StringName in Registry.buildings:
		if Registry.buildings[id].map_rect.grow(AVATAR_RADIUS).has_point(p):
			return true
	if p.distance_to(Registry.economy.fountain_pos) < 22.0 + AVATAR_RADIUS:
		return true
	return false


func _clamp_to_bounds(p: Vector2) -> Vector2:
	var hub := Registry.economy.hub_size
	return p.clamp(Vector2(14, 20), hub - Vector2(14, 12))


func _update_camera() -> void:
	var hub := Registry.economy.hub_size
	var tl := avatar - view_size * 0.5
	tl.x = (hub.x - view_size.x) * 0.5 if view_size.x >= hub.x else clampf(tl.x, 0.0, hub.x - view_size.x)
	tl.y = (hub.y - view_size.y) * 0.5 if view_size.y >= hub.y else clampf(tl.y, 0.0, hub.y - view_size.y)
	camera_topleft = tl.round()
	position = -camera_topleft


# ================================================================= drawing

func _draw() -> void:
	var hub := Registry.economy.hub_size
	var fountain := Registry.economy.fountain_pos
	# Outside the map (screens larger than the hub): dark forest.
	draw_rect(Rect2(camera_topleft - Vector2(8, 8), view_size + Vector2(16, 16)), Color("0e1512"))
	# Ground: grass tiles with variation.
	var t := 16
	for y in range(0, int(hub.y), t):
		for x in range(0, int(hub.x), t):
			var h := absi(hash(Vector2i(x, y))) % 7
			var g := Color("1f2e26") if h < 3 else (Color("223329") if h < 6 else Color("26392d"))
			draw_rect(Rect2(x, y, t, t), g)
	# Courtyard paths from the fountain to each door.
	var path_col := Color("3a3a44")
	draw_circle(fountain, 46.0, path_col)
	for id: StringName in Registry.buildings:
		var door: Vector2 = Registry.buildings[id].door_point()
		_draw_path(fountain, door, path_col)
	# Fountain.
	draw_circle(fountain, 22.0, Color("55525e"))
	draw_circle(fountain, 18.0, Color("2b5866"))
	draw_circle(fountain, 18.0 - 2.0 * (1.0 + sin(_time * 2.0)), Color(UiTheme.CYAN, 0.35))
	draw_rect(Rect2(fountain - Vector2(2, 9), Vector2(4, 9)), Color("6a6676"))
	draw_circle(fountain - Vector2(0, 10), 2.0, Color(UiTheme.CYAN, 0.8))
	# Trees along the edges.
	for i in 22:
		var tp := Vector2(fmod(float(i) * 97.0, hub.x), 0.0)
		tp.y = 6.0 if i % 2 == 0 else hub.y - 14.0
		if i % 3 == 0:
			tp = Vector2(6.0 if i % 2 == 0 else hub.x - 8.0, fmod(float(i) * 61.0, hub.y))
		_draw_tree(tp.round())
	# Buildings (back to front by y).
	var ids: Array = Registry.buildings.keys()
	ids.sort_custom(func(a: StringName, b: StringName) -> bool: return Registry.buildings[a].map_rect.position.y < Registry.buildings[b].map_rect.position.y)
	for id: StringName in ids:
		_draw_building(Registry.buildings[id])
	# Tap target marker.
	if _target != Vector2.INF:
		var r := 3.0 + 1.0 * sin(_time * 8.0)
		draw_arc(_target.round(), r, 0.0, TAU, 12, Color(UiTheme.CYAN, 0.8), 1.0)
	_draw_avatar()


func _draw_path(a: Vector2, b: Vector2, c: Color) -> void:
	var mid := Vector2(b.x, a.y)
	var w := 14.0
	draw_rect(Rect2(Vector2(minf(a.x, mid.x), a.y - w * 0.5), Vector2(absf(mid.x - a.x), w)), c)
	draw_rect(Rect2(Vector2(b.x - w * 0.5, minf(mid.y, b.y)), Vector2(w, absf(b.y - mid.y) + 2.0)), c)


func _draw_tree(p: Vector2) -> void:
	draw_rect(Rect2(p + Vector2(-1, 2), Vector2(3, 5)), Color("3b2a1e"))
	draw_circle(p, 6.0, Color("163021"))
	draw_circle(p + Vector2(-1, -1), 4.0, Color("1d3d2a"))


func _draw_building(b: BuildingData) -> void:
	var lv := GameState.building_level(b.id)
	var r := b.map_rect
	var ruined := lv <= 0
	var x := r.position.x
	var y := r.position.y
	var w := r.size.x
	var h := r.size.y
	var roof_h := roundf(h * 0.38)
	# Shadow
	draw_rect(Rect2(x + 3, y + h - 2, w, 5), Color(0, 0, 0, 0.35))
	if b.is_rift_gate:
		_draw_gate(b, lv)
	else:
		var wall := Color("3a3640") if ruined else Color("5d566c")
		draw_rect(Rect2(x, y + roof_h, w, h - roof_h), wall)
		draw_rect(Rect2(x, y + roof_h, w, 2), wall.lightened(0.15))
		if ruined:
			# Broken roof: jagged dark stubs, rubble.
			var dark := Color("26222c")
			var k := 0.0
			while k < w:
				var stub := roof_h * (0.3 + 0.6 * float(absi(hash(Vector2i(int(x + k), int(y)))) % 10) / 10.0)
				draw_rect(Rect2(x + k, y + roof_h - stub, minf(10.0, w - k), stub), dark)
				k += 10.0
			for i in 6:
				var rp := Vector2(x + float(absi(hash(i * 13 + int(x))) % int(w)), y + h + 1.0 + float(i % 3))
				draw_rect(Rect2(rp, Vector2(3, 2)), Color("4a4552"))
			draw_line(Vector2(x + w * 0.3, y + roof_h + 4), Vector2(x + w * 0.4, y + h - 6), Color("1b1820"), 1.0)
			draw_line(Vector2(x + w * 0.7, y + roof_h + 8), Vector2(x + w * 0.62, y + h - 4), Color("1b1820"), 1.0)
		else:
			var roof := b.roof_color
			draw_colored_polygon(PackedVector2Array([Vector2(x - 4, y + roof_h), Vector2(x + w * 0.5, y - 4), Vector2(x + w + 4, y + roof_h)]), roof.darkened(0.25))
			draw_colored_polygon(PackedVector2Array([Vector2(x, y + roof_h - 1), Vector2(x + w * 0.5, y + 1), Vector2(x + w, y + roof_h - 1)]), roof)
			# Banner for each level above 1.
			for i in range(1, lv):
				draw_rect(Rect2(x + 6 + float(i - 1) * 8.0, y + roof_h + 4, 4, 9), UiTheme.GOLD)
		# Windows: lit count = level.
		var n := 4
		for i in n:
			var wx := x + 8.0 + float(i) * (w - 16.0) / float(n - 1) - 3.0
			var lit := i < lv + (1 if lv > 0 else 0)
			var flicker := 0.85 + 0.15 * sin(_time * 3.0 + float(i))
			draw_rect(Rect2(wx, y + roof_h + 10, 6, 8), Color(Color("ffd27a"), flicker) if lit and not ruined else Color("15131a"))
		# Door
		draw_rect(Rect2(x + w * 0.5 - 5, y + h - 14, 10, 14), Color("1b1820") if ruined else Color("3b2a1e"))
	# Highlight after an upgrade.
	if _highlight == b.id and _highlight_t > 0.0:
		draw_rect(r.grow(3.0), Color(UiTheme.GOLD, _highlight_t), false, 2.0)
	# Name plate + status.
	var label := b.display_name.to_upper()
	var status := "RUINED" if ruined else "LV%d" % lv
	draw_string(font, Vector2(x - 20, y + h + 16), label, HORIZONTAL_ALIGNMENT_CENTER, w + 40, 8, UiTheme.PARCH)
	draw_string(font, Vector2(x - 20, y + h + 25), status, HORIZONTAL_ALIGNMENT_CENTER, w + 40, 8, UiTheme.DANGER if ruined else UiTheme.GOLD)
	# "!" when the next level is affordable.
	if GameState.can_upgrade(b.id):
		var bp := Vector2(x + w - 4, y - 6 + roundf(sin(_time * 4.0) * 2.0))
		draw_circle(bp, 6.0, UiTheme.GOLD)
		draw_string(font, bp + Vector2(-6, 3), "!", HORIZONTAL_ALIGNMENT_CENTER, 12, 8, UiTheme.INK)


func _draw_gate(b: BuildingData, lv: int) -> void:
	var r := b.map_rect
	var c := r.get_center() + Vector2(0, 4)
	var stone := Color("4a4556")
	draw_rect(Rect2(r.position.x, r.position.y + 10, 14, r.size.y - 10), stone)
	draw_rect(Rect2(r.end.x - 14, r.position.y + 10, 14, r.size.y - 10), stone)
	draw_rect(Rect2(r.position.x - 4, r.position.y, r.size.x + 8, 12), stone.darkened(0.2))
	for i in 5:
		var rr := 26.0 - float(i) * 5.0 + sin(_time * 2.0 + float(i)) * 1.5
		draw_circle(c, rr, Color(UiTheme.VIOLET, 0.25 + 0.12 * float(i)))
	draw_circle(c, 4.0, Color(0.9, 0.85, 1.0, 0.9))
	for i in lv:
		draw_rect(Rect2(r.position.x + 18 + float(i) * 8.0, r.position.y + 3, 5, 5), UiTheme.GOLD)


func _draw_avatar() -> void:
	var p := avatar.round()
	var bob := roundf(absf(sin(_walk_t * 10.0))) if _target != Vector2.INF else 0.0
	draw_rect(Rect2(p.x - 5, p.y + 6, 10, 2), Color(0, 0, 0, 0.4))
	draw_rect(Rect2(p.x - 4, p.y - 2 - bob, 8, 8), Color("24306a"))
	draw_rect(Rect2(p.x - 4, p.y + 5 - bob, 8, 1), UiTheme.GOLD)
	draw_rect(Rect2(p.x - 2, p.y - 7 - bob, 5, 5), Color("f1d3bd"))
	draw_rect(Rect2(p.x - 3, p.y - 9 - bob, 7, 3), Color("c7432c"))
	draw_rect(Rect2(p.x - 3 if _facing > 0.0 else p.x + 2, p.y - 7 - bob, 2, 6), Color("c7432c"))
	draw_rect(Rect2(p.x + (2 if _facing > 0.0 else -3), p.y - 5 - bob, 1, 1), Color("3a2a1e"))
