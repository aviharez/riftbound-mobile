class_name TitleScreen
extends Control
## Title screen (placeholder art): Continue / New game / How to play. Entry point of the game.

var _modal: ModalLayer
var _confirm_new: bool = false
var _new_button: Button
var _time: float = 0.0


func _ready() -> void:
	theme = UiTheme.theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	col.anchor_top = 0.55
	col.anchor_bottom = 0.95
	col.anchor_left = 0.5
	col.anchor_right = 0.5
	col.offset_left = -110.0
	col.offset_right = 110.0
	col.add_theme_constant_override("separation", 8)
	add_child(col)

	var title := Label.new()
	title.text = "RIFTBOUND"
	title.theme_type_variation = "Title"
	title.add_theme_font_size_override("font_size", 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	var sub := Label.new()
	sub.text = "ARCANE ACADEMY"
	sub.theme_type_variation = "Eyebrow"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(sub)
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 10.0
	col.add_child(spacer)

	if GameState.has_save() and GameState.runs > 0:
		col.add_child(_button("Continue", "Primary", func() -> void: GameState.go_to(GameState.SCENE_ACADEMY)))
		_new_button = _button("New game", "", _on_new_game)
	else:
		_new_button = _button("Start", "Primary", _on_new_game)
	col.add_child(_new_button)
	col.add_child(_button("How to play", "", _show_how_to))
	var stats := Label.new()
	stats.theme_type_variation = "Small"
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if GameState.runs > 0:
		stats.text = "Runs %d · Best wave %d · Bosses %d" % [GameState.runs, GameState.best_wave, GameState.bosses_defeated]
	col.add_child(stats)
	var ver := Label.new()
	ver.theme_type_variation = "Small"
	ver.text = "Prototype · placeholder art"
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(ver)

	_modal = ModalLayer.new()
	add_child(_modal)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var s := size
	draw_rect(Rect2(Vector2.ZERO, s), UiTheme.INK)
	# Rift glow
	var c := Vector2(s.x * 0.5, s.y * 0.28)
	for i in 6:
		var r := 120.0 - float(i) * 18.0 + sin(_time * 1.2 + float(i)) * 3.0
		draw_circle(c, r, Color(UiTheme.VIOLET, 0.05 + 0.03 * float(i)))
	draw_circle(c, 18.0, Color(0.85, 0.8, 1.0, 0.5))
	# Academy silhouette
	var base_y := s.y * 0.5
	var sil := Color("0b0b16")
	draw_rect(Rect2(0, base_y, s.x, s.y - base_y), sil)
	var towers: Array[Vector3] = [Vector3(0.12, 60, 18), Vector3(0.3, 90, 22), Vector3(0.5, 130, 30), Vector3(0.7, 95, 22), Vector3(0.88, 70, 18)]
	for t: Vector3 in towers:
		var x := s.x * t.x
		draw_rect(Rect2(x - t.z * 0.5, base_y - t.y, t.z, t.y), sil)
		draw_colored_polygon(PackedVector2Array([Vector2(x - t.z * 0.7, base_y - t.y), Vector2(x, base_y - t.y - t.z * 1.2), Vector2(x + t.z * 0.7, base_y - t.y)]), sil)
		if int(_time * 2.0 + t.x * 10.0) % 3 != 0:
			draw_rect(Rect2(x - 2, base_y - t.y * 0.6, 4, 5), Color(UiTheme.RELIC, 0.6))
	# Drifting motes
	for i in 24:
		var px := fmod(float(i) * 37.0 + _time * (6.0 + float(i % 5)), s.x)
		var py := fmod(float(i) * 53.0 - _time * (10.0 + float(i % 7)), s.y * 0.5)
		if py < 0.0:
			py += s.y * 0.5
		draw_rect(Rect2(px, py, 1, 1), Color(0.8, 0.75, 1.0, 0.5))


func _button(text: String, variation: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	if variation != "":
		b.theme_type_variation = variation
	b.custom_minimum_size.y = 24.0
	b.pressed.connect(on_press)
	return b


func _on_new_game() -> void:
	if GameState.runs > 0 and not _confirm_new:
		_confirm_new = true
		_new_button.text = "Tap again: erase progress"
		return
	GameState.new_game()
	GameState.academy_spawn = Vector2.INF
	GameState.go_to(GameState.SCENE_ACADEMY)


func _show_how_to() -> void:
	var box := _modal._open()
	box.add_child(_modal._label("How to play", "Title"))
	for line: String in [
		"Walk around the Academy: tap the ground to move, tap a building to use it.",
		"Enter the Rift Gate to fight. Drag below the rune line to move; touch the arena to aim. The angle stays locked.",
		"Balls fire on their own and come back. Catch a falling ball for a Perfect Catch.",
		"Balls absorb green gems (XP) and rainbow Rift Prisms on their way and deliver them when they return.",
		"Level up to fill 4 ball slots and 4 item slots. Two Lv3 balls + a prism fuse into one.",
		"Runs pay Mana Shards, Ruins Materials and Ancient Relics. Spend them to repair and upgrade buildings: each one makes your next runs stronger.",
	]:
		box.add_child(_modal._label("• " + line, "", true))
	box.add_child(_modal._button("Close", "Primary", func() -> void: _modal.close()))
