class_name Icons
extends RefCounted
## Small vector icons drawn with CanvasItem calls (UI layer, crisp at any scale). `s` is the icon height.
## Original shapes for Riftbound: castle, crossed swords, student, compass, book, scroll, gem.


static func draw(ci: CanvasItem, id: StringName, c: Vector2, s: float, col: Color) -> void:
	match id:
		&"academy": _castle(ci, c, s, col)
		&"rift": _swords(ci, c, s, col)
		&"characters": _student(ci, c, s, col)
		&"expeditions": _compass(ci, c, s, col)
		&"stories": _book(ci, c, s, col)
		&"quest": _scroll(ci, c, s, col)
		_: _gem(ci, c, s * 0.45, col)


static func _castle(ci: CanvasItem, c: Vector2, s: float, col: Color) -> void:
	var h := s * 0.5
	var w := s * 0.42
	# Keep with a pointed central spire and two towers.
	ci.draw_rect(Rect2(c.x - w, c.y - h * 0.1, w * 2.0, h * 1.1), col)
	ci.draw_rect(Rect2(c.x - w - s * 0.08, c.y - h * 0.55, s * 0.22, h * 1.55), col)
	ci.draw_rect(Rect2(c.x + w - s * 0.14, c.y - h * 0.55, s * 0.22, h * 1.55), col)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(c.x - w - s * 0.12, c.y - h * 0.55), Vector2(c.x - w + s * 0.18, c.y - h * 0.55), Vector2(c.x - w + s * 0.03, c.y - h * 0.95)]), col)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(c.x + w - s * 0.18, c.y - h * 0.55), Vector2(c.x + w + s * 0.12, c.y - h * 0.55), Vector2(c.x + w - s * 0.03, c.y - h * 0.95)]), col)
	ci.draw_rect(Rect2(c.x - s * 0.13, c.y - h * 0.6, s * 0.26, h * 0.6), col)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(c.x - s * 0.17, c.y - h * 0.6), Vector2(c.x + s * 0.17, c.y - h * 0.6), Vector2(c.x, c.y - h * 1.15)]), col)
	ci.draw_rect(Rect2(c.x - s * 0.08, c.y + h * 0.45, s * 0.16, h * 0.55), Color(0.05, 0.04, 0.1, 0.9))


static func _swords(ci: CanvasItem, c: Vector2, s: float, col: Color) -> void:
	var r := s * 0.48
	for sg: float in [-1.0, 1.0]:
		var a := Vector2(c.x - r * sg, c.y + r)
		var b := Vector2(c.x + r * 0.75 * sg, c.y - r * 0.85)
		ci.draw_line(a, b, col, maxf(1.2, s * 0.11), true)
		var d := (b - a).normalized()
		var n := Vector2(-d.y, d.x)
		var g := a + d * r * 0.55
		ci.draw_line(g - n * s * 0.16, g + n * s * 0.16, col, maxf(1.0, s * 0.09), true)


static func _student(ci: CanvasItem, c: Vector2, s: float, col: Color) -> void:
	ci.draw_circle(c + Vector2(0, -s * 0.2), s * 0.2, col)
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.4, s * 0.48), c + Vector2(-s * 0.3, s * 0.08), c + Vector2(0, -s * 0.02),
		c + Vector2(s * 0.3, s * 0.08), c + Vector2(s * 0.4, s * 0.48)]), col)
	# Hair fringe.
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.23, -s * 0.2), c + Vector2(0, -s * 0.46), c + Vector2(s * 0.23, -s * 0.2), c + Vector2(0, -s * 0.3)]), col.lightened(0.25))


static func _compass(ci: CanvasItem, c: Vector2, s: float, col: Color) -> void:
	var r := s * 0.45
	ci.draw_arc(c, r, 0.0, TAU, 24, col, maxf(1.0, s * 0.07), true)
	var k := r * 0.85
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -k), c + Vector2(k * 0.25, 0), c + Vector2(0, k), c + Vector2(-k * 0.25, 0)]), col)
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-k, 0), c + Vector2(0, -k * 0.25), c + Vector2(k, 0), c + Vector2(0, k * 0.25)]), col.darkened(0.25))
	ci.draw_circle(c, s * 0.06, Color(0.05, 0.04, 0.1))


static func _book(ci: CanvasItem, c: Vector2, s: float, col: Color) -> void:
	var w := s * 0.48
	var h := s * 0.36
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-w, -h), c + Vector2(-s * 0.04, -h + s * 0.08), c + Vector2(-s * 0.04, h + s * 0.08), c + Vector2(-w, h)]), col)
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(s * 0.04, -h + s * 0.08), c + Vector2(w, -h), c + Vector2(w, h), c + Vector2(s * 0.04, h + s * 0.08)]), col)
	for i in 3:
		var y := c.y - h * 0.4 + float(i) * h * 0.45
		ci.draw_line(Vector2(c.x - w * 0.75, y), Vector2(c.x - w * 0.2, y + s * 0.03), Color(0.05, 0.04, 0.1, 0.8), maxf(0.8, s * 0.05))
		ci.draw_line(Vector2(c.x + w * 0.2, y + s * 0.03), Vector2(c.x + w * 0.75, y), Color(0.05, 0.04, 0.1, 0.8), maxf(0.8, s * 0.05))


static func _scroll(ci: CanvasItem, c: Vector2, s: float, col: Color) -> void:
	var w := s * 0.32
	var h := s * 0.42
	ci.draw_rect(Rect2(c.x - w, c.y - h, w * 2.0, h * 2.0), col)
	ci.draw_rect(Rect2(c.x - w - s * 0.06, c.y - h - s * 0.06, w * 2.0 + s * 0.12, s * 0.12), col.darkened(0.3))
	ci.draw_rect(Rect2(c.x - w - s * 0.06, c.y + h - s * 0.06, w * 2.0 + s * 0.12, s * 0.12), col.darkened(0.3))
	for i in 3:
		var y := c.y - h * 0.45 + float(i) * h * 0.45
		ci.draw_line(Vector2(c.x - w * 0.6, y), Vector2(c.x + w * 0.6, y), Color(0.25, 0.18, 0.1), maxf(0.8, s * 0.05))


static func _gem(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.8, 0), c + Vector2(0, r), c + Vector2(-r * 0.8, 0)]), col)
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.8, 0), c + Vector2(0, 0)]), col.lightened(0.35))


## Red notification badge with "!" (reference: unread markers on tabs and buildings).
static func badge(ci: CanvasItem, c: Vector2, r: float = 3.5) -> void:
	ci.draw_circle(c, r + 0.8, Color(0.05, 0.03, 0.08))
	ci.draw_circle(c, r, Color("e0485a"))
	ci.draw_rect(Rect2(c.x - 0.5, c.y - r * 0.6, 1.0, r * 0.75), Color.WHITE)
	ci.draw_rect(Rect2(c.x - 0.5, c.y + r * 0.3, 1.0, 1.0), Color.WHITE)


## Resource icons: 0 Mana Shard (crystal), 1 Ruins Material (stone block), 2 Ancient Relic (medallion). `k` scales a 10-unit icon.
static func resource(ci: CanvasItem, i: int, c: Vector2, k: float = 1.0) -> void:
	var col: Color = UiTheme.resource_colors()[i]
	match i:
		0:
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -5) * k, c + Vector2(3, -1) * k, c + Vector2(0, 5) * k, c + Vector2(-3, -1) * k]), col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -5) * k, c + Vector2(3, -1) * k, c]), col.lightened(0.4))
		1:
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-4, -1) * k, c + Vector2(0, -4) * k, c + Vector2(4, -1) * k, c + Vector2(4, 3) * k, c + Vector2(0, 5) * k, c + Vector2(-4, 3) * k]), col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-4, -1) * k, c + Vector2(0, -4) * k, c + Vector2(4, -1) * k, c + Vector2(0, 1) * k]), col.lightened(0.3))
		_:
			ci.draw_circle(c, 4.2 * k, col.darkened(0.25))
			ci.draw_circle(c, 3.0 * k, col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -2) * k, c + Vector2(1.5, 0) * k, c + Vector2(0, 2) * k, c + Vector2(-1.5, 0) * k]), Color("7a4a1a"))
