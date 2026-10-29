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
var _time: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = UiTheme.pixel_font()


func speed_rect() -> Rect2:
	var w := float(Registry.balance.world_size.x)
	return Rect2(Vector2(w - 60.0, 9.0), BUTTON_SIZE)


func pause_rect() -> Rect2:
	var w := float(Registry.balance.world_size.x)
	return Rect2(Vector2(w - 33.0, 9.0), BUTTON_SIZE)


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
	draw_rect(Rect2(-offset.x, 0, visible_size.x, BAND_H), UiTheme.INK)
	draw_rect(Rect2(-offset.x, BAND_H, visible_size.x, 2), Color("0b1a13"))
	draw_rect(Rect2(-offset.x, BAND_H, visible_size.x * float(b.xp) / float(b.xp_needed()), 2), UiTheme.GEM)
	draw_rect(Rect2(-offset.x, BAND_H + 2.0, visible_size.x, 1), Color(UiTheme.GOLD, 0.5))
	# HP
	_text(Vector2(8, 15), "HP", UiTheme.PARCH)
	draw_rect(Rect2(22, 9, 50, 5), Color("2a1520"))
	draw_rect(Rect2(22, 9, roundf(50.0 * float(b.hp) / float(b.max_hp)), 5), Color("ff5a6a") if b.hp <= 3 else Color("e0566a"))
	if b.prisms > 0:
		_text(Vector2(78, 15), "PRISM %d" % b.prisms, PRISM_COLORS[int(_time * 6.0) % PRISM_COLORS.size()])
	_text(Vector2(8, 28), "LV %d" % b.level, UiTheme.GEM)
	_text(Vector2(42, 28), "KILL %d" % b.kills, UiTheme.MUTED)
	_text(Vector2(90, 28), "BALLS %d" % b.balls.size(), UiTheme.MUTED)
	# Wave + time
	_text(Vector2(120, 15), "WAVE %02d" % b.wave, UiTheme.GOLD, 80.0, HORIZONTAL_ALIGNMENT_CENTER)
	var t := int(b.run_time)
	_text(Vector2(120, 28), "%d:%02d" % [floori(b.run_time / 60.0), t % 60], UiTheme.MUTED, 80.0, HORIZONTAL_ALIGNMENT_CENTER)
	# Buttons
	_button(speed_rect(), "x%d" % b.speed, b.speed > 1)
	_button(pause_rect(), "II", false)


func _button(r: Rect2, label: String, active: bool) -> void:
	draw_rect(r, Color("3a2a6e") if active else UiTheme.INK_2)
	draw_rect(r, Color(UiTheme.GOLD, 0.7), false, 1.0)
	_text(Vector2(r.position.x, r.position.y + 11.0), label, UiTheme.PARCH, r.size.x, HORIZONTAL_ALIGNMENT_CENTER)


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
	var alpha := 0.35 if near else 0.92
	if ready:
		for i in 3:
			draw_circle(c, r + 9.0 - float(i) * 3.0, Color(1.0, 0.55, 0.24, 0.08 * alpha))
	draw_circle(c, r + 2.0, Color(0.04, 0.04, 0.09, 0.85 * alpha))
	draw_circle(c, r - 1.0, Color(Color("3a2a6e") if ready else Color("1d1d33"), alpha))
	draw_arc(c, r + 1.0, 0.0, TAU, 40, Color(UiTheme.GOLD, 0.25 * alpha), 2.0)
	if frac > 0.0:
		var ring_col := (Color("ffd27a") if int(_time * 6.0) % 2 == 0 else UiTheme.GOLD) if ready else UiTheme.CYAN
		draw_arc(c, r + 1.0, -PI * 0.5, -PI * 0.5 + TAU * frac, 40, Color(ring_col, alpha), 2.0)
	var f := float(int(_time * 10.0) % 2) if ready else 0.0
	var flame := Color("ff6a3d") if ready else Color("5d5068")
	draw_rect(Rect2(c.x - 4, c.y - 1, 8, 7), Color(flame, alpha))
	draw_rect(Rect2(c.x - 2, c.y - 5 - f, 5, 5), Color(flame, alpha))
	draw_rect(Rect2(c.x - 1, c.y - 8 - f, 2, 3), Color(flame, alpha))
	draw_rect(Rect2(c.x - 1, c.y + 1, 3, 4), Color(Color("ffd27a") if ready else Color("7d7088"), alpha))
	_text(Vector2(c.x - 30, c.y + r + 10.0), "FLAME ORB", Color(UiTheme.GOLD if ready else Color("bdb7d0"), alpha), 60.0, HORIZONTAL_ALIGNMENT_CENTER)
	for i in 4:
		var on := frac >= float(i + 1) / 4.0 - 0.0001
		var dc := Vector2(c.x - 12.0 + float(i) * 8.0, c.y + r + 16.0)
		if on:
			_diamond(dc, 2.5, Color(Color("ffd27a") if ready else UiTheme.CYAN, alpha))
		else:
			_diamond(dc, 2.5, Color(0.04, 0.04, 0.09, 0.85 * alpha), Color(UiTheme.MUTED, 0.6 * alpha))


func _draw_popups() -> void:
	var w := float(Registry.balance.world_size.x)
	var i := 0
	for p: Battle.Callout in battle.popups:
		var k := p.t / p.max_t
		var a := k / 0.15 if k < 0.15 else ((1.0 - k) / 0.3 if k > 0.7 else 1.0)
		var y := 180.0 + float(i) * 16.0 - roundf(k * 12.0)
		_text(Vector2(1, y + 1), p.text, Color(0, 0, 0, a), w, HORIZONTAL_ALIGNMENT_CENTER, 12)
		_text(Vector2(0, y), p.text, Color(p.color, a), w, HORIZONTAL_ALIGNMENT_CENTER, 12)
		i += 1
