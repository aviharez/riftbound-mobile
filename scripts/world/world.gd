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

## Visible area in playfield coordinates. Set by Main whenever the screen size changes.
var visible_rect: Rect2 = Rect2(0, 0, 270, 560)


func set_visible_rect(r: Rect2) -> void:
	visible_rect = r
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
		var c := COL_WALL_A if int(y / 12.0) % 2 == 0 else COL_WALL_B
		draw_rect(Rect2(visible_rect.position.x, y + 1.0, field.position.x - visible_rect.position.x - 1.0, 10.0), c)
		draw_rect(Rect2(field.end.x + 1.0, y + 1.0, visible_rect.end.x - field.end.x - 1.0, 10.0), c)
		y += 12.0

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
