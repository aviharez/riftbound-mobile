class_name DialoguePlayer
extends Control
## Full-screen dialogue scene: location and title, two big portraits (the speaker lit, the other dimmed),
## a text box with a typewriter effect, then a choice, its reply and the shared ending.
## Tap to finish the line / go on. Emits `finished(choice_index)` (-1 when there was no choice).
## Lives on the root UI layer (crisp text), never in the pixel SubViewport. See docs/relationship-spec.md.

signal finished(choice_index: int)

const CHARS_PER_SECOND := 60.0
const PORTRAIT_PX := 160.0
const BOX_H := 132.0

var _dialogue: DialogueData
var _queue: Array[String] = []
var _choice_index: int = -1
var _asked: bool = false
var _typing: bool = false
var _shown: float = 0.0

var _root: Control
var _left: Portrait
var _right: Portrait
var _name: Label
var _text: Label
var _hint: Label
var _choices: VBoxContainer


func _ready() -> void:
	theme = UiTheme.theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func is_open() -> bool:
	return _root != null


func play(d: DialogueData) -> void:
	close()
	_dialogue = d
	_choice_index = -1
	_asked = false
	_queue = d.lines.duplicate()
	_build()
	_next()


func close() -> void:
	if _root:
		_root.queue_free()
		_root = null


func _process(delta: float) -> void:
	if not _typing or _text == null:
		return
	_shown += delta * CHARS_PER_SECOND
	_text.visible_characters = int(_shown)
	if _shown >= float(_text.get_total_character_count()):
		_finish_typing()


# ================================================================= flow

func _next() -> void:
	if not _queue.is_empty():
		_say(_queue.pop_front())
		return
	if not _asked and not _dialogue.choices.is_empty():
		_ask()
		return
	var idx := _choice_index
	close()
	finished.emit(idx)


func _say(line: String) -> void:
	var who := DialogueData.speaker_of(line)
	var c := Registry.character(who) if who != &"narrator" else null
	_name.text = c.display_name.get_slice(" ", 0) if c else ""
	_name.add_theme_color_override("font_color", c.hair_color.lightened(0.35) if c else UiTheme.MUTED)
	_text.text = DialogueData.text_of(line)
	_text.add_theme_color_override("font_color", UiTheme.PARCH if c else Color(UiTheme.MUTED, 1.0).lightened(0.2))
	_left.dimmed = _left.character == null or _left.character.id != who
	_right.dimmed = _right.character == null or _right.character.id != who
	_left.position.y = _portrait_y() - (6.0 if not _left.dimmed else 0.0)
	_right.position.y = _portrait_y() - (6.0 if not _right.dimmed else 0.0)
	_text.visible_characters = 0
	_shown = 0.0
	_typing = true
	_hint.visible = false


func _finish_typing() -> void:
	_typing = false
	_text.visible_characters = -1
	_hint.visible = true


func _ask() -> void:
	_asked = true
	_name.text = "You"
	_name.add_theme_color_override("font_color", UiTheme.GOLD)
	_text.text = _dialogue.choice_prompt if _dialogue.choice_prompt != "" else "What do you say?"
	_text.visible_characters = -1
	_typing = false
	_hint.visible = false
	_left.dimmed = true
	_right.dimmed = true
	for i in _dialogue.choices.size():
		var ch: Dictionary = _dialogue.choices[i]
		var b := Button.new()
		b.text = str(ch.get("text", "..."))
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 8)
		b.custom_minimum_size = Vector2(0, 26)
		var index := i
		b.pressed.connect(func() -> void: _choose(index))
		_choices.add_child(b)
	_choices.visible = true


func _choose(i: int) -> void:
	_choice_index = i
	for c: Node in _choices.get_children():
		c.queue_free()
	_choices.visible = false
	var ch: Dictionary = _dialogue.choices[i]
	_queue.clear()
	for l: Variant in ch.get("reply", []):
		_queue.append(str(l))
	_queue.append_array(_dialogue.ending)
	_next()


func _skip() -> void:
	if _asked and _choice_index < 0:
		return  # the choice can't be skipped
	_queue.clear()
	if not _asked and not _dialogue.choices.is_empty():
		_ask()
	else:
		_next()


func _on_tap(ev: InputEvent) -> void:
	var tap := (ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT) \
		or (ev is InputEventScreenTouch and (ev as InputEventScreenTouch).pressed)
	if not tap or _choices.visible:
		return
	accept_event()
	if _typing:
		_finish_typing()
	else:
		_next()


# ================================================================= layout

## Big, but two must fit side by side with a margin on narrow screens.
func _portrait_px() -> float:
	return minf(PORTRAIT_PX, floorf((size.x - 24.0) * 0.5))


func _portrait_y() -> float:
	return size.y - BOX_H - _portrait_px() + 8.0


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.gui_input.connect(_on_tap)
	add_child(_root)

	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.04, 0.09, 0.97)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(bg)
	# A soft band of the scene's light behind the portraits.
	var band := ColorRect.new()
	band.color = Color(UiTheme.VIOLET, 0.08)
	band.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	band.offset_top = -BOX_H - _portrait_px() - 20.0
	band.offset_bottom = -BOX_H
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(band)

	var head := VBoxContainer.new()
	head.set_anchors_preset(Control.PRESET_TOP_WIDE)
	head.offset_left = 14.0
	head.offset_right = -14.0
	head.offset_top = 34.0
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(head)
	var loc := Label.new()
	loc.text = _dialogue.location
	loc.theme_type_variation = "Eyebrow"
	loc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	head.add_child(loc)
	var title := Label.new()
	title.text = _dialogue.title
	title.theme_type_variation = "Title"
	head.add_child(title)
	var bond := Registry.bond(_dialogue.bond_id)
	if bond:
		var sub := Label.new()
		sub.text = bond.display_name()
		sub.theme_type_variation = "Small"
		head.add_child(sub)

	var skip := Button.new()
	skip.text = "Skip"
	skip.add_theme_font_size_override("font_size", 8)
	skip.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	skip.offset_left = -50.0
	skip.offset_right = -8.0
	skip.offset_top = 8.0
	skip.offset_bottom = 26.0
	skip.pressed.connect(_skip)
	_root.add_child(skip)

	var cast := _dialogue.cast()
	_left = Portrait.make(Registry.character(cast[0]) if cast.size() > 0 else null, PORTRAIT_PX, false, false)
	_right = Portrait.make(Registry.character(cast[1]) if cast.size() > 1 else null, PORTRAIT_PX, false, false)
	_root.add_child(_left)
	_root.add_child(_right)
	_root.resized.connect(_place_portraits)
	_place_portraits.call_deferred()

	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.INK, Color(UiTheme.GOLD, 0.7), 1, 8))
	box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	box.offset_top = -BOX_H
	box.offset_left = 6.0
	box.offset_right = -6.0
	box.offset_bottom = -6.0
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(box)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(col)
	_name = Label.new()
	_name.theme_type_variation = "Heading"
	col.add_child(_name)
	_text = Label.new()
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.custom_minimum_size.x = 200.0
	col.add_child(_text)
	_choices = VBoxContainer.new()
	_choices.add_theme_constant_override("separation", 3)
	_choices.visible = false
	col.add_child(_choices)
	_hint = Label.new()
	_hint.text = "Tap to continue"
	_hint.theme_type_variation = "Tiny"
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.add_theme_color_override("font_color", UiTheme.MUTED)
	col.add_child(_hint)
	# Choices need more room than a line of text: grow the box upward while they are shown.
	_choices.visibility_changed.connect(func() -> void:
		box.offset_top = -BOX_H - (80.0 if _choices.visible else 0.0)
		_text.size_flags_vertical = Control.SIZE_SHRINK_BEGIN if _choices.visible else Control.SIZE_EXPAND_FILL)


func _place_portraits() -> void:
	if _left == null:
		return
	var w := size.x
	var px := _portrait_px()
	for p: Portrait in [_left, _right]:
		p.custom_minimum_size = Vector2(px, px)
		p.size = p.custom_minimum_size
		p.queue_redraw()
	_left.position = Vector2(w * 0.5 - px - 4.0, _portrait_y() - (6.0 if not _left.dimmed else 0.0))
	_right.position = Vector2(w * 0.5 + 4.0, _portrait_y() - (6.0 if not _right.dimmed else 0.0))
	_left.visible = _left.character != null
	_right.visible = _right.character != null
