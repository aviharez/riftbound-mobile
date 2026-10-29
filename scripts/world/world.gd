class_name World
extends Node2D
## M0 placeholder arena. Draws the fixed 270x560 playfield and fills any extra visible area with wall stone.
## Coordinates are playfield-local (0,0 = top-left of the 270x560 playfield).
## Replace the drawing with real tiles and sprites in M7; keep the coordinate system.

const COL_OUTER := Color("0f0f17")
const COL_WALL_A := Color("16161f")
const COL_WALL_B := Color("191a24")
const COL_TRIM := Color(0.902, 0.741, 0.451, 0.3)       # Academy Gold, dimmed
const COL_RUNE := Color(0.902, 0.741, 0.451, 0.55)
const COL_ZONE := Color(0.412, 0.847, 0.910, 0.04)       # Arcane Cyan tint
const COL_RIFT := Color(0.435, 0.290, 0.902)             # Rift Violet
const FLOOR_SHADES: Array[Color] = [Color("262834"), Color("232530"), Color("292b38"), Color("24262f"), Color("2a2c37")]
const TILE := 16

## Visible area in playfield coordinates. Set by Main whenever the screen size changes.
var visible_rect: Rect2 = Rect2(0, 0, 270, 560)
var _markers: Array[Vector2] = []


func set_visible_rect(r: Rect2) -> void:
	visible_rect = r
	queue_redraw()


func add_marker(world_pos: Vector2) -> void:
	_markers.append(world_pos.floor())
	if _markers.size() > 12:
		_markers.pop_front()
	queue_redraw()


func _draw() -> void:
	var b := Registry.balance
	var size := Vector2(b.world_size)
	var wall := float(b.wall_width)
	var field := Rect2(wall, 0.0, size.x - wall * 2.0, size.y)

	# Extra visible area + walls: stone blocks.
	draw_rect(visible_rect, COL_OUTER)
	var y := floorf(visible_rect.position.y / 12.0) * 12.0
	while y < visible_rect.end.y:
		var row := int(y / 12.0)
		var c := COL_WALL_A if row % 2 == 0 else COL_WALL_B
		draw_rect(Rect2(visible_rect.position.x, y + 1.0, field.position.x - visible_rect.position.x - 1.0, 10.0), c)
		draw_rect(Rect2(field.end.x + 1.0, y + 1.0, visible_rect.end.x - field.end.x - 1.0, 10.0), c)
		y += 12.0

	# Field floor: 16 px tiles, desaturated so projectiles carry the color.
	var ty := 0
	while ty < int(size.y):
		var tx := int(field.position.x)
		while tx < int(field.end.x):
			var shade := FLOOR_SHADES[absi(hash(Vector2i(tx, ty))) % FLOOR_SHADES.size()]
			draw_rect(Rect2(tx + 1, ty + 1, TILE - 1, TILE - 1), shade)
			tx += TILE
		ty += TILE

	# Ceiling ledge and wall trims.
	draw_rect(Rect2(field.position.x, 0.0, field.size.x, b.ceiling_y), Color("121219"))
	draw_rect(Rect2(field.position.x, b.ceiling_y - 1.0, field.size.x, 1.0), COL_TRIM)
	draw_rect(Rect2(field.position.x - 1.0, b.ceiling_y, 1.0, size.y - b.ceiling_y), COL_TRIM)
	draw_rect(Rect2(field.end.x, b.ceiling_y, 1.0, size.y - b.ceiling_y), COL_TRIM)

	# Rift glow at the top center (above the playfield too, so tall screens show more of it).
	for i in 4:
		var r := 46.0 - float(i) * 10.0
		draw_circle(Vector2(size.x * 0.5, b.ceiling_y), r, Color(COL_RIFT, 0.06 + 0.05 * float(i)))

	# Move zone and rune line.
	draw_rect(Rect2(field.position.x, b.rune_line_y, field.size.x, size.y - b.rune_line_y), COL_ZONE)
	var x := field.position.x + 2.0
	while x < field.end.x:
		draw_rect(Rect2(x, b.rune_line_y, 3.0, 1.0), COL_RUNE)
		x += 6.0

	# Placeholder enemy row and player, sized per art-spec.
	for col in b.grid_columns:
		if col == 2 or col == 5:
			continue
		var ex := field.position.x + float(col) * b.cell_size + (b.cell_size - b.enemy_size) * 0.5
		var ey := b.first_row_y + (b.cell_size - b.enemy_size) * 0.5
		draw_rect(Rect2(ex, ey, b.enemy_size, b.enemy_size), Color("1b1130"))
		draw_rect(Rect2(ex + 2.0, ey + 2.0, b.enemy_size - 4.0, b.enemy_size - 4.0), Color("5e3bb8"))
		draw_rect(Rect2(ex + 6.0, ey + 9.0, 3.0, 3.0), Color("9ff3ff"))
		draw_rect(Rect2(ex + 15.0, ey + 9.0, 3.0, 3.0), Color("9ff3ff"))
	var p := Vector2(roundf(size.x * 0.5), 520.0)
	draw_rect(Rect2(p.x - 10.0, p.y - 28.0, 20.0, 28.0), Color(0.141, 0.188, 0.416))
	draw_rect(Rect2(p.x - 4.0, p.y - 34.0, 8.0, 7.0), Color("c7432c"))

	# 1-px checker: must look perfectly crisp on device (pixel-perfect check).
	for i in 8:
		for j in 8:
			if (i + j) % 2 == 0:
				draw_rect(Rect2(field.position.x + 4.0 + float(i), size.y - 12.0 + float(j), 1.0, 1.0), Color.WHITE)

	# Tap markers (M0 input check).
	for m: Vector2 in _markers:
		draw_rect(Rect2(m.x - 3.0, m.y, 7.0, 1.0), Color(0.412, 0.847, 0.910))
		draw_rect(Rect2(m.x, m.y - 3.0, 1.0, 7.0), Color(0.412, 0.847, 0.910))
