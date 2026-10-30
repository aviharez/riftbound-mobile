class_name FxGlow
extends Node2D
## Additive light on top of the battle: ball halos and glowing trails, chain-lightning glow, star flares,
## torch light and the student's magic circle. Per-object glow drawn at world resolution (pixel discs and
## lines), not a full-screen bloom pass (art-spec §5). Child of Fx; reads Battle and World, owns no state.

var fx: Fx
var _t: float = 0.0


func _ready() -> void:
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = m
	z_index = 1


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var battle := fx.get_parent() as Battle
	if battle == null or battle.loadout == null:
		return
	var world := battle.get_parent() as World
	if world:
		for tp: Vector2 in world.torch_points():
			var fl := 0.8 + 0.2 * sin(_t * 9.0 + tp.y) + 0.1 * sin(_t * 23.0 + tp.x)
			draw_circle(tp, 9.0 * fl, Color(1.0, 0.45, 0.15, 0.07))
			draw_circle(tp, 5.0 * fl, Color(1.0, 0.6, 0.25, 0.14))
		var rc := world.rift_center()
		if rc != Vector2.INF:
			var pulse := 0.8 + 0.2 * sin(_t * 2.5)
			draw_circle(rc, 30.0 * pulse, Color(0.45, 0.3, 0.95, 0.06))
			draw_circle(rc, 18.0 * pulse, Color(0.55, 0.4, 1.0, 0.09))
	_draw_circle_under(battle)
	for b: Ball in battle.balls:
		if b.state == Ball.State.HAND:
			continue
		var p := b.pos.round()
		var glow: Color = Battle.COL_GOLD if b.charged else (b.slot.glow_color if b.slot else Color(0.85, 0.85, 0.95))
		if b.state == Ball.State.RETURN:
			draw_circle(p, 2.0, Color(glow, 0.08))
			continue
		if b.trail.size() > 1:
			var pts := b.trail.duplicate()
			pts.append(b.pos)
			if b.slot:
				draw_polyline(pts, Color(glow, 0.32), 1.0)
		# Only element and fused balls glow; baby balls stay plain so the two read apart at a glance.
		if b.slot:
			var big := 1.3 if b.slot.fused else 1.0
			draw_circle(p, 10.0 * big, Color(glow, 0.10))
			draw_circle(p, 6.5 * big, Color(glow, 0.22))
	for bo: Fx.Bolt in fx.bolts():
		var a := 1.0 - bo.t / bo.life
		draw_line(bo.from, bo.to, Color(bo.color, 0.22 * a), 3.0)
		draw_circle(bo.to, 4.0, Color(bo.color, 0.25 * a))
	for f: Fx.Flare in fx.flares:
		var k := f.t / f.life
		var len := roundf(f.size * (1.0 - k * k))
		var c := Color(f.color, 1.0 - k)
		var p2 := f.pos.round()
		if len >= 1.0:
			draw_rect(Rect2(p2.x - len, p2.y, len * 2.0 + 1.0, 1.0), c)
			draw_rect(Rect2(p2.x, p2.y - len, 1.0, len * 2.0 + 1.0), c)
			var d := roundf(len * 0.45)
			for s: Vector2 in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
				for i in range(1, int(d) + 1):
					draw_rect(Rect2(p2 + s * float(i), Vector2.ONE), Color(c, c.a * 0.6))
		draw_circle(p2, maxf(1.0, f.size * 0.6 * (1.0 - k)), Color(c, c.a * 0.5))


## A slowly turning rune circle at the student's feet; brighter while balls are in hand.
func _draw_circle_under(battle: Battle) -> void:
	var p := battle.player.round() + Vector2(0, 7)
	var col := Color(0.41, 0.85, 0.91)
	var a := 0.16
	draw_arc(p, 12.0, 0.0, TAU, 32, Color(col, a), 1.0)
	draw_arc(p, 8.0, 0.0, TAU, 24, Color(col, a * 0.7), 1.0)
	for i in 6:
		var ang := _t * 0.6 + float(i) * TAU / 6.0
		var q := (p + Vector2.from_angle(ang) * 10.0).round()
		draw_rect(Rect2(q, Vector2.ONE), Color(col, a * 2.0))
