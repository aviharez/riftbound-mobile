class_name Battle
extends Node2D
## One combat run: simulation + drawing of the arena contents (docs/combat-spec.md).
## Coordinates are playfield-local (0..270 x 0..560). Main feeds input and decides when the run is active.
## Everything spawned (balls, enemies, drops) is a plain RefCounted in arrays, drawn in one _draw().

signal level_up_ready
signal fusion_ready
signal run_ended
## A fusion happened (for the codex; Battle itself never touches GameState).
signal fused(result: BallSlot)

const PRISM_COLORS: Array[Color] = [Color("ff6a6a"), Color("ffd27a"), Color("7fe0a8"), Color("69D8E8"), Color("a98bff")]
const COL_GEM := Color("7fe0a8")
const COL_GEM_DARK := Color("1d4a33")
const COL_GOLD := Color("ffd27a")
const COL_PARCH := Color("F3EBDD")
const COL_CYAN := Color("69D8E8")
const COL_DANGER := Color("ff5a6a")


class Blast:
	var pos: Vector2
	var radius: float
	var damage: int
	var color: Color


class ChainHit:
	var pos: Vector2
	var from: Enemy
	var hops: int
	var damage: int
	var slow: bool
	var color: Color


class Orb:
	var pos: Vector2
	var vel: Vector2
	var t: float = 0.0


class Callout:
	var text: String
	var color: Color
	var t: float = 0.0
	var max_t: float = 1.3


@onready var fx: Fx = $Fx

var balance: CombatBalance
var settings: PlayerSettings
var font: Font
var loadout: Loadout
## The student playing this run (starting element, ultimate, colors).
var character: CharacterData
var mods: Loadout.Mods
var rng := RandomNumberGenerator.new()

## Set by Main: the simulation only advances while true.
var active: bool = false
var speed: int = 1

# Run state (read by the HUD and the overlays).
var hp: int = 10
var max_hp: int = 10
var wave: int = 1
var rows: int = 0
var kills: int = 0
var catches: int = 0
var run_time: float = 0.0
var over: bool = false
var energy: float = 0.0
var boss_pending: bool = false
var boss_active: bool = false
var bosses: int = 0
var level: int = 1
var xp: int = 0
var pending_levels: int = 0
var rerolls: int = 2
var prisms: int = 0
var fusions: int = 0
var shards: int = 0
var popups: Array[Callout] = []

var player: Vector2 = Vector2(135, 520)
var aim_deg: float = 90.0

var balls: Array[Ball] = []
var enemies: Array[Enemy] = []
var drops: Array[Drop] = []
var orbs: Array[Orb] = []
var _blasts: Array[Blast] = []
var _chains: Array[ChainHit] = []

var hitstop: float = 0.0
var trauma: float = 0.0
var red_flash: float = 0.0
var _fire_timer: float = 0.0
var _last_row_y: float = 0.0
var _fusion_snooze: String = ""
var _boss_data: EnemyData
var _regular: Array[EnemyData] = []
var _fallback_enemy: EnemyData
var _columns: Array = []  # Array of Array[Enemy], rebuilt each frame (enemies never move sideways)
var _drop_columns: Array = []


func _ready() -> void:
	balance = Registry.balance
	fx.balance = balance
	for e: EnemyData in Registry.enemies.values():
		if e.is_boss:
			_boss_data = e
		elif e.spawn_chance_base < 0.0:
			_fallback_enemy = e
		else:
			_regular.append(e)
	_regular.sort_custom(func(a: EnemyData, b: EnemyData) -> bool: return String(a.id) < String(b.id))


func setup(p_settings: PlayerSettings, p_font: Font) -> void:
	settings = p_settings
	font = p_font
	fx.font = p_font


# ================================================================= run lifecycle

## `student` decides the starting element and the ultimate; `run_bonuses` comes from GameState.run_bonuses().
func start_run(student: CharacterData = null, run_bonuses: Dictionary = {}) -> void:
	rng.randomize()
	character = student if student else Registry.character(&"lyra")
	loadout = Loadout.create(balance, Registry.elements.get(character.element_id), run_bonuses)
	mods = loadout.mods()
	max_hp = mods.max_hp
	hp = max_hp
	wave = 1
	rows = 0
	kills = 0
	catches = 0
	run_time = 0.0
	over = false
	energy = 0.0
	boss_pending = false
	boss_active = false
	bosses = 0
	level = 1
	xp = 0
	pending_levels = 0
	rerolls = balance.rerolls_per_run + roundi(run_bonuses.get(&"rerolls", 0.0))
	prisms = 0
	fusions = 0
	shards = 0
	popups.clear()
	balls.clear()
	enemies.clear()
	drops.clear()
	orbs.clear()
	_blasts.clear()
	_chains.clear()
	fx.clear()
	player = Vector2(Vector2(balance.world_size).x * 0.5, balance.player_max.y - 28.0)
	aim_deg = balance.start_aim_deg
	_fire_timer = 0.0
	hitstop = 0.0
	trauma = 0.0
	red_flash = 0.0
	_fusion_snooze = ""
	rebuild_balls()
	for k in range(3, -1, -1):
		_spawn_row(balance.first_row_y + float(k) * balance.cell_size, true)
	_last_row_y = balance.first_row_y
	queue_redraw()


func xp_needed() -> int:
	return balance.xp_needed(level)


func wave_progress() -> float:
	if boss_active:
		return 1.0
	var w := balance.boss_every_waves
	return (float((wave - 1) % w) + float(rows % balance.rows_per_wave) / float(balance.rows_per_wave)) / float(w)


func shake_offset() -> Vector2:
	if not settings.screen_shake or trauma <= 0.0:
		return Vector2.ZERO
	var m := trauma * trauma * balance.shake_max_offset
	return Vector2(roundf(rng.randf_range(-m, m)), roundf(rng.randf_range(-m, m)))


# ================================================================= input from Main

func move_by(d: Vector2) -> void:
	player = (player + d * settings.move_sensitivity).clamp(balance.player_min, balance.player_max)


func aim_at(world_point: Vector2) -> void:
	var dir := world_point - (player - Vector2(0, 3))
	var a := rad_to_deg(atan2(-dir.y, dir.x))
	if a < 0.0:
		a = balance.aim_max_deg if a < -90.0 else balance.aim_min_deg
	aim_deg = clampf(a, balance.aim_min_deg, balance.aim_max_deg)


func rotate_aim(dx: float) -> void:
	aim_deg = clampf(aim_deg - dx * settings.aim_sensitivity * 1.2, balance.aim_min_deg, balance.aim_max_deg)


func cast_ultimate() -> void:
	if not active:
		return
	if energy < balance.energy_max:
		fx.number(Vector2(Vector2(balance.world_size).x - 35.0, balance.world_size.y - 80.0), "NOT CHARGED", Color("a29db8"))
		return
	energy = 0.0
	match character.ultimate_id:
		&"frost_nova": _frost_nova()
		&"verdant_bloom": _verdant_bloom()
		_: _flame_orb()


func ultimate_color() -> Color:
	var e: ElementData = Registry.elements.get(character.element_id) if character else null
	return e.glow_color if e else Color("ff6a3d")


## Lyra: an orb along the aim that explodes on the first enemy.
func _flame_orb() -> void:
	var o := Orb.new()
	o.pos = player - Vector2(0, 6)
	o.vel = _aim_dir() * balance.flame_orb_speed
	orbs.append(o)
	fx.burst(o.pos, [Color("ffb347"), Color("ff6a3d"), Color("fff1a8")], 12, 60.0, 0.3, 2.0)
	trauma = minf(1.0, trauma + 0.12)


## Selene: every enemy on the field is slowed for a long time and takes ice damage.
func _frost_nova() -> void:
	var dmg := roundi(balance.frost_nova_damage_base + balance.frost_nova_damage_per_wave * float(wave))
	var ice: Array[Color] = [Color.WHITE, Color("cfe8ff"), Color("96d2ff")]
	for e: Enemy in enemies:
		if not e.alive:
			continue
		e.slow = maxf(e.slow, balance.frost_nova_slow_duration)
		fx.burst(e.center(), ice, 6, 40.0, 0.5, 1.0)
		_hit_enemy(e, dmg, false, null)
	for i in 3:
		fx.ring(player, 120.0 + 90.0 * float(i), Color("96d2ff") if i != 1 else Color.WHITE, 0.45 + 0.15 * float(i))
	hitstop = balance.hitstop_ultimate
	trauma = minf(1.0, trauma + 0.4)


## Noah: heal, gather every gem and prism on the field, and lash the enemies closest to the rune line.
func _verdant_bloom() -> void:
	hp = mini(max_hp, hp + balance.verdant_bloom_heal)
	var gems := 0
	for d: Drop in drops:
		if d.dead:
			continue
		d.dead = true
		fx.mote(d.pos, (player - d.pos) * 2.5, Color("d6ffe6") if not d.prism else Color("ffd27a"), 0.4, 1.0)
		if d.prism:
			prisms += 1
			_fusion_snooze = ""
		else:
			gems += 1
	if gems > 0:
		var n := ceili(float(gems) * mods.xp_mult)
		_gain_xp(n)
		fx.number(player + Vector2(0, -22), "+%d XP" % n, COL_GEM)
	var dmg := roundi(balance.verdant_bloom_damage_base + balance.verdant_bloom_damage_per_wave * float(wave))
	var line := balance.rune_line_y
	for e: Enemy in enemies:
		if e.alive and e.pos.y + e.size > line - balance.verdant_bloom_reach:
			fx.burst(e.center(), [COL_GEM, Color("2f6b47"), Color.WHITE], 8, 50.0, 0.5, 1.0)
			_hit_enemy(e, dmg, false, null)
	var x := float(balance.wall_width) + 8.0
	while x < float(balance.world_size.x - balance.wall_width):
		fx.burst(Vector2(x, line - 2.0), [COL_GEM, Color("2f6b47")], 3, 45.0, 0.6, 1.0)
		x += 16.0
	fx.ring(player, 40.0, COL_GEM, 0.4)
	popup("+%d HP" % balance.verdant_bloom_heal, COL_GEM)
	hitstop = balance.hitstop_ultimate
	trauma = minf(1.0, trauma + 0.3)


# ================================================================= level up / fusion (called by Main)

func offer_cards() -> Array[LevelCard]:
	return loadout.offer(rng)


func reroll_cards() -> Array[LevelCard]:
	rerolls -= 1
	return loadout.offer(rng)


func apply_card(card: LevelCard) -> void:
	var msg := loadout.apply_card(card, rng)
	match card.kind:
		LevelCard.SHARDS:
			shards += balance.fallback_shards
		LevelCard.HEAL:
			hp = mini(max_hp, hp + balance.fallback_heal)
		LevelCard.ENERGY:
			energy = minf(balance.energy_max, energy + balance.fallback_energy)
	_refresh_mods()
	if (card.kind == LevelCard.NEW_ITEM and card.item.stat == &"max_hp") or (card.kind == LevelCard.UP_ITEM and card.item_slot.data.stat == &"max_hp"):
		var heal := card.item.value_per_level if card.item else card.item_slot.data.value_per_level
		hp = mini(max_hp, hp + roundi(heal))
	rebuild_balls()
	pending_levels -= 1
	popup(msg, card.color())


func fusion_pairs() -> Array[Vector2i]:
	return loadout.fusion_pairs()


func apply_fusion(pair: Vector2i) -> void:
	var r := loadout.fuse(pair)
	prisms -= 1
	fusions += 1
	_fusion_snooze = ""
	rebuild_balls()
	fused.emit(r)
	popup(("EVOLUTION: " if r.evolved else "FUSION: ") + r.display_name.to_upper(), r.glow_color)
	fx.ring(player, 46.0, r.glow_color, 0.5)
	fx.ring(player, 22.0, Color.WHITE, 0.35)
	fx.burst(player, [r.glow_color, Color.WHITE, COL_GOLD], 40, 110.0, 0.6, 2.0)
	hitstop = balance.hitstop_fusion
	trauma = minf(1.0, trauma + 0.4)


## "Keep the prism for later": don't reopen until the pairs or the prism count change.
func snooze_fusion() -> void:
	_fusion_snooze = _fusion_signature()


func can_fuse() -> bool:
	return prisms > 0 and not loadout.fusion_pairs().is_empty()


func debug_add_level() -> void:
	level += 1
	pending_levels += 1


func debug_max_balls() -> void:
	for s: BallSlot in loadout.owned_balls():
		s.level = balance.max_level
	_fusion_snooze = ""


func debug_add_prism() -> void:
	prisms += 1
	_fusion_snooze = ""


func debug_add_baby_balls(n: int) -> void:
	loadout.debug_baby_balls += n
	_refresh_mods()
	rebuild_balls()


# ================================================================= simulation

func _process(delta: float) -> void:
	var real_dt := minf(delta, 0.05)
	if active and not over:
		if hitstop > 0.0:
			hitstop -= real_dt
		else:
			_update(real_dt * float(speed))
	trauma = maxf(0.0, trauma - real_dt * balance.trauma_decay)
	red_flash = maxf(0.0, red_flash - real_dt)
	queue_redraw()


func _update(dt: float) -> void:
	run_time += dt
	_keyboard(dt)

	var v := balance.descent_speed(wave)
	_last_row_y += v * dt
	for e: Enemy in enemies:
		if not e.alive:
			continue
		e.pos.y += v * dt * (balance.slow_factor if e.slow > 0.0 else 1.0)
		if e.slow > 0.0:
			e.slow -= dt
		if e.burn > 0.0:
			e.burn -= dt
			e.burn_timer += dt
			if rng.randf() < 0.3:
				fx.mote(e.pos + Vector2(rng.randf_range(3, e.size - 3), rng.randf_range(3, e.size - 3)), Vector2(0, -24), Color("ff6a3d") if rng.randf() < 0.5 else Color("ffb347"), 0.3)
			if e.burn_timer >= balance.burn_tick:
				e.burn_timer = 0.0
				_hit_enemy(e, e.burn_damage, false, null, true)
				if not e.alive:
					continue
		e.flash = maxf(0.0, e.flash - dt)
		e.squash = maxf(0.0, e.squash - dt * 7.0)
		e.spawn = minf(1.0, e.spawn + dt * 3.0)
		e.phase += dt * 3.0
		if e.pos.y + e.size >= balance.rune_line_y:
			e.alive = false
			fx.burst(Vector2(e.center().x, balance.rune_line_y - 3.0), [COL_DANGER, Color("ffb3ba")], 18, 90.0, 0.5, 2.0)
			fx.ring(Vector2(e.center().x, balance.rune_line_y - 3.0), 20.0, COL_DANGER)
			if e.data.is_boss:
				boss_active = false
			_damage_player(e.data.contact_damage)
			if over:
				return
	while _last_row_y - balance.cell_size >= balance.first_row_y:
		_last_row_y -= balance.cell_size
		if boss_pending:
			_last_row_y -= balance.cell_size
			_spawn_boss(_last_row_y)
		else:
			_spawn_row(_last_row_y, false)

	for d: Drop in drops:
		d.pos.y += v * dt
		d.age += dt
		if d.pos.y >= balance.rune_line_y - balance.gem_lost_margin:
			d.dead = true
			fx.burst(d.pos, [COL_GOLD if d.prism else Color(COL_GEM, 0.6)], 3, 24.0, 0.3)

	_rebuild_columns()

	_fire_timer -= dt
	while _fire_timer <= 0.0:
		if not _fire():
			_fire_timer = 0.0
			break
		_fire_timer += mods.fire_interval

	for b: Ball in balls:
		_update_ball(b, dt)

	_update_orbs(dt)
	_resolve_queues()

	enemies = enemies.filter(func(e: Enemy) -> bool: return e.alive)
	drops = drops.filter(func(d: Drop) -> bool: return not d.dead)
	fx.step(dt)
	for p: Callout in popups:
		p.t += dt
	popups = popups.filter(func(p: Callout) -> bool: return p.t < p.max_t)

	if pending_levels > 0:
		level_up_ready.emit()
	elif can_fuse() and _fusion_signature() != _fusion_snooze:
		fusion_ready.emit()


func _keyboard(dt: float) -> void:
	var dir := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		dir.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		dir.x += 1.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		dir.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		dir.y += 1.0
	if dir != Vector2.ZERO:
		player = (player + dir * 150.0 * dt).clamp(balance.player_min, balance.player_max)
	if Input.is_physical_key_pressed(KEY_Q):
		aim_deg = clampf(aim_deg + 80.0 * dt, balance.aim_min_deg, balance.aim_max_deg)
	if Input.is_physical_key_pressed(KEY_E):
		aim_deg = clampf(aim_deg - 80.0 * dt, balance.aim_min_deg, balance.aim_max_deg)


# ----------------------------------------------------------------- spawning

func _spawn_row(row_top: float, instant: bool) -> void:
	rows += 1
	if rows % balance.rows_per_wave == 0:
		wave += 1
		if (wave - 1) % balance.boss_every_waves == 0 and _boss_data:
			boss_pending = true
			popup("BOSS INCOMING", Color("ff6b6b"))
		else:
			popup("WAVE %02d" % wave, Color("E6BD73"))
	var gaps: Array[int] = []
	var n_gaps := rng.randi_range(balance.gaps_min, balance.gaps_max)
	while gaps.size() < n_gaps:
		var g := rng.randi_range(0, balance.grid_columns - 1)
		if not gaps.has(g):
			gaps.append(g)
	for c in balance.grid_columns:
		if gaps.has(c):
			continue
		var data := _roll_enemy()
		var e := Enemy.new()
		e.data = data
		e.size = balance.enemy_size
		e.pos = Vector2(float(balance.wall_width) + float(c) * balance.cell_size + (balance.cell_size - e.size) * 0.5, row_top + (balance.cell_size - e.size) * 0.5)
		e.max_hp = data.hp_for_wave(wave, balance)
		e.hp = e.max_hp
		e.spawn = 1.0 if instant else 0.0
		e.phase = rng.randf() * TAU
		enemies.append(e)


func _roll_enemy() -> EnemyData:
	var r := rng.randf()
	var acc := 0.0
	for e: EnemyData in _regular:
		acc += e.spawn_chance_base + e.spawn_chance_per_wave * float(wave)
		if r < acc:
			return e
	return _fallback_enemy


func _spawn_boss(top: float) -> void:
	var e := Enemy.new()
	e.data = _boss_data
	e.size = balance.cell_size * float(_boss_data.size_cells - 1) + balance.enemy_size
	# Centred on the field, whatever the column count (7 columns = between cells, which is fine for a boss).
	var field_w := float(balance.grid_columns) * balance.cell_size
	e.pos = Vector2(float(balance.wall_width) + (field_w - e.size) * 0.5, top + (balance.cell_size - balance.enemy_size) * 0.5)
	e.max_hp = _boss_data.hp_for_wave(wave, balance)
	e.hp = e.max_hp
	enemies.append(e)
	boss_pending = false
	boss_active = true


# ----------------------------------------------------------------- balls

func rebuild_balls() -> void:
	var want: Array = []
	for s: BallSlot in loadout.owned_balls():
		for i in s.count:
			want.append(["%d:%d" % [s.uid, i], s])
	for i in mods.baby_balls:
		want.append(["baby:%d" % i, null])
	var old := {}
	for b: Ball in balls:
		old[b.key] = b
	var next: Array[Ball] = []
	for w: Array in want:
		var b: Ball = old.get(w[0])
		if b:
			old.erase(w[0])
		else:
			b = Ball.new()
			b.key = w[0]
			b.pos = player
		b.slot = w[1]
		next.append(b)
	for b: Ball in old.values():
		if b.state != Ball.State.HAND:
			fx.burst(b.pos, [Color.WHITE], 4, 30.0, 0.3)
		if b.prism:
			prisms += 1
		if b.gems > 0:
			_gain_xp(b.gems)
	balls = next


func _fire() -> bool:
	var pick: Ball = null
	for b: Ball in balls:
		if b.state == Ball.State.HAND and b.charged:
			pick = b
			break
	if pick == null:
		for b: Ball in balls:
			if b.state == Ball.State.HAND:
				pick = b
				break
	if pick == null:
		return false
	var dir := _aim_dir()
	pick.state = Ball.State.FLY
	pick.pos = player + Vector2(0, -3) + dir * balance.launch_offset
	pick.vel = dir * balance.ball_speed
	pick.bounces = 0
	pick.trail.clear()
	fx.burst(pick.pos, [COL_GOLD if pick.charged else (pick.slot.glow_color if pick.slot else Color.WHITE)], 2, 30.0, 0.15)
	return true


func _update_ball(b: Ball, dt: float) -> void:
	if b.state == Ball.State.HAND:
		b.pos = player
		return
	b.push_trail()
	if b.state == Ball.State.RETURN:
		var to := player - b.pos
		var d := to.length()
		var step := balance.return_speed * dt
		if d < step + 5.0:
			b.state = Ball.State.HAND
			b.charged = false
			_deliver(b, false)
		else:
			b.pos += to / d * step
		return

	var r := balance.ball_radius
	var steps := maxi(1, ceili(balance.ball_speed * dt / balance.max_substep))
	var sdt := dt / float(steps)
	var cap := _ball_capacity(b)
	var reach := _ball_reach(b)
	for _i in steps:
		b.pos += b.vel * sdt
		if _walls(b, r):
			b.bounces += 1
		var col := _column_of(b.pos.x)
		var hit := false
		for ci in range(col - 1, col + 2):
			if ci < 0 or ci >= _columns.size():
				continue
			for e: Enemy in _columns[ci]:
				if not e.alive or b.pos.y < e.pos.y - 4.0 or b.pos.y > e.pos.y + e.size + 4.0:
					continue
				if _collide_rect(b, e.pos, e.size, r):
					var base := b.slot.damage if b.slot else balance.baby_ball_damage
					_hit_enemy(e, base * mods.catch_multiplier if b.charged else base, b.charged, b.slot)
					b.bounces += 1
					hit = true
					break
			if hit:
				break
		if hit:
			_walls(b, r)  # an enemy next to a wall can push the ball into it
		_absorb_drops(b, col, cap, reach)
		_fix_angle(b)
		if b.vel.y > 0.0 and b.bounces > 0 and b.pos.distance_to(player - Vector2(0, 2)) < balance.catch_radius:
			_catch(b)
			return
		if b.pos.y > balance.lost_below_y:
			b.state = Ball.State.RETURN
			b.charged = false
			return


func _ball_capacity(b: Ball) -> int:
	var cap := mods.gem_capacity
	if b.slot and b.slot.has_effect(&"siphon"):
		cap *= balance.siphon_capacity_multiplier
	return cap


func _ball_reach(b: Ball) -> float:
	var reach := mods.gem_reach
	if b.slot and b.slot.has_effect(&"siphon"):
		reach += balance.siphon_reach_bonus
	return reach


func _absorb_drops(b: Ball, col: int, cap: int, reach: float) -> void:
	for ci in range(col - 1, col + 2):
		if ci < 0 or ci >= _drop_columns.size():
			continue
		for d: Drop in _drop_columns[ci]:
			if d.dead:
				continue
			var rr := reach + (2.0 if d.prism else 0.0)
			if absf(d.pos.x - b.pos.x) > rr or absf(d.pos.y - b.pos.y) > rr:
				continue
			if d.prism:
				if b.prism:
					continue
				b.prism = true
				d.dead = true
				fx.ring(d.pos, 10.0, COL_GOLD, 0.25)
				continue
			if b.gems >= cap:
				continue
			d.dead = true
			b.gems += 1
			fx.mote(d.pos, b.vel * 0.05, Color("d6ffe6"), 0.25)


func _catch(b: Ball) -> void:
	b.state = Ball.State.HAND
	b.charged = true
	catches += 1
	_gain_energy(balance.catch_energy)
	_deliver(b, true)
	fx.number(player + Vector2(0, -16), "CATCH", COL_GOLD)
	fx.burst(player + Vector2(0, -3), [COL_GOLD, Color("fff3c4")], 8, 45.0, 0.3)
	fx.ring(player + Vector2(0, -2), 10.0, COL_GOLD, 0.25)
	_fire_timer = minf(_fire_timer, 0.0)


func _deliver(b: Ball, caught: bool) -> void:
	if b.prism:
		b.prism = false
		prisms += 1
		_fusion_snooze = ""
		popup("RIFT PRISM", COL_GOLD)
		fx.burst(player + Vector2(0, -5), PRISM_COLORS, 16, 60.0, 0.5, 2.0)
	if b.gems <= 0:
		return
	var n := b.gems
	if caught:
		var bonus := balance.catch_xp_bonus_max if mods.catch_multiplier >= balance.catch_multiplier + 1 else balance.catch_xp_bonus
		n = ceili(float(b.gems) * bonus)
	n = ceili(float(n) * mods.xp_mult)
	b.gems = 0
	_gain_xp(n)
	fx.number(player + Vector2(rng.randf_range(-5, 5), -22), "+%d XP" % n, COL_GEM)


func _update_orbs(dt: float) -> void:
	var size := Vector2(balance.world_size)
	for o: Orb in orbs:
		o.t += dt
		var steps := maxi(1, ceili(balance.flame_orb_speed * dt / balance.max_substep))
		var sdt := dt / float(steps)
		var boom := false
		for _i in steps:
			o.pos += o.vel * sdt
			if o.pos.y < balance.ceiling_y + 5.0:
				boom = true
				break
			var left := float(balance.wall_width) + 5.0
			var right := size.x - float(balance.wall_width) - 5.0
			if o.pos.x < left:
				o.pos.x = left
				o.vel.x = absf(o.vel.x)
			elif o.pos.x > right:
				o.pos.x = right
				o.vel.x = -absf(o.vel.x)
			for e: Enemy in enemies:
				if e.alive and e.rect().grow(5.0).has_point(o.pos):
					boom = true
					break
			if boom:
				break
		if rng.randf() < 0.9:
			fx.mote(o.pos + Vector2(rng.randf_range(-2, 2), rng.randf_range(-2, 2)), Vector2(rng.randf_range(-15, 15), rng.randf_range(8, 30)), Color("ff6a3d") if rng.randf() < 0.5 else Color("ffb347"), 0.35, 2.0)
		if boom:
			_explode(o.pos)
			o.t = INF
		elif o.pos.y > size.y or o.t > 4.0:
			o.t = INF
	orbs = orbs.filter(func(o: Orb) -> bool: return o.t != INF)


func _explode(at: Vector2) -> void:
	var dmg := roundi(balance.flame_orb_damage_base + balance.flame_orb_damage_per_wave * float(wave))
	for e: Enemy in enemies:
		if e.alive and e.center().distance_to(at) < balance.flame_orb_radius + e.size * 0.35:
			_hit_enemy(e, dmg, true, null)
	fx.ring(at, balance.flame_orb_radius, Color("ffb347"), 0.4)
	fx.ring(at, balance.flame_orb_radius * 0.6, Color("fff1a8"), 0.3)
	fx.burst(at, [Color("ffb347"), Color("ff6a3d"), Color("fff1a8"), Color.WHITE], 46, 130.0, 0.7, 2.0)
	hitstop = balance.hitstop_ultimate
	trauma = minf(1.0, trauma + 0.55)


# ----------------------------------------------------------------- damage and effects

func _hit_enemy(e: Enemy, dmg: int, charged: bool, src: BallSlot, is_burn: bool = false) -> void:
	if not e.alive:
		return
	e.hp -= dmg
	e.flash = balance.flash_time
	e.squash = 1.0
	var c := e.center()
	var sparks: Array[Color] = [COL_GOLD, Color("fff3c4")]
	if not charged:
		sparks = [Color.WHITE, src.glow_color if src else Color("e8e8f0")]
	fx.burst(c + Vector2(rng.randf_range(-5, 5), rng.randf_range(-5, 5)), sparks, 3, 55.0, 0.25)
	if not is_burn:
		fx.flare(c + Vector2(rng.randf_range(-4, 4), rng.randf_range(-4, 4)), COL_GOLD if charged else (src.glow_color if src else Color.WHITE), 7.0 if charged else 4.0)
	if settings.damage_numbers:
		var col := Color("ffb347") if charged else (Color("ff9a5a") if is_burn else COL_PARCH)
		fx.number(Vector2(c.x + rng.randf_range(-6, 6), e.pos.y + 10.0), str(dmg), col, charged)
	if src:
		_apply_effects(e, dmg, src)
	if e.hp <= 0:
		_kill(e)


func _apply_effects(e: Enemy, dmg: int, src: BallSlot) -> void:
	var p := src.power
	var c := e.center()
	if src.has_effect(&"burn"):
		e.burn = balance.burn_base_duration + float(p)
		e.burn_damage = p
		if src.has_effect(&"spread"):
			for o: Enemy in enemies:
				if o != e and o.alive and o.center().distance_to(c) < balance.spread_radius:
					o.burn = maxf(o.burn, balance.burn_base_duration + float(p))
					o.burn_damage = p
	if src.has_effect(&"slow"):
		e.slow = balance.slow_base_duration + balance.slow_duration_per_power * float(p)
	if src.has_effect(&"blast"):
		var bl := Blast.new()
		bl.pos = c
		bl.radius = balance.blast_base_radius + balance.blast_radius_per_power * float(p)
		bl.damage = p
		bl.color = Color("e2e8f0")
		_blasts.append(bl)
	if src.has_effect(&"chain"):
		var ch := ChainHit.new()
		ch.pos = c
		ch.from = e
		ch.hops = p
		ch.damage = maxi(1, dmg - 1)
		ch.slow = src.has_effect(&"chainSlow")
		ch.color = src.glow_color
		_chains.append(ch)


func _kill(e: Enemy) -> void:
	e.alive = false
	kills += 1
	var c := e.center()
	for i in e.data.gem_drop:
		var d := Drop.new()
		d.pos = e.pos + Vector2(rng.randf_range(4, e.size - 4), rng.randf_range(4, e.size - 4))
		d.age = rng.randf() * 6.0
		drops.append(d)
	if e.data.prism_chance > 0.0 and rng.randf() < e.data.prism_chance:
		var pd := Drop.new()
		pd.pos = c
		pd.prism = true
		drops.append(pd)
	_gain_energy(e.data.energy_on_kill)
	if e.data.is_boss:
		boss_active = false
		bosses += 1
		fx.burst(c, [Color("ff6b6b"), Color("6b4aa8"), Color("E6BD73"), Color.WHITE], 90, 170.0, 0.9, 2.0)
		fx.ring(c, 68.0, Color("ff6b6b"), 0.5)
		fx.flare(c, Color("ffe3a3"), 24.0, 0.4)
		fx.ring(c, 41.0, Color("E6BD73"), 0.4)
		hitstop = balance.hitstop_boss
		trauma = 1.0
		popup("BOSS DEFEATED", Color("E6BD73"))
	else:
		var big := e.data.hp_multiplier >= 2.0
		fx.burst(c, _enemy_colors(e.data.id), 26 if big else 16, 90.0, 0.6, 2.0)
		fx.burst(c, [Color("2a1650"), Color("4b2a86")], 10 if big else 6, 50.0, 0.5, 2.0)
		fx.flare(c, Color("c9b6ff"), 12.0 if big else 9.0, 0.24)
		fx.ring(c, 26.0 if big else 17.0, COL_CYAN if e.data.death_blast_radius > 0.0 else Color("a98bff"))
		hitstop = minf(balance.hitstop_cap, hitstop + balance.hitstop_kill)
		trauma = minf(1.0, trauma + (0.25 if big else 0.1))
	if e.data.death_blast_radius > 0.0:
		var bl := Blast.new()
		bl.pos = c
		bl.radius = e.data.death_blast_radius
		bl.damage = e.data.death_blast_damage
		bl.color = COL_CYAN
		_blasts.append(bl)


## Area hits and chain lightning queued this frame. Kills they cause queue more for the next frame.
func _resolve_queues() -> void:
	if not _blasts.is_empty():
		var list := _blasts
		_blasts = []
		for bl: Blast in list:
			fx.ring(bl.pos, bl.radius, bl.color, 0.3)
			for e: Enemy in enemies:
				if e.alive and e.center().distance_to(bl.pos) < bl.radius:
					_hit_enemy(e, bl.damage, false, null)
	if not _chains.is_empty():
		var chains := _chains
		_chains = []
		for ch: ChainHit in chains:
			var at := ch.pos
			var seen: Array[Enemy] = [ch.from]
			for _k in ch.hops:
				var best: Enemy = null
				var best_d := balance.chain_range
				for e: Enemy in enemies:
					if not e.alive or seen.has(e):
						continue
					var d := e.center().distance_to(at)
					if d < best_d:
						best_d = d
						best = e
				if best == null:
					break
				seen.append(best)
				fx.bolt(at, best.center(), ch.color)
				if ch.slow:
					best.slow = balance.chain_slow_duration
				at = best.center()
				_hit_enemy(best, ch.damage, false, null)


func _damage_player(n: int) -> void:
	hp = maxi(0, hp - n)
	trauma = minf(1.0, trauma + 0.5)
	red_flash = 0.3
	if hp <= 0 and not over:
		over = true
		run_ended.emit()


func _gain_energy(n: float) -> void:
	var was := energy
	energy = minf(balance.energy_max, energy + n * mods.energy_gain)
	if was < balance.energy_max and energy >= balance.energy_max:
		popup("ULTIMATE READY", Color("ffb347"))


func _gain_xp(n: int) -> void:
	xp += n
	while xp >= balance.xp_needed(level):
		xp -= balance.xp_needed(level)
		level += 1
		pending_levels += 1


func popup(text: String, color: Color) -> void:
	var p := Callout.new()
	p.text = text
	p.color = color
	popups.append(p)
	if popups.size() > 3:
		popups.pop_front()


func _refresh_mods() -> void:
	mods = loadout.mods()
	max_hp = mods.max_hp
	hp = mini(hp, max_hp)


func _fusion_signature() -> String:
	var parts: Array[String] = []
	for p: Vector2i in loadout.fusion_pairs():
		parts.append("%d%d" % [p.x, p.y])
	return ",".join(parts) + "|%d" % prisms


# ----------------------------------------------------------------- geometry

func _aim_dir() -> Vector2:
	var a := deg_to_rad(aim_deg)
	return Vector2(cos(a), -sin(a))


func _column_of(x: float) -> int:
	return int(floorf((x - float(balance.wall_width)) / balance.cell_size))


func _rebuild_columns() -> void:
	_columns.resize(balance.grid_columns)
	_drop_columns.resize(balance.grid_columns)
	for i in balance.grid_columns:
		_columns[i] = []
		_drop_columns[i] = []
	for e: Enemy in enemies:
		if not e.alive:
			continue
		var c0 := clampi(_column_of(e.pos.x), 0, balance.grid_columns - 1)
		var c1 := clampi(_column_of(e.pos.x + e.size), 0, balance.grid_columns - 1)
		for c in range(c0, c1 + 1):
			_columns[c].append(e)
	for d: Drop in drops:
		if not d.dead:
			_drop_columns[clampi(_column_of(d.pos.x), 0, balance.grid_columns - 1)].append(d)


func _walls(b: Ball, r: float) -> bool:
	var size := Vector2(balance.world_size)
	var hit := false
	var left := float(balance.wall_width) + r
	var right := size.x - float(balance.wall_width) - r
	if b.pos.x < left:
		b.pos.x = left
		b.vel.x = absf(b.vel.x)
		hit = true
	elif b.pos.x > right:
		b.pos.x = right
		b.vel.x = -absf(b.vel.x)
		hit = true
	if b.pos.y < balance.ceiling_y + r:
		b.pos.y = balance.ceiling_y + r
		b.vel.y = absf(b.vel.y)
		hit = true
	return hit


## Circle vs axis-aligned square. Reflects the velocity and pushes the ball out. Returns true on contact.
static func _collide_rect(b: Ball, top_left: Vector2, size: float, r: float) -> bool:
	var closest := Vector2(clampf(b.pos.x, top_left.x, top_left.x + size), clampf(b.pos.y, top_left.y, top_left.y + size))
	var delta := b.pos - closest
	var d2 := delta.length_squared()
	if d2 >= r * r:
		return false
	var n := Vector2.ZERO
	if d2 > 0.000001:
		n = delta / sqrt(d2)
		b.pos = closest + n * (r + 0.3)
	else:
		var l := b.pos.x - top_left.x
		var rr := top_left.x + size - b.pos.x
		var t := b.pos.y - top_left.y
		var bt := top_left.y + size - b.pos.y
		var m := minf(minf(l, rr), minf(t, bt))
		if m == l:
			n = Vector2.LEFT
			b.pos.x = top_left.x - r - 0.3
		elif m == rr:
			n = Vector2.RIGHT
			b.pos.x = top_left.x + size + r + 0.3
		elif m == t:
			n = Vector2.UP
			b.pos.y = top_left.y - r - 0.3
		else:
			n = Vector2.DOWN
			b.pos.y = top_left.y + size + r + 0.3
	var dot := b.vel.dot(n)
	if dot < 0.0:
		b.vel -= 2.0 * dot * n
	return true


func _fix_angle(b: Ball) -> void:
	var sp := b.vel.length()
	var min_vy := sp * balance.min_vertical_ratio
	if absf(b.vel.y) < min_vy:
		b.vel.y = min_vy if b.vel.y >= 0.0 else -min_vy
		b.vel.x = signf(b.vel.x if b.vel.x != 0.0 else 1.0) * sqrt(sp * sp - min_vy * min_vy)


# ================================================================= drawing

func _draw() -> void:
	if loadout == null:
		return
	for e: Enemy in enemies:
		_draw_enemy(e)
		if e.slow > 0.0:
			draw_rect(e.rect(), Color(0.59, 0.82, 1.0, 0.28))
	_draw_drops()
	if active or not over:
		_draw_aim()
	for b: Ball in balls:
		if b.state != Ball.State.HAND:
			_draw_ball(b)
	for o: Orb in orbs:
		var p := o.pos.round()
		var f := float(int(run_time * 20.0) % 2)
		draw_rect(Rect2(p - Vector2(5 + f, 5 + f), Vector2(11 + 2 * f, 11 + 2 * f)), Color(1.0, 0.42, 0.24, 0.5))
		draw_rect(Rect2(p - Vector2(3, 3), Vector2(7, 7)), Color("ff6a3d"))
		draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), COL_GOLD)
		draw_rect(Rect2(p - Vector2(1, 1), Vector2(2, 2)), Color.WHITE)
	_draw_player()
	_draw_zone_labels()


func _draw_enemy(e: Enemy) -> void:
	var k := e.spawn * (1.0 + e.squash * 0.12)
	var s := roundf(e.size * k)
	if s < 2.0:
		return
	var x := roundf(e.pos.x + (e.size - s) * 0.5)
	var y := roundf(e.pos.y + (e.size - s) * 0.5)
	if e.data.sprite:
		_draw_enemy_sprite(e)
		return
	if e.flash > 0.0:
		draw_rect(Rect2(x, y, s, s), Color.WHITE)
		return
	var bob := roundf(sin(e.phase))
	match e.data.id:
		&"boss_warden":
			draw_rect(Rect2(x, y, s, s), Color("0e0718"))
			draw_rect(Rect2(x + 2, y + 2, s - 4, s - 4), Color("34204f"))
			draw_rect(Rect2(x + 2, y + s - 11, s - 4, 6), Color("4a2f72"))
			var horn := Color("b8955a")
			draw_rect(Rect2(x + 3, y + 3, 6, 3), horn)
			draw_rect(Rect2(x + 3, y + 6, 3, 5), horn)
			draw_rect(Rect2(x + s - 9, y + 3, 6, 3), horn)
			draw_rect(Rect2(x + s - 6, y + 6, 3, 5), horn)
			var ex := x + floorf(s * 0.5)
			var ey := y + floorf(s * 0.45) + bob
			var look := roundf(sin(e.phase * 0.5) * 3.0)
			draw_rect(Rect2(ex - 8, ey - 5, 16, 10), Color("1a0d2b"))
			draw_rect(Rect2(ex - 7, ey - 4, 14, 8), Color("ff6b6b"))
			draw_rect(Rect2(ex - 2 + look, ey - 2, 4, 4), COL_CYAN)
			draw_rect(Rect2(ex - 1 + look, ey - 1, 1, 1), Color.WHITE)
			draw_rect(Rect2(x, y - 6, s, 3), Color(0, 0, 0, 0.7))
			draw_rect(Rect2(x, y - 6, maxf(1.0, roundf(s * float(e.hp) / float(e.max_hp))), 3), Color("ff6b6b"))
			return
		&"brute":
			draw_rect(Rect2(x, y, s, s), Color("120a20"))
			draw_rect(Rect2(x + 2, y + 2, s - 4, s - 4), Color("3f2968"))
			draw_rect(Rect2(x + 2, y + s - 6, s - 4, 3), Color("563a8a"))
			draw_rect(Rect2(x + 2, y + 2, 3, 2), Color("b8955a"))
			draw_rect(Rect2(x + 2, y + 4, 2, 2), Color("b8955a"))
			draw_rect(Rect2(x + s - 5, y + 2, 3, 2), Color("b8955a"))
			draw_rect(Rect2(x + s - 4, y + 4, 2, 2), Color("b8955a"))
			draw_rect(Rect2(x + floorf(s * 0.5) - 2, y + floorf(s * 0.42) + bob, 5, 4), Color("ff6b6b"))
			draw_rect(Rect2(x + floorf(s * 0.5) - 1, y + floorf(s * 0.42) + 1 + bob, 2, 1), Color("ffd0d0"))
		&"shard":
			draw_rect(Rect2(x, y, s, s), Color("141b26"))
			draw_rect(Rect2(x + 2, y + 2, s - 4, s - 4), Color("1f2a3a"))
			var cx := x + s * 0.5
			var cy := y + s * 0.5 + bob
			var r := s * 0.36
			draw_colored_polygon(PackedVector2Array([Vector2(cx, cy - r), Vector2(cx + r * 0.7, cy), Vector2(cx, cy + r), Vector2(cx - r * 0.7, cy)]), COL_CYAN)
			draw_rect(Rect2(roundf(cx - 1.5), roundf(cy - 2), 3, 4), Color("6F4AE6"))
		_:
			draw_rect(Rect2(x, y, s, s), Color("1b1130"))
			draw_rect(Rect2(x + 2, y + 2, s - 4, s - 4), Color("5e3bb8"))
			draw_rect(Rect2(x + 2, y + 2, s - 4, 2), Color("7c58d6"))
			draw_rect(Rect2(x + floorf(s * 0.26), y + floorf(s * 0.38) + bob, 3, 3), Color("9ff3ff"))
			draw_rect(Rect2(x + floorf(s * 0.62), y + floorf(s * 0.38) + bob, 3, 3), Color("9ff3ff"))
			draw_rect(Rect2(x + floorf(s * 0.36), y + floorf(s * 0.68), floorf(s * 0.28), 1), Color("1b1130"))
	if e.hp < e.max_hp:
		draw_rect(Rect2(x + 2, y + s - 3, s - 4, 1), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(x + 2, y + s - 3, maxf(1.0, roundf((s - 4.0) * float(e.hp) / float(e.max_hp))), 1), Color("ff6b6b"))


## Generated sprite, centred on the hitbox at whole pixels. Spawn fades in instead of scaling (no mixels);
## a hit shows the cached white silhouette.
func _draw_enemy_sprite(e: Enemy) -> void:
	var tex := e.data.sprite
	var sz := tex.get_size()
	var bob := roundf(sin(e.phase))
	var pos := (e.pos + Vector2(e.size, e.size) * 0.5 - sz * 0.5).round() + Vector2(0.0, bob)
	var a := clampf(e.spawn, 0.0, 1.0)
	# Contact shadow so the creature sits on the 3/4 floor of the painted arena.
	var foot := (e.pos + Vector2(e.size * 0.5, e.size - 1.0)).round()
	draw_rect(Rect2(foot.x - 8.0, foot.y, 16.0, 2.0), Color(0, 0, 0, 0.35 * a))
	draw_rect(Rect2(foot.x - 6.0, foot.y - 1.0, 12.0, 4.0), Color(0, 0, 0, 0.2 * a))
	draw_texture(SpriteKit.white(tex) if e.flash > 0.0 else tex, pos, Color(1, 1, 1, a))
	if e.hp < e.max_hp and e.flash <= 0.0:
		var x := roundf(e.pos.x)
		var y := roundf(e.pos.y + e.size + 1.0)
		draw_rect(Rect2(x + 2, y, e.size - 4, 1), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(x + 2, y, maxf(1.0, roundf((e.size - 4.0) * float(e.hp) / float(e.max_hp))), 1), Color("ff6b6b"))


func _enemy_colors(id: StringName) -> Array[Color]:
	match id:
		&"brute": return [Color("6b4aa8"), Color("E6BD73"), Color.WHITE]
		&"shard": return [COL_CYAN, Color("6F4AE6"), Color.WHITE]
	return [Color("8d6ae0"), Color("c9b6ff"), Color.WHITE]


func _draw_drops() -> void:
	for d: Drop in drops:
		var p := (d.pos + Vector2(0, roundf(sin(d.age * 4.0)))).round()
		if d.prism:
			var c := PRISM_COLORS[int(d.age * 8.0) % PRISM_COLORS.size()]
			draw_rect(Rect2(p.x - 2, p.y - 5, 5, 11), Color("2a1d3a"))
			draw_rect(Rect2(p.x - 4, p.y - 2, 9, 5), Color("2a1d3a"))
			draw_rect(Rect2(p.x - 1, p.y - 4, 3, 9), c)
			draw_rect(Rect2(p.x - 3, p.y - 1, 7, 3), c)
			draw_rect(Rect2(p.x, p.y - 2, 1, 2), Color.WHITE)
			continue
		draw_rect(Rect2(p.x - 1, p.y - 2, 3, 5), COL_GEM_DARK)
		draw_rect(Rect2(p.x - 2, p.y - 1, 5, 3), COL_GEM_DARK)
		draw_rect(Rect2(p.x, p.y - 1, 1, 3), COL_GEM)
		draw_rect(Rect2(p.x - 1, p.y, 3, 1), COL_GEM)
		draw_rect(Rect2(p.x, p.y, 1, 1), Color.WHITE if int(d.age * 3.0) % 4 == 0 else Color("d6ffe6"))


func _draw_ball(b: Ball) -> void:
	var returning := b.state == Ball.State.RETURN
	var glow: Color = COL_GOLD if b.charged else (b.slot.glow_color if b.slot else Color(0.9, 0.9, 0.94))
	var n := b.trail.size()
	for i in n:
		var a := float(i + 1) / float(n + 1) * (0.12 if returning else (0.5 if b.slot else 0.22))
		var sz := 2.0 if (b.slot and i * 2 > n) else 1.0
		draw_rect(Rect2(b.trail[i].round() - Vector2(floorf(sz * 0.5), floorf(sz * 0.5)), Vector2(sz, sz)), Color(glow, a))
	var p := b.pos.round()
	if returning:
		draw_rect(Rect2(p - Vector2(1, 1), Vector2(2, 2)), Color(0.9, 0.9, 0.94, 0.35))
		return
	if b.slot == null:
		draw_rect(Rect2(p - Vector2(1, 1), Vector2(2, 2)), COL_GOLD if b.charged else Color("e6e6ee"))
	elif b.slot.fused:
		var f := float(int(run_time * 12.0) % 2)
		draw_rect(Rect2(p - Vector2(4 + f, 4 + f), Vector2(9 + 2 * f, 9 + 2 * f)), Color(glow, 0.35))
		draw_rect(Rect2(p - Vector2(3, 3), Vector2(7, 7)), Color(glow, 0.8))
		draw_rect(Rect2(p - Vector2(2, 2), Vector2(5, 5)), Color("fff3c4") if b.charged else b.slot.core_color)
	else:
		draw_rect(Rect2(p - Vector2(2, 2), Vector2(5, 5)), Color(glow, 0.6))
		draw_rect(Rect2(p - Vector2(1, 1), Vector2(3, 3)), Color("fff3c4") if b.charged else b.slot.core_color)
	if b.gems > 0:
		for i in mini(b.gems, 6):
			var a := run_time * 8.0 + float(i) * 1.05
			draw_rect(Rect2((p + Vector2(cos(a), sin(a)) * 4.0).round(), Vector2.ONE), COL_GEM)
	if b.prism:
		draw_rect(Rect2(p + Vector2(-1, -6), Vector2(3, 3)), PRISM_COLORS[int(run_time * 10.0) % PRISM_COLORS.size()])


func _draw_aim() -> void:
	var dir := _aim_dir()
	var probe := Ball.new()
	probe.pos = player + Vector2(0, -3) + dir * balance.launch_offset
	probe.vel = dir
	var bounces := 0
	var r := balance.ball_radius
	var size_y := float(balance.world_size.y)
	if _columns.size() != balance.grid_columns:
		_rebuild_columns()
	for i in 700:
		probe.pos += probe.vel * 2.0
		var hit := _walls(probe, r)
		if not hit and probe.pos.y < balance.rune_line_y:
			var col := _column_of(probe.pos.x)
			for ci in range(col - 1, col + 2):
				if ci < 0 or ci >= _columns.size():
					continue
				for e: Enemy in _columns[ci]:
					if e.alive and _collide_rect(probe, e.pos, e.size, r):
						hit = true
						break
				if hit:
					break
		if hit:
			draw_rect(Rect2(probe.pos.round() - Vector2.ONE, Vector2(3, 3)), Color(COL_PARCH, 0.8))
			bounces += 1
			if bounces > settings.aim_preview_bounces:
				break
		elif i % 3 == 0:
			draw_rect(Rect2(probe.pos.round(), Vector2.ONE), Color(COL_CYAN, 0.55 / (1.0 + float(bounces) * 1.2)))
		if probe.pos.y > size_y:
			break
	var c := (player + Vector2(0, -3) + dir * balance.crosshair_distance).round()
	var pulse := 4.0 + roundf(sin(run_time * 6.0) + 1.0)
	draw_arc(c + Vector2(0.5, 0.5), pulse, 0.0, TAU, 16, COL_PARCH, 1.0)
	draw_rect(Rect2(c.x, c.y - pulse - 3, 1, 2), COL_PARCH)
	draw_rect(Rect2(c.x, c.y + pulse + 1, 1, 2), COL_PARCH)
	draw_rect(Rect2(c.x - pulse - 3, c.y, 2, 1), COL_PARCH)
	draw_rect(Rect2(c.x + pulse + 1, c.y, 2, 1), COL_PARCH)
	draw_string(font, c + Vector2(-20, pulse + 10), str(roundi(aim_deg)), HORIZONTAL_ALIGNMENT_CENTER, 40.0, 8, Color(COL_PARCH, 0.55))


func _draw_player() -> void:
	var p := player.round()
	draw_rect(Rect2(p.x - 5, p.y + 6, 10, 2), Color(0, 0, 0, 0.4))
	if character and character.sprite_sheet:
		# Seen from behind (facing the Rift); feet on the shadow.
		draw_texture_rect_region(character.sprite_sheet, Rect2(p.x - 16.0, p.y - 23.0, 32.0, 32.0), SpriteKit.frame_rect(SpriteKit.Dir.NORTH))
		_draw_hand(p)
		return
	var hair := character.hair_color if character else Color("c7432c")
	var accent := character.accent_color if character else Color("E6BD73")
	draw_rect(Rect2(p.x - 5, p.y - 3, 10, 9), accent)
	draw_rect(Rect2(p.x - 4, p.y - 2, 8, 7), Color("24306a"))
	draw_rect(Rect2(p.x - 4, p.y + 5, 8, 1), accent)
	draw_rect(Rect2(p.x - 2, p.y - 7, 5, 5), Color("f1d3bd"))
	draw_rect(Rect2(p.x - 3, p.y - 9, 7, 3), hair)
	draw_rect(Rect2(p.x - 3, p.y - 7, 2, 6), hair)
	draw_rect(Rect2(p.x + 2, p.y - 7, 2, 4), hair)
	var dir := _aim_dir()
	var i := 3.0
	while i < 9.0:
		draw_rect(Rect2((p + Vector2(0, -2) + dir * i).round(), Vector2.ONE), Color("8a6a3a"))
		i += 2.0
	var tip := (p + Vector2(0, -2) + dir * 9.0).round()
	draw_rect(Rect2(tip - Vector2.ONE, Vector2(3, 3)), Color("ffb347") if int(run_time * 8.0) % 2 == 0 else Color("fff1a8"))
	_draw_hand(p)


## Balls waiting in hand, as dots under the student.
func _draw_hand(p: Vector2) -> void:
	var hand: Array[Ball] = []
	for b: Ball in balls:
		if b.state == Ball.State.HAND:
			hand.append(b)
	var n := mini(hand.size(), 14)
	var w := float(n * 3)
	for k in n:
		var b := hand[k]
		var col: Color = COL_GOLD if b.charged else (b.slot.glow_color if b.slot else Color("d8d8e0"))
		draw_rect(Rect2(p.x - floorf(w * 0.5) + float(k * 3), p.y + 10, 2, 2), col)
	if hand.size() > 14:
		draw_string(font, Vector2(p.x + w * 0.5 + 2.0, p.y + 14.0), "+%d" % (hand.size() - 14), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("d8d8e0"))


func _draw_zone_labels() -> void:
	if not settings.show_touches and run_time > 7.0:
		return
	var a := 0.7 if settings.show_touches else clampf((7.0 - run_time) / 2.0, 0.0, 0.7)
	var w := float(balance.world_size.x)
	draw_string(font, Vector2(0, balance.rune_line_y - 6.0), "^ AIM AREA ^", HORIZONTAL_ALIGNMENT_CENTER, w, 8, Color(COL_CYAN, a))
	draw_string(font, Vector2(0, balance.rune_line_y + 12.0), "v MOVE AREA v", HORIZONTAL_ALIGNMENT_CENTER, w, 8, Color(Color("E6BD73"), a))
	if settings.show_touches:
		var x := float(balance.wall_width)
		while x < w - float(balance.wall_width):
			draw_rect(Rect2(x, balance.rune_line_y - settings.zone_tolerance, 2, 1), Color(COL_CYAN, 0.5))
			x += 4.0
