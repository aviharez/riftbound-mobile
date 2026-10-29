extends Node
## Headless invariant test for the ball simulation (combat-spec §3). Run via tools/stress.sh (loaded at runtime by tools/run_runner.gd).
## Plays the real main scene at x3 speed with 60+ extra balls for N frames, auto-picking level-up cards,
## and counts violations: a flying ball inside a wall or an enemy, a near-horizontal ball, or NaN.
## Exit 0 = no violations, 1 = violations found.

const FRAMES := 3600

var main: BattleScreen
var frames := 0
var checks := 0
var inside_wall := 0
var inside_enemy := 0
var flat := 0
var nan := 0


func _ready() -> void:
	main = get_tree().current_scene as BattleScreen


func _process(_delta: float) -> void:
	if main == null or main.battle == null or main.battle.loadout == null:
		return
	var b := main.battle
	var bal := _balance()
	if frames == 0:
		_restart()
	frames += 1
	b.aim_at(Vector2(135.0 + sin(frames * 0.05) * 120.0, 100.0 + cos(frames * 0.03) * 80.0))
	match main.state:
		BattleScreen.State.LEVEL_UP: main._on_card_chosen(b.offer_cards()[0])
		BattleScreen.State.FUSION: main._on_fusion_chosen(b.fusion_pairs()[0])
		BattleScreen.State.OVER: _restart()
	for ball: Ball in b.balls:
		if ball.state != Ball.State.FLY:
			continue
		checks += 1
		var p := ball.pos
		if is_nan(p.x) or is_nan(p.y):
			nan += 1
		if p.x < bal.wall_width + bal.ball_radius - 0.01 or p.x > bal.world_size.x - bal.wall_width - bal.ball_radius + 0.01 or p.y < bal.ceiling_y + bal.ball_radius - 0.01:
			inside_wall += 1
		for e: Enemy in b.enemies:
			if e.alive and e.rect().grow(-0.5).has_point(p):
				inside_enemy += 1
		if absf(ball.vel.y) < ball.vel.length() * (bal.min_vertical_ratio - 0.01):
			flat += 1
	if frames >= FRAMES:
		var bad := inside_wall + inside_enemy + flat + nan
		print("STRESS frames=%d ball_checks=%d inside_wall=%d inside_enemy=%d near_horizontal=%d nan=%d kills=%d wave=%d -> %s" % [
			frames, checks, inside_wall, inside_enemy, flat, nan, b.kills, b.wave, "PASS" if bad == 0 else "FAIL"])
		get_tree().quit(0 if bad == 0 else 1)
	return


func _restart() -> void:
	main._start_run()
	main.battle.debug_add_baby_balls(60)
	main.battle.speed = 3


func _balance() -> CombatBalance:
	return Registry.balance
