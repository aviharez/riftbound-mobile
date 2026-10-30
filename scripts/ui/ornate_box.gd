class_name OrnateBox
extends StyleBox
## The Riftbound UI frame, drawn in code so it stays crisp at any phone resolution (UI layer, native res):
## an indigo gradient, a gold outer line, a thin inner line and violet diamond studs on the corners.
## Buttons get pointed (diamond-tipped) ends. One class, several looks — see `Kind`.

enum Kind { PANEL, CARD, BUTTON, BUTTON_PRIMARY, CHIP, PLAQUE }

var kind: Kind = Kind.PANEL
var top: Color = Color("1d1b3a")
var bottom: Color = Color("12111f")
var border: Color = UiTheme.GOLD
var inner: Color = Color(UiTheme.GOLD, 0.35)
var stud: Color = Color("9b6cff")
## Outer glow drawn around the frame (selected card, hovered primary button). Alpha 0 = none.
var glow: Color = Color(0, 0, 0, 0)
var studs: bool = true


static func make(k: Kind, margin: float = 8.0) -> OrnateBox:
	var s := OrnateBox.new()
	s.kind = k
	s.set_content_margin_all(margin)
	match k:
		Kind.BUTTON_PRIMARY:
			s.top = Color("8a63f2")
			s.bottom = Color("4b2db8")
			s.inner = Color(1, 1, 1, 0.18)
			s.studs = false
			s.content_margin_left = margin + 6.0
			s.content_margin_right = margin + 6.0
		Kind.BUTTON:
			s.top = Color("262447")
			s.bottom = Color("171631")
			s.border = Color(UiTheme.GOLD, 0.75)
			s.inner = Color(UiTheme.GOLD, 0.18)
			s.studs = false
			s.content_margin_left = margin + 6.0
			s.content_margin_right = margin + 6.0
		Kind.CARD:
			s.top = Color("201e3d")
			s.bottom = Color("151429")
			s.border = Color(UiTheme.GOLD, 0.6)
			s.inner = Color(UiTheme.GOLD, 0.15)
		Kind.CHIP:
			s.top = Color("1b1a33")
			s.bottom = Color("131227")
			s.border = Color(UiTheme.GOLD, 0.45)
			s.inner = Color(0, 0, 0, 0)
			s.studs = false
		Kind.PLAQUE:
			s.top = Color("2a2650")
			s.bottom = Color("1a1834")
			s.studs = false
	return s


## A copy with another border (and glow). Copies every field by hand: Resource.duplicate() only copies
## exported properties, which would reset the look to a plain PANEL.
func copy() -> OrnateBox:
	var s := OrnateBox.new()
	s.kind = kind
	s.top = top
	s.bottom = bottom
	s.border = border
	s.inner = inner
	s.stud = stud
	s.glow = glow
	s.studs = studs
	for side: int in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		s.set_content_margin(side, get_content_margin(side))
	return s


func tinted(new_border: Color, new_glow: Color = Color(0, 0, 0, 0)) -> OrnateBox:
	var s := copy()
	s.border = new_border
	s.glow = new_glow
	return s


func _shape(r: Rect2, inset: float) -> PackedVector2Array:
	var a := r.grow(-inset)
	if kind == Kind.BUTTON or kind == Kind.BUTTON_PRIMARY or kind == Kind.PLAQUE:
		# Hexagon: pointed left and right ends.
		var tip := minf(a.size.y * 0.5, 7.0)
		var my := a.position.y + a.size.y * 0.5
		return PackedVector2Array([
			Vector2(a.position.x + tip, a.position.y), Vector2(a.end.x - tip, a.position.y), Vector2(a.end.x, my),
			Vector2(a.end.x - tip, a.end.y), Vector2(a.position.x + tip, a.end.y), Vector2(a.position.x, my)])
	# Rectangle with small cut corners.
	var c := 3.0 if kind != Kind.CHIP else 2.0
	return PackedVector2Array([
		Vector2(a.position.x + c, a.position.y), Vector2(a.end.x - c, a.position.y), Vector2(a.end.x, a.position.y + c),
		Vector2(a.end.x, a.end.y - c), Vector2(a.end.x - c, a.end.y), Vector2(a.position.x + c, a.end.y),
		Vector2(a.position.x, a.end.y - c), Vector2(a.position.x, a.position.y + c)])


func _draw(ci: RID, rect: Rect2) -> void:
	var rs := RenderingServer
	if glow.a > 0.0:
		for i in 3:
			var g := _shape(rect.grow(3.0 - float(i)), 0.0)
			g.append(g[0])
			rs.canvas_item_add_polyline(ci, g, PackedColorArray([Color(glow, glow.a * (0.25 + 0.25 * float(i)))]), 1.0, true)
	var pts := _shape(rect, 0.0)
	# Vertical gradient: per-vertex colours by height.
	var cols := PackedColorArray()
	for p: Vector2 in pts:
		var t := clampf((p.y - rect.position.y) / maxf(1.0, rect.size.y), 0.0, 1.0)
		cols.append(top.lerp(bottom, t))
	rs.canvas_item_add_polygon(ci, pts, cols)
	var outline := pts.duplicate()
	outline.append(pts[0])
	rs.canvas_item_add_polyline(ci, outline, PackedColorArray([border]), 1.0, true)
	if inner.a > 0.0 and rect.size.x > 12.0 and rect.size.y > 12.0:
		var ins := _shape(rect, 2.5)
		ins.append(ins[0])
		rs.canvas_item_add_polyline(ci, ins, PackedColorArray([inner]), 0.6, true)
	if studs and rect.size.x > 30.0:
		for c: Vector2 in [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]:
			_diamond(ci, c, 3.2, Color("2a1d55"))
			_diamond(ci, c, 2.2, stud)
	if kind == Kind.PANEL and rect.size.x > 60.0:
		# Small gem at the top centre, like the reference frames.
		var tc := Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y)
		_diamond(ci, tc, 4.0, Color("2a1d55"))
		_diamond(ci, tc, 3.0, UiTheme.CYAN)


static func _diamond(ci: RID, c: Vector2, r: float, col: Color) -> void:
	RenderingServer.canvas_item_add_polygon(ci, PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)]), PackedColorArray([col]))
