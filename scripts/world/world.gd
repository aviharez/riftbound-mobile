class_name World
extends Node2D
## Static arena backdrop (placeholder art until M7): floor, walls, ceiling, Rift glow, move zone and rune line.
## Coordinates are playfield-local (0,0 = top-left of the 270x560 playfield). Any extra visible area
## (wider/taller screens) is filled with wall stone. The Battle node draws on top of this.

const COL_OUTER := Color("0f0f17")
const COL_WALL_A := Color("16161f")
const COL_WALL_B := Color("191a24")
const COL_TRIM := Color(0.902, 0.741, 0.451, 0.3)       # Academy Gold, dimmed
const COL_RUNE := Color(0.902, 0.741, 0.451, 0.55)
const COL_ZONE := Color(0.412, 0.847, 0.910, 0.04)       # Arcane Cyan tint
const COL_RIFT := Color(0.435, 0.290, 0.902)             # Rift Violet
const FLOOR_SHADES: Array[Color] = [Color("262834"), Color("232530"), Color("292b38"), Color("24262f"), Color("2a2c37")]
const TILE := 16
## Darkens the floor art so it stays mid-dark behind enemies and balls.
const FLOOR_TINT := Color(0.8, 0.8, 0.85)
## Cells of the floor sheet with the same terrain on all four corners (assets/art/tiles/arena_floor.png,
## a blue-grey recolour of the PixelLab sheet arena_floor_wang.png made with tools/art/recolor.py),
## so they tile seamlessly in any order. The sheet's transition tiles are not used yet.
const FLOOR_CELLS: Array[Vector2i] = [Vector2i(0, 0), Vector2i(3, 3)]

## PixelLab floor tileset (16x16 cells). Null = flat placeholder shades.
@export var floor_sheet: Texture2D = preload("res://assets/art/tiles/arena_floor.png")
## Decorations along the bottom of the move zone and beside the Rift: [texture, position, alpha].
## Kept dim and out of the enemies' lanes so projectiles stay the brightest thing on screen (art-spec §4).
var _props: Array = [
	[preload("res://assets/art/props/rubble.png"), Vector2(14, 530), 0.85],
	[preload("res://assets/art/props/crystals.png"), Vector2(40, 6), 0.55],
	[preload("res://assets/art/props/crystals.png"), Vector2(200, 6), 0.55],
]

## Painted arena (PixelLab Pro, redrawn at native 270 px, floor extended; see assets/art/CREDITS.md).
## Covers world x -45..315 and y -116..564; its stage starts exactly at the rune line (y 455).
## Null = the older code-drawn arena below.
@export var arena_backdrop: Texture2D = preload("res://assets/art/arena/rift_arena.png")
const ARENA_ORIGIN := Vector2(-45, -116)
## Torches and braziers in the painted arena (world coordinates), lit by FxGlow.
const ARENA_TORCHES: Array[Vector2] = [Vector2(86, 114), Vector2(183, 114), Vector2(48, 135), Vector2(221, 135),
	Vector2(31, 183), Vector2(237, 183), Vector2(20, 500), Vector2(249, 500)]
## The painted portal's swirl, animated by the portal shader on top.
const ARENA_PORTAL := Rect2(113, 52, 44, 56)

## Visible area in playfield coordinates. Set by Main whenever the screen size changes.
var visible_rect: Rect2 = Rect2(0, 0, 270, 560)
var _portal: ColorRect
var _vignette: ColorRect


func _ready() -> void:
	var b := Registry.balance
	# Rift portal (shader) behind the enemies, centred on the ceiling.
	_portal = ColorRect.new()
	_portal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if arena_backdrop:
		_portal.size = ARENA_PORTAL.size
		_portal.position = ARENA_PORTAL.position
	else:
		_portal.size = Vector2(96, 40)
		_portal.position = Vector2(float(b.world_size.x) * 0.5 - 48.0, b.ceiling_y - 14.0)
	var pm := ShaderMaterial.new()
	pm.shader = preload("res://assets/shaders/portal.gdshader")
	pm.set_shader_parameter(&"opacity", 0.55 if arena_backdrop else 1.0)
	_portal.material = pm
	add_child(_portal)
	move_child(_portal, 0)
	# Dithered vignette over everything in the world.
	_vignette = ColorRect.new()
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vm := ShaderMaterial.new()
	vm.shader = preload("res://assets/shaders/vignette.gdshader")
	_vignette.material = vm
	_vignette.z_index = 2
	add_child(_vignette)
	_layout_overlays()


func set_visible_rect(r: Rect2) -> void:
	visible_rect = r
	_layout_overlays()
	queue_redraw()


func _layout_overlays() -> void:
	if _vignette:
		_vignette.position = visible_rect.position
		_vignette.size = visible_rect.size


## Torch positions on the walls (playfield coordinates); FxGlow lights them.
func torch_points() -> Array[Vector2]:
	if arena_backdrop:
		return ARENA_TORCHES
	var b := Registry.balance
	var wall := float(b.wall_width)
	var out: Array[Vector2] = []
	var y := b.ceiling_y + 70.0
	while y < b.rune_line_y:
		out.append(Vector2(wall * 0.5, y))
		out.append(Vector2(float(b.world_size.x) - wall * 0.5, y))
		y += 130.0
	return out


func _draw() -> void:
	if arena_backdrop:
		# Sky colour above the painting on very tall screens, then the painted arena.
		draw_rect(visible_rect, Color("10101c"))
		draw_texture(arena_backdrop, ARENA_ORIGIN)
		return
	var b := Registry.balance
	var size := Vector2(b.world_size)
	var wall := float(b.wall_width)
	var field := Rect2(wall, 0.0, size.x - wall * 2.0, size.y)

	# Extra visible area + walls: gothic stone with offset blocks, banners and torches.
	draw_rect(visible_rect, COL_OUTER)
	_draw_wall(Rect2(visible_rect.position.x, visible_rect.position.y, field.position.x - visible_rect.position.x, visible_rect.size.y), false)
	_draw_wall(Rect2(field.end.x, visible_rect.position.y, visible_rect.end.x - field.end.x, visible_rect.size.y), true)

	# Field floor: 16 px tiles, desaturated so projectiles carry the color.
	var ty := 0
	while ty < int(size.y):
		var tx := int(field.position.x)
		while tx < int(field.end.x):
			if floor_sheet:
				var cell := FLOOR_CELLS[absi(hash(Vector2i(tx, ty))) % FLOOR_CELLS.size()]
				draw_texture_rect_region(floor_sheet, Rect2(tx, ty, TILE, TILE), Rect2(cell * TILE, Vector2(TILE, TILE)), FLOOR_TINT)
			else:
				var shade := FLOOR_SHADES[absi(hash(Vector2i(tx, ty))) % FLOOR_SHADES.size()]
				draw_rect(Rect2(tx + 1, ty + 1, TILE - 1, TILE - 1), shade)
			tx += TILE
		ty += TILE
	# Faint magic circle in the middle of the field.
	draw_arc(Vector2(size.x * 0.5, 225.0), 52.0, 0.0, TAU, 64, Color(0.412, 0.847, 0.910, 0.06), 1.0)
	draw_arc(Vector2(size.x * 0.5, 225.0), 40.0, 0.0, TAU, 48, Color(0.412, 0.847, 0.910, 0.06), 1.0)

	# Ceiling ledge (behind the HUD band, extends up into any extra area) and wall trims.
	draw_rect(Rect2(field.position.x, visible_rect.position.y, field.size.x, b.ceiling_y - visible_rect.position.y), Color("121219"))
	draw_rect(Rect2(field.position.x, b.ceiling_y - 1.0, field.size.x, 1.0), COL_TRIM)
	draw_rect(Rect2(field.position.x - 1.0, b.ceiling_y, 1.0, size.y - b.ceiling_y), COL_TRIM)
	draw_rect(Rect2(field.end.x, b.ceiling_y, 1.0, size.y - b.ceiling_y), COL_TRIM)

	# Rift glow at the top center.
	for i in 4:
		draw_circle(Vector2(size.x * 0.5, b.ceiling_y), 46.0 - float(i) * 10.0, Color(COL_RIFT, 0.06 + 0.05 * float(i)))

	for pr: Array in _props:
		var tex: Texture2D = pr[0]
		var pos: Vector2 = pr[1]
		if pos.y < b.ceiling_y:
			pos.y = b.ceiling_y - tex.get_height() + 4.0  # sits on the ceiling ledge
		draw_texture(tex, pos.round(), Color(1, 1, 1, pr[2]))

	# Move zone and rune line.
	draw_rect(Rect2(field.position.x, b.rune_line_y, field.size.x, size.y - b.rune_line_y), COL_ZONE)
	var x := field.position.x + 2.0
	while x < field.end.x:
		draw_rect(Rect2(x, b.rune_line_y, 3.0, 1.0), COL_RUNE)
		x += 6.0
	x = field.position.x + 17.0
	while x < field.end.x:
		draw_rect(Rect2(x, b.rune_line_y - 2.0, 1.0, 5.0), COL_RUNE)
		draw_rect(Rect2(x - 2.0, b.rune_line_y, 5.0, 1.0), COL_RUNE)
		x += 34.0


## A wall strip: stone blocks in staggered courses with a lit inner edge, banners and torch sconces.
func _draw_wall(r: Rect2, right_side: bool) -> void:
	if r.size.x <= 0.0:
		return
	var b := Registry.balance
	var y := floorf(r.position.y / 8.0) * 8.0
	var row := 0
	while y < r.end.y:
		var off := 4.0 if row % 2 == 0 else 0.0
		var x := r.position.x - off
		while x < r.end.x:
			var shade := COL_WALL_A if absi(hash(Vector2i(int(x), int(y)))) % 3 != 0 else COL_WALL_B
			var bx := maxf(x, r.position.x)
			var bw := minf(x + 9.0, r.end.x) - bx
			if bw > 0.0:
				draw_rect(Rect2(bx, y + 1.0, bw, 7.0), shade)
				draw_rect(Rect2(bx, y + 1.0, bw, 1.0), Color(shade.lightened(0.12)))
			x += 10.0
		y += 8.0
		row += 1
	# Inner edge facing the arena: lit stone trim.
	var edge_x := r.position.x if right_side else r.end.x - 2.0
	draw_rect(Rect2(edge_x, b.ceiling_y, 2.0, r.end.y - b.ceiling_y), Color("2a2b3c"))
	# Banners between torches (navy with gold trim and a violet gem), only where the wall is wide enough.
	var cx := r.position.x + r.size.x * 0.5 if r.size.x < 30.0 else (r.position.x + 7.0 if right_side else r.end.x - 7.0)
	var by := b.ceiling_y + 132.0
	while by < b.rune_line_y - 40.0:
		var bw := 9.0
		var bx := roundf(cx - bw * 0.5)
		draw_rect(Rect2(bx - 1.0, by - 1.0, bw + 2.0, 1.0), Color("8a6a3a"))
		draw_rect(Rect2(bx, by, bw, 22.0), Color("1f2a5c"))
		draw_rect(Rect2(bx, by, 1.0, 22.0), Color(UiTheme.GOLD, 0.6))
		draw_rect(Rect2(bx + bw - 1.0, by, 1.0, 22.0), Color(UiTheme.GOLD, 0.6))
		draw_colored_polygon(PackedVector2Array([Vector2(bx, by + 22.0), Vector2(bx + bw, by + 22.0), Vector2(bx + bw * 0.5, by + 26.0)]), Color("1f2a5c"))
		draw_rect(Rect2(bx + 3.0, by + 8.0, 3.0, 3.0), Color("8b6cf0"))
		draw_rect(Rect2(bx + 4.0, by + 7.0, 1.0, 5.0), Color("8b6cf0"))
		by += 260.0
	for tp: Vector2 in torch_points():
		if (tp.x > float(b.world_size.x) * 0.5) != right_side:
			continue
		var t := tp.round()
		draw_rect(Rect2(t.x - 2.0, t.y + 2.0, 5.0, 2.0), Color("5a4a3a"))
		draw_rect(Rect2(t.x - 1.0, t.y + 4.0, 3.0, 3.0), Color("3a2e26"))
		var fl := float(int(Time.get_ticks_msec() / 90) % 2)
		draw_rect(Rect2(t.x - 1.0, t.y - 1.0 - fl, 3.0, 3.0 + fl), Color("ff8a3d"))
		draw_rect(Rect2(t.x, t.y - fl, 1.0, 2.0), Color("ffe3a3"))
