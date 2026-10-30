class_name Hud
extends Control
## In-battle HUD on the native-resolution UI layer: top band, XP bar, left wave-progress bar,
## ultimate button, popups, damage flash and (optionally) touch markers.
## Geometry is defined in playfield coordinates and drawn with the playfield offset, so it lines up
## with the world. Main uses the same rects for touch hit-testing (combat-spec §2, §11).

const BAND_H := 34.0
const BUTTON_SIZE := Vector2(22, 16)
const ULT_RADIUS := 16.0
const PRISM_COLORS: Array[Color] = [Color("ff6a6a"), Color("ffd27a"), Color("7fe0a8"), Color("69D8E8"), Color("a98bff")]

var battle: Battle
var settings: PlayerSettings
## Top-left of the playfield in UI coordinates (set by Main).
var offset: Vector2 = Vector2.ZERO
var visible_size: Vector2 = Vector2(270, 560)
## Active touches for the debug overlay: id -> {pos: Vector2 (playfield), role: StringName}.
var touches: Dictionary = {}
var _font: Font
var _display: Font
var _body: Font
var _time: float = 0.0
var _panel: OrnateBox
var _chip: OrnateBox
var _btn: OrnateBox
var _btn_on: OrnateBox


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = UiTheme.pixel_font()
	_display = UiTheme.display_font()
	_body = UiTheme.body_font()
	_panel = OrnateBox.make(OrnateBox.Kind.CARD, 0.0)
	_panel.studs = false
	_chip = OrnateBox.make(OrnateBox.Kind.PLAQUE, 0.0)
	_btn = OrnateBox.make(OrnateBox.Kind.CHIP, 0.0)
	_btn.border = Color(UiTheme.GOLD, 0.8)
	_btn_on = _btn.tinted(UiTheme.GOLD)
	_btn_on.top = Color("6a48d8")
	_btn_on.bottom = Color("3d2596")


func speed_rect() -> Rect2:
	var w := float(Registry.balance.world_size.x)
	return Rect2(Vector2(w - 56.0, 7.0), BUTTON_SIZE + Vector2(0, 4))


func pause_rect() -> Rect2:
	var w := float(Registry.balance.world_size.x)
	return Rect2(Vector2(w - 30.0, 7.0), BUTTON_SIZE + Vector2(0, 4))


func ult_center() -> Vector2:
	var s := Vector2(Registry.balance.world_size)
	return Vector2(s.x - 35.0, s.y - 56.0)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	if battle == null or battle.loadout == null:
		return
	draw_set_transform(offset)
	_draw_band()
	_draw_progress()
	_draw_ult()
	_draw_popups()
	if settings.show_touches:
		for t: Dictionary in touches.values():
			var c := Color("E6BD73") if t.role == &"move" else (Color("69D8E8") if t.role == &"aim" else Color("ff6a3d"))
			draw_arc(t.pos, 11.0, 0.0, TAU, 24, c, 1.0)
			_text(t.pos + Vector2(-30, -16), String(t.role).to_upper(), c, 60.0, HORIZONTAL_ALIGNMENT_CENTER)
	draw_set_transform(Vector2.ZERO)
	if battle.red_flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, visible_size), Color(1.0, 0.24, 0.31, battle.red_flash * 0.6))


func _text(at: Vector2, s: String, c: Color, width: float = -1.0, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, size: int = 8) -> void:
	draw_string(_font, at, s, align, width, size, c)


func _draw_band() -> void:
	var b := battle
	var ci := get_canvas_item()
	# Band background: deep indigo fading down, with a gold rule.
	var band := Rect2(-offset.x, 0, visible_size.x, BAND_H)
	draw_polygon(PackedVector2Array([band.position, Vector2(band.end.x, 0), band.end, Vector2(band.position.x, band.end.y)]),
		PackedColorArray([Color("0d0c1a"), Color("0d0c1a"), Color(0.07, 0.065, 0.14, 0.92), Color(0.07, 0.065, 0.14, 0.92)]))
	draw_line(Vector2(band.position.x, BAND_H + 0.5), Vector2(band.end.x, BAND_H + 0.5), Color(UiTheme.GOLD, 0.55), 1.0)

	# Portrait in a gold ring.
	var pc := Vector2(17, 17)
	draw_circle(pc, 14.0, Color("0b0a16"))
	if b.character and b.character.sprite_sheet:
		var head := SpriteKit.head_rect(b.character.sprite_sheet)
		draw_texture_rect_region(b.character.sprite_sheet, Rect2(pc - Vector2(9, 9), Vector2(18, 18)), head)
	draw_arc(pc, 13.5, 0.0, TAU, 40, UiTheme.GOLD, 1.5, true)
	draw_arc(pc, 15.5, 0.0, TAU, 40, Color(UiTheme.GOLD, 0.35), 1.0, true)
	_diamond(pc + Vector2(0, 15.5), 2.5, UiTheme.VIOLET, UiTheme.GOLD)

	# HP / level panel.
	var pr := Rect2(30, 5, 66, 24)
	_panel.draw(ci, pr)
	var hp_frac := float(b.hp) / float(b.max_hp)
	_heart(Vector2(36, 11.5))
	draw_rect(Rect2(41, 9, 51, 5), Color("2a1220"))
	draw_rect(Rect2(41, 9, roundf(51.0 * hp_frac), 5), Color("ff5a6a") if b.hp <= 3 else Color("d8435a"))
	draw_rect(Rect2(41, 9, roundf(51.0 * hp_frac), 1), Color(1, 1, 1, 0.25))
	_btext(Vector2(41, 22), "%d / %d" % [b.hp, b.max_hp], UiTheme.PARCH, 6)
	draw_string(_display, Vector2(34, 26.5), "Lv. %d" % b.level, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, UiTheme.GOLD)
	var xp_frac := float(b.xp) / float(b.xp_needed())
	draw_rect(Rect2(58, 23, 34, 3), Color("0c1a2a"))
	draw_rect(Rect2(58, 23, roundf(34.0 * xp_frac), 3), Color("4fb4ff"))

	# Wave plaque: WAVE NN, timer and kills.
	var wr := Rect2(100, 4, 74, 27)
	_chip.draw(ci, wr)
	draw_string(_display, Vector2(wr.position.x, 15), "WAVE %02d" % b.wave, HORIZONTAL_ALIGNMENT_CENTER, wr.size.x, 9, UiTheme.GOLD)
	var t := int(b.run_time)
	_clock(Vector2(112, 23))
	_btext(Vector2(117, 26), "%d:%02d" % [floori(b.run_time / 60.0), t % 60], UiTheme.PARCH, 7)
	_skull(Vector2(142, 23))
	_btext(Vector2(147, 26), str(b.kills), UiTheme.PARCH, 7)
	if b.prisms > 0:
		_diamond(Vector2(181, 12), 3.5, PRISM_COLORS[int(_time * 6.0) % PRISM_COLORS.size()], UiTheme.GOLD)
		_btext(Vector2(186, 15), "x%d" % b.prisms, UiTheme.PARCH, 7)
	_btext(Vector2(178, 27), "%d balls" % b.balls.size(), UiTheme.MUTED, 6)

	# Buttons
	_button(speed_rect(), "x%d" % b.speed, b.speed > 1)
	_button(pause_rect(), "II", false)
	draw_string(_display, Vector2(pause_rect().position.x - 4.0, pause_rect().end.y + 6.0), "PAUSE", HORIZONTAL_ALIGNMENT_CENTER, pause_rect().size.x + 8.0, 5, Color(UiTheme.GOLD, 0.8))


func _btext(at: Vector2, s: String, c: Color, size: int = 7) -> void:
	draw_string(_body, at, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, c)


func _heart(c: Vector2) -> void:
	var col := Color("ff5a6a")
	draw_circle(c + Vector2(-1.3, -0.8), 1.7, col)
	draw_circle(c + Vector2(1.3, -0.8), 1.7, col)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-3, -0.3), c + Vector2(3, -0.3), c + Vector2(0, 3)]), col)


func _clock(c: Vector2) -> void:
	draw_arc(c, 2.6, 0.0, TAU, 16, UiTheme.PARCH, 0.8, true)
	draw_line(c, c + Vector2(0, -1.8), UiTheme.PARCH, 0.8)
	draw_line(c, c + Vector2(1.3, 0), UiTheme.PARCH, 0.8)


func _skull(c: Vector2) -> void:
	draw_circle(c + Vector2(0, -0.6), 2.5, UiTheme.PARCH)
	draw_rect(Rect2(c.x - 1.5, c.y + 1.0, 3, 1.8), UiTheme.PARCH)
	draw_circle(c + Vector2(-0.9, -0.6), 0.7, Color("0d0c1a"))
	draw_circle(c + Vector2(0.9, -0.6), 0.7, Color("0d0c1a"))


func _button(r: Rect2, label: String, active: bool) -> void:
	(_btn_on if active else _btn).draw(get_canvas_item(), r)
	draw_string(_display, Vector2(r.position.x, r.position.y + r.size.y * 0.5 + 3.5), label, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 9, UiTheme.PARCH)


func _diamond(c: Vector2, r: float, fill: Color, stroke: Color = Color(0, 0, 0, 0)) -> void:
	var pts := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)])
	draw_colored_polygon(pts, fill)
	if stroke.a > 0.0:
		pts.append(pts[0])
		draw_polyline(pts, stroke, 1.0)


func _draw_progress() -> void:
	var bal := Registry.balance
	var cx := 7.5
	var y0 := bal.ceiling_y + 22.0
	var y1 := y0 + roundf((bal.rune_line_y - bal.ceiling_y) * 0.55)
	var p := battle.wave_progress()
	_diamond(Vector2(cx, bal.ceiling_y + 10.0), 5.0, UiTheme.VIOLET, UiTheme.GOLD)
	_diamond(Vector2(cx, bal.ceiling_y + 10.0), 1.5, Color("c9b6ff"))
	draw_rect(Rect2(cx - 2.5, y0, 5, y1 - y0), Color("08080f"))
	draw_rect(Rect2(cx - 3.0, y0 - 0.5, 6, y1 - y0 + 1.0), Color(UiTheme.GOLD, 0.7), false, 1.0)
	var fh := roundf((y1 - y0) * p)
	draw_rect(Rect2(cx - 1.5, y0, 3, fh), Color("b8435a") if battle.boss_active else UiTheme.VIOLET)
	var every := bal.boss_every_waves
	for i in range(1, every):
		var yy := roundf(y0 + (y1 - y0) * float(i) / float(every))
		_diamond(Vector2(cx, yy), 3.0, Color("c9b6ff") if p >= float(i) / float(every) else Color("1d1d33"), UiTheme.GOLD)
	var by := y1 + 10.0
	var pulse := (battle.boss_active or battle.boss_pending) and int(_time * 6.0) % 2 == 0
	draw_circle(Vector2(cx, by), 7.0, Color("0b0b16"))
	draw_arc(Vector2(cx, by), 7.0, 0.0, TAU, 20, Color("ff6b6b") if pulse else UiTheme.GOLD, 1.0)
	draw_rect(Rect2(cx - 5, by - 5, 2, 3), Color("b8955a"))
	draw_rect(Rect2(cx + 3, by - 5, 2, 3), Color("b8955a"))
	draw_rect(Rect2(cx - 3, by - 2, 6, 5), Color("ff6b6b") if pulse else Color("d8c8f0"))
	draw_rect(Rect2(cx - 2, by, 1, 1), Color("0b0b16"))
	draw_rect(Rect2(cx + 1, by, 1, 1), Color("0b0b16"))
	_text(Vector2(0, by + 16.0), "BOSS", Color("ff6b6b") if pulse else UiTheme.GOLD)


func _draw_ult() -> void:
	var b := battle
	var bal := Registry.balance
	var c := ult_center()
	var r := ULT_RADIUS
	var ready := b.energy >= bal.energy_max
	var frac := b.energy / bal.energy_max
	var near := b.player.distance_to(c) < 32.0
	var alpha := 0.35 if near else 0.95
	var elem := b.ultimate_color()
	if ready:
		var pulse := 0.5 + 0.5 * sin(_time * 6.0)
		for i in 4:
			draw_circle(c, r + 10.0 - float(i) * 2.5, Color(elem, (0.05 + 0.04 * pulse) * alpha))
	# Body: dark disc with a soft inner glow in the element colour.
	draw_circle(c, r + 2.5, Color(0.03, 0.03, 0.07, 0.9 * alpha))
	for i in 5:
		var k := float(i) / 4.0
		var col := Color("17152e").lerp(elem.darkened(0.45) if ready else Color("262340"), k)
		draw_circle(c, (r - 1.0) * (1.0 - k * 0.55), Color(col, alpha))
	# Ornate ring: gold double line with four diamonds.
	draw_arc(c, r + 1.5, 0.0, TAU, 48, Color(UiTheme.GOLD, 0.55 * alpha), 1.0, true)
	draw_arc(c, r + 3.5, 0.0, TAU, 48, Color(UiTheme.GOLD, 0.35 * alpha), 1.0, true)
	if frac > 0.0:
		var ring_col := (Color("ffe3a3") if int(_time * 6.0) % 2 == 0 else UiTheme.GOLD) if ready else UiTheme.CYAN
		draw_arc(c, r + 2.5, -PI * 0.5, -PI * 0.5 + TAU * frac, 48, Color(ring_col, alpha), 2.0, true)
	for a: float in [0.0, PI * 0.5, PI, PI * 1.5]:
		_diamond(c + Vector2.from_angle(a) * (r + 3.0), 2.2, Color(UiTheme.VIOLET, alpha), Color(UiTheme.GOLD, alpha))
	_flame(c + Vector2(0, 1), 7.5, elem if ready else Color("6a6080"), alpha)
	# Name under the button, kept inside the playfield.
	var ult_name := b.character.ultimate_name.to_upper() if b.character else "ULTIMATE"
	var tw := _display.get_string_size(ult_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
	var tx := minf(c.x - tw * 0.5, float(Registry.balance.world_size.x) - tw - 3.0)
	draw_string_outline(_display, Vector2(tx, c.y + r + 12.0), ult_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, 2, Color(0, 0, 0, 0.7 * alpha))
	draw_string(_display, Vector2(tx, c.y + r + 12.0), ult_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(UiTheme.GOLD if ready else Color("cfc8e0"), alpha))
	for i in 4:
		var on := frac >= float(i + 1) / 4.0 - 0.0001
		var dc := Vector2(c.x - 12.0 + float(i) * 8.0, c.y + r + 18.0)
		if on:
			_diamond(dc, 2.5, Color(Color("ffd27a") if ready else UiTheme.CYAN, alpha))
		else:
			_diamond(dc, 2.5, Color(0.04, 0.04, 0.09, 0.85 * alpha), Color(UiTheme.MUTED, 0.6 * alpha))


## A smooth flame (teardrop with an inner core), flickering.
func _flame(c: Vector2, h: float, col: Color, alpha: float) -> void:
	var f := sin(_time * 14.0) * 0.6
	var outer := PackedVector2Array()
	var inner := PackedVector2Array()
	for i in 17:
		var t := float(i) / 16.0 * TAU
		var w := sin(t * 0.5)
		var x := sin(t) * h * 0.55 * (0.6 + 0.4 * w)
		var y := -cos(t) * h * (0.75 if cos(t) > 0.0 else 0.5) * (1.0 + (0.18 if cos(t) > 0.0 else 0.0))
		outer.append(c + Vector2(x + (f if y < 0.0 else 0.0), y))
		inner.append(c + Vector2(x * 0.5, y * 0.55 + h * 0.18))
	draw_colored_polygon(outer, Color(col, alpha))
	draw_colored_polygon(inner, Color(col.lightened(0.55), alpha))


func _draw_popups() -> void:
	var w := float(Registry.balance.world_size.x)
	var i := 0
	for p: Battle.Callout in battle.popups:
		var k := p.t / p.max_t
		var a := k / 0.15 if k < 0.15 else ((1.0 - k) / 0.3 if k > 0.7 else 1.0)
		var y := 180.0 + float(i) * 16.0 - roundf(k * 12.0)
		draw_string_outline(_display, Vector2(0, y), p.text, HORIZONTAL_ALIGNMENT_CENTER, w, 11, 3, Color(0.05, 0.02, 0.12, a))
		draw_string(_display, Vector2(0, y), p.text, HORIZONTAL_ALIGNMENT_CENTER, w, 11, Color(p.color, a))
		i += 1
