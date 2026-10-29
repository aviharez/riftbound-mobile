extends Node
## Plays through every screen and saves a screenshot of each (run-and-observe evidence).
## Run via tools/capture_flow.sh (sets the window size; loaded at runtime by tools/run_runner.gd). Not part of the game.
## Battle screens: play, level up, fusion, after fusion, pause, ultimate, many balls, result.

var main: BattleScreen
var out_dir := "docs/qa/evidence"
var prefix := "flow"
var t := 0.0
var wait := 0.0
var phase := 0


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out_dir = arg.trim_prefix("--out=")
		elif arg.begins_with("--prefix="):
			prefix = arg.trim_prefix("--prefix=")
	main = get_tree().current_scene as BattleScreen
	prefix += "-battle"


func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := "%s/%s-%s-%dx%d.png" % [out_dir, prefix, name, img.get_width(), img.get_height()]
	img.save_png(path if path.begins_with("/") else ProjectSettings.globalize_path("res://" + path))
	print("SHOT ", path)


func _process(delta: float) -> void:
	if main == null or main.battle == null or main.battle.loadout == null:
		return
	t += delta
	if wait > 0.0:
		wait -= delta
		return
	var b := main.battle
	match phase:
		0:
			if t > 0.5:
				main._touch_down(0, Vector2(70, 250)); main._touches.erase(0)
				phase = 2; t = 0.0
		2:
			if t > 3.0:
				shot("02-play"); b.speed = 3; phase = 3; t = 0.0
		3:
			match main.state:
				BattleScreen.State.PLAYING:
					b.aim_at(Vector2(135.0 + sin(t * 0.7) * 120.0, 200.0))
					b.player.x = 135.0 + sin(t * 0.4) * 90.0
				BattleScreen.State.LEVEL_UP:
					shot("03-level-up"); wait = 0.3; phase = 4
		4:
			main._on_card_chosen(_prefer(b.offer_cards(), [LevelCard.NEW_BALL]))
			for i in 12:
				b.debug_add_level()
			phase = 5
		5:
			match main.state:
				BattleScreen.State.LEVEL_UP: main._on_card_chosen(_prefer(b.offer_cards(), [LevelCard.NEW_BALL, LevelCard.NEW_ITEM]))
				BattleScreen.State.FUSION: main._on_fusion_kept()
				BattleScreen.State.PLAYING:
					if b.pending_levels == 0:
						b.debug_max_balls(); b.debug_add_prism(); phase = 6
		6:
			if main.state == BattleScreen.State.FUSION:
				shot("04-fusion"); wait = 0.3; phase = 7
		7:
			main._on_fusion_chosen(b.fusion_pairs()[0]); phase = 8; t = 0.0
		8:
			_autoplay()
			if t > 1.5:
				shot("05-after-fusion"); wait = 0.2; phase = 9
		9:
			main._pause(); wait = 0.3; phase = 10
		10:
			shot("06-pause"); wait = 0.2; phase = 11
		11:
			main._resume(); b.debug_add_baby_balls(36); b.speed = 1; b.energy = _balance().energy_max; phase = 12; t = 0.0
		12:
			_autoplay()
			if t > 2.0 and b.energy >= _balance().energy_max:
				b.cast_ultimate(); phase = 13; t = 0.0
		13:
			_autoplay()
			if t > 0.25:
				shot("07-ultimate"); phase = 14; t = 0.0
		14:
			_autoplay()
			if t > 2.5:
				shot("08-many-balls"); wait = 0.3; phase = 15
		15:
			b._damage_player(999); phase = 16; t = 0.0
		16:
			if t > 1.0:
				shot("09-result"); wait = 0.3; phase = 17
		17:
			get_tree().quit(0)
	return


func _autoplay() -> void:
	var b := main.battle
	match main.state:
		BattleScreen.State.PLAYING: b.aim_at(Vector2(135.0 + sin(t) * 100.0, 150.0))
		BattleScreen.State.FUSION: main._on_fusion_kept()
		BattleScreen.State.LEVEL_UP: main._on_card_chosen(b.offer_cards()[0])


func _prefer(cards: Array[LevelCard], kinds: Array[StringName]) -> LevelCard:
	for c: LevelCard in cards:
		if kinds.has(c.kind):
			return c
	return cards[0]


func _balance() -> CombatBalance:
	return Registry.balance
