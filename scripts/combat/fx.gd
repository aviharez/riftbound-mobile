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
	var crit: bool = false


## A 4-point star flash (hits, kills), drawn by the additive glow layer.
class Flare:
	var pos: Vector2
	var color: Color
	var size: float
	var t: float = 0.0
	var life: float = 0.18


var balance: CombatBalance
var font: Font
var _particles: Array[Particle] = []
var _rings: Array[Ring] = []
var _bolts: Array[Bolt] = []
var _numbers: Array[Number] = []
var flares: Array[Flare] = []
var glow: FxGlow
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	glow = FxGlow.new()
	glow.fx = self
	add_child(glow)


func clear() -> void:
	flares.clear()
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


func number(at: Vector2, text: String, color: Color, crit: bool = false) -> void:
	if _numbers.size() >= balance.max_damage_numbers:
		return
	var n := Number.new()
	n.pos = at
	n.text = text
	n.color = color
	n.crit = crit
	if crit:
		n.max_t = 0.8
	_numbers.append(n)


func flare(at: Vector2, color: Color, size: float = 5.0, life: float = 0.18) -> void:
	if flares.size() >= balance.max_flares:
		return
	var f := Flare.new()
	f.pos = at
	f.color = color
	f.size = size
	f.life = life
	flares.append(f)


## Live bolts, for the glow layer.
func bolts() -> Array[Bolt]:
	return _bolts


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
	for f: Flare in flares:
		f.t += dt
	flares = flares.filter(func(f: Flare) -> bool: return f.t < f.life)


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
		var k := n.t / n.max_t
		var a := 1.0 - k * k
		var at := n.pos.round() + Vector2(-24.0, 0.0)
		var outline := Color(0.08, 0.02, 0.12, a)
		var sz := 8
		if n.crit:
			# Pop in big, then settle (whole font sizes only).
			sz = 16 if n.t < 0.12 else 8
			if n.t < 0.12:
				at.y -= 4.0
		for o: Vector2 in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1), Vector2(1, 1)]:
			draw_string(font, at + o, n.text, HORIZONTAL_ALIGNMENT_CENTER, 48.0, sz, outline)
		draw_string(font, at, n.text, HORIZONTAL_ALIGNMENT_CENTER, 48.0, sz, Color(n.color, a))
