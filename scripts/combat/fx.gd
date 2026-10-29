class_name Fx
extends Node2D
## World-space feedback drawn above the battle: particles, rings, lightning bolts, damage numbers.
## Everything is pooled in plain arrays and drawn in one _draw() call. Caps come from CombatBalance.


class Particle:
	var pos: Vector2
	var vel: Vector2
	var life: float
	var max_life: float
	var color: Color
	var size: float


class Ring:
	var pos: Vector2
	var max_radius: float
	var color: Color
	var life: float
	var t: float = 0.0


class Bolt:
	var from: Vector2
	var to: Vector2
	var color: Color
	var life: float = 0.18
	var t: float = 0.0


class Number:
	var pos: Vector2
	var text: String
	var color: Color
	var t: float = 0.0
	var max_t: float = 0.6


var balance: CombatBalance
var font: Font
var _particles: Array[Particle] = []
var _rings: Array[Ring] = []
var _bolts: Array[Bolt] = []
var _numbers: Array[Number] = []
var _rng := RandomNumberGenerator.new()


func clear() -> void:
	_particles.clear()
	_rings.clear()
	_bolts.clear()
	_numbers.clear()
	queue_redraw()


func burst(at: Vector2, colors: Array[Color], count: int, speed: float = 70.0, life: float = 0.5, size: float = 1.0) -> void:
	if _particles.size() > balance.max_particles:
		return
	for i in count:
		var p := Particle.new()
		var a := _rng.randf() * TAU
		var v := _rng.randf_range(speed * 0.3, speed)
		p.pos = at
		p.vel = Vector2(cos(a), sin(a)) * v
		p.max_life = life
		p.life = _rng.randf_range(life * 0.5, life)
		p.color = colors[_rng.randi_range(0, colors.size() - 1)]
		p.size = size + (1.0 if _rng.randf() < 0.3 else 0.0)
		_particles.append(p)


## A single drifting particle (trails, embers).
func mote(at: Vector2, vel: Vector2, color: Color, life: float, size: float = 1.0) -> void:
	if _particles.size() > balance.max_particles:
		return
	var p := Particle.new()
	p.pos = at
	p.vel = vel
	p.life = life
	p.max_life = life
	p.color = color
	p.size = size
	_particles.append(p)


func ring(at: Vector2, radius: float, color: Color, life: float = 0.35) -> void:
	if _rings.size() >= balance.max_rings:
		return
	var r := Ring.new()
	r.pos = at
	r.max_radius = radius
	r.color = color
	r.life = life
	_rings.append(r)


func bolt(from: Vector2, to: Vector2, color: Color) -> void:
	var b := Bolt.new()
	b.from = from
	b.to = to
	b.color = color
	_bolts.append(b)


func number(at: Vector2, text: String, color: Color) -> void:
	if _numbers.size() >= balance.max_damage_numbers:
		return
	var n := Number.new()
	n.pos = at
	n.text = text
	n.color = color
	_numbers.append(n)


func step(dt: float) -> void:
	var damp := pow(0.92, dt * 60.0)
	for p: Particle in _particles:
		p.pos += p.vel * dt
		p.vel *= damp
		p.vel.y += 45.0 * dt
		p.life -= dt
	_particles = _particles.filter(func(p: Particle) -> bool: return p.life > 0.0)
	for r: Ring in _rings:
		r.t += dt
	_rings = _rings.filter(func(r: Ring) -> bool: return r.t < r.life)
	for b: Bolt in _bolts:
		b.t += dt
	_bolts = _bolts.filter(func(b: Bolt) -> bool: return b.t < b.life)
	for n: Number in _numbers:
		n.t += dt
		n.pos.y -= 16.0 * dt
	_numbers = _numbers.filter(func(n: Number) -> bool: return n.t < n.max_t)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	for b: Bolt in _bolts:
		var c := Color(b.color, 1.0 - b.t / b.life)
		var pts := PackedVector2Array([b.from])
		for i in range(1, 5):
			var k := float(i) / 5.0
			pts.append(b.from.lerp(b.to, k) + Vector2(_rng.randf_range(-3, 3), _rng.randf_range(-3, 3)))
		pts.append(b.to)
		draw_polyline(pts, c, 1.0)
		draw_rect(Rect2(b.to.floor() - Vector2.ONE, Vector2(2, 2)), Color.WHITE)
	for r: Ring in _rings:
		var k := r.t / r.life
		var radius := 2.0 + (r.max_radius - 2.0) * (1.0 - (1.0 - k) * (1.0 - k))
		draw_arc(r.pos.round(), radius, 0.0, TAU, maxi(12, int(radius * 1.5)), Color(r.color, 1.0 - k), 1.5)
	for p: Particle in _particles:
		var a := clampf(p.life / p.max_life * 1.4, 0.0, 1.0)
		draw_rect(Rect2(p.pos.round(), Vector2(p.size, p.size)), Color(p.color, p.color.a * a))
	for n: Number in _numbers:
		var a := 1.0 - n.t / n.max_t
		var at := n.pos.round() + Vector2(-20.0, 0.0)
		draw_string(font, at + Vector2(1, 1), n.text, HORIZONTAL_ALIGNMENT_CENTER, 40.0, 8, Color(0, 0, 0, a * 0.8))
		draw_string(font, at, n.text, HORIZONTAL_ALIGNMENT_CENTER, 40.0, 8, Color(n.color, a))
