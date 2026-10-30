class_name AcademyHud
extends Control
## Academy UI layer (reference: academy hub mockups): portrait ring with academy restoration, resource pills,
## the current quest tracker, the "Open <building>" prompt and the icon navigation bar with red badges.
## Drawn in code on the native-resolution UI layer; invisible flat buttons take the taps.
## Emits signals; AcademyScreen decides what they do.

signal nav_pressed(tab: StringName)
signal prompt_pressed(building_id: StringName)

const TOP_H := 30.0
const NAV_H := 40.0
const QUEST_RECT := Rect2(4, 32, 158, 17)
const TABS: Array[Array] = [[&"academy", "Academy"], [&"rift", "Battle"], [&"characters", "Students"], [&"expeditions", "Expeditions"], [&"stories", "Journal"]]

var _prompt: Button
var _prompt_id: StringName = &""
var _quest_button: Button
var _nav_buttons: Array[Button] = []
var _badge_timer: float = 0.0
var _badges: Dictionary = {}
var _quest_text: String = ""
var _quest_progress: String = ""
var _active_tab: StringName = &"academy"
var _panel: OrnateBox
var _pill: OrnateBox
var _nav_box: OrnateBox


func _ready() -> void:
	theme = UiTheme.theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel = OrnateBox.make(OrnateBox.Kind.CARD, 0.0)
	_panel.studs = false
	_pill = OrnateBox.make(OrnateBox.Kind.CHIP, 0.0)
	_pill.border = Color(UiTheme.GOLD, 0.55)
	_nav_box = OrnateBox.make(OrnateBox.Kind.PANEL, 0.0)

	_prompt = Button.new()
	_prompt.theme_type_variation = "Primary"
	_prompt.custom_minimum_size = Vector2(160, 22)
	_prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.offset_top = -NAV_H - 34.0
	_prompt.offset_bottom = -NAV_H - 12.0
	_prompt.offset_left = -80.0
	_prompt.offset_right = 80.0
	_prompt.visible = false
	_prompt.pressed.connect(func() -> void: prompt_pressed.emit(_prompt_id))
	add_child(_prompt)

	_quest_button = _flat_button()
	_quest_button.position = QUEST_RECT.position
	_quest_button.size = QUEST_RECT.size
	_quest_button.pressed.connect(func() -> void: nav_pressed.emit(&"stories"))
	add_child(_quest_button)

	for tab: Array in TABS:
		var b := _flat_button()
		var id: StringName = tab[0]
		b.pressed.connect(func() -> void:
			if id != &"rift":
				_active_tab = id
			nav_pressed.emit(id)
			queue_redraw())
		add_child(b)
		_nav_buttons.append(b)

	GameState.resources_changed.connect(refresh)
	resized.connect(_layout)
	_layout()
	refresh()


func _flat_button() -> Button:
	var b := Button.new()
	for st: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	b.focus_mode = Control.FOCUS_NONE
	return b


func _layout() -> void:
	var w := size.x / float(TABS.size())
	for i in _nav_buttons.size():
		_nav_buttons[i].position = Vector2(w * float(i), size.y - NAV_H)
		_nav_buttons[i].size = Vector2(w, NAV_H)


## Called when resources change; also refreshes the quest tracker.
func refresh() -> void:
	_quest_text = ""
	_quest_progress = ""
	for q: QuestData in Registry.quests:
		if GameState.quests_claimed.has(q.id):
			continue
		_quest_text = q.title
		_quest_progress = "Claim reward" if GameState.quest_complete(q) else "%s (%d/%d)" % [q.description.trim_suffix("."), mini(GameState.quest_value(q), q.target), q.target]
		break
	_quest_button.visible = _quest_text != ""
	queue_redraw()


## Shows "Enter <building>" above the nav bar while the avatar stands at a door.
func set_prompt(building_id: StringName) -> void:
	if building_id == _prompt_id:
		return
	_prompt_id = building_id
	if building_id == &"":
		_prompt.visible = false
		return
	var b: BuildingData = Registry.buildings[building_id]
	_prompt.text = ("Enter the Rift" if b.is_rift_gate else "Open %s" % b.display_name)
	_prompt.visible = true


## True when a screen position lands on the HUD (taps there must not move the avatar).
func covers(screen_pos: Vector2) -> bool:
	if screen_pos.y <= TOP_H or screen_pos.y >= size.y - NAV_H:
		return true
	if _quest_button.visible and QUEST_RECT.has_point(screen_pos):
		return true
	return _prompt.visible and _prompt.get_global_rect().has_point(screen_pos)


func _process(delta: float) -> void:
	_badge_timer -= delta
	if _badge_timer > 0.0:
		return
	_badge_timer = 1.0
	var affordable := false
	for id: StringName in Registry.buildings:
		affordable = affordable or GameState.can_upgrade(id)
	var students := false
	for c: CharacterData in Registry.characters:
		students = students or (GameState.is_student_unlocked(c.id) and GameState.can_upgrade_student(c.id))
	_badges = {
		&"academy": affordable,
		&"characters": students,
		&"expeditions": GameState.ready_expedition_count() > 0,
		&"stories": GameState.available_scene_count() + GameState.claimable_quest_count() > 0,
	}
	refresh()


func _draw() -> void:
	_draw_top()
	if _quest_text != "":
		_draw_quest()
	_draw_nav()


func _draw_top() -> void:
	var ci := get_canvas_item()
	draw_rect(Rect2(0, 0, size.x, TOP_H), Color(0.04, 0.035, 0.09, 0.8))
	# Portrait ring with the selected student's head.
	var pc := Vector2(15, 15)
	var student := GameState.current_student()
	draw_circle(pc, 12.5, Color("0b0a16"))
	if student and student.sprite_sheet:
		draw_texture_rect_region(student.sprite_sheet, Rect2(pc - Vector2(9, 9), Vector2(18, 18)), SpriteKit.head_rect(student.sprite_sheet))
	draw_arc(pc, 12.5, 0.0, TAU, 40, UiTheme.GOLD, 1.5, true)
	draw_arc(pc, 14.3, 0.0, TAU, 40, Color(UiTheme.GOLD, 0.35), 1.0, true)
	# Academy panel: name and restoration.
	var pr := Rect2(28, 4, 74, 22)
	_panel.draw(ci, pr)
	var font := UiTheme.display_font()
	draw_string(font, Vector2(33, 13), "Astralis Academy", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, UiTheme.GOLD)
	var lv := 0
	var mx := 0
	for id: StringName in Registry.buildings:
		lv += GameState.building_level(id)
		mx += Registry.buildings[id].max_level
	var frac := float(lv) / float(maxi(1, mx))
	draw_rect(Rect2(33, 17, 50, 4), Color("0c1a2a"))
	draw_rect(Rect2(33, 17, roundf(50.0 * frac), 4), Color("4fb4ff"))
	draw_string(UiTheme.body_font(), Vector2(85, 22), "%d%%" % roundi(frac * 100.0), HORIZONTAL_ALIGNMENT_LEFT, -1, 6, UiTheme.PARCH)
	# Resource pills, right-aligned.
	var colors := UiTheme.resource_colors()
	var amounts := GameState.resources()
	var pw := 50.0
	var x := size.x - 4.0 - pw * 3.0 - 6.0
	for i in 3:
		var r := Rect2(x + float(i) * (pw + 3.0), 7, pw, 16)
		_pill.draw(ci, r)
		_res_icon(i, r.position + Vector2(8, 8), colors[i])
		draw_string(UiTheme.body_font(), Vector2(r.position.x + 15, r.position.y + 11.5), _short(amounts[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 7, UiTheme.PARCH)


func _res_icon(i: int, c: Vector2, _col: Color) -> void:
	Icons.resource(self, i, c)


static func _short(n: int) -> String:
	if n >= 10000:
		return "%.1fk" % (float(n) / 1000.0)
	return str(n)


func _draw_quest() -> void:
	var r := QUEST_RECT
	_pill.draw(get_canvas_item(), r)
	var ready := _quest_progress == "Claim reward"
	var c := r.position + Vector2(8, r.size.y * 0.5)
	draw_circle(c, 5.0, Color("e0485a") if ready else Color(UiTheme.GOLD, 0.9))
	draw_rect(Rect2(c.x - 0.5, c.y - 3.0, 1.0, 3.6), Color("1a1020"))
	draw_rect(Rect2(c.x - 0.5, c.y + 1.6, 1.0, 1.0), Color("1a1020"))
	draw_string(UiTheme.display_font(), Vector2(r.position.x + 16, r.position.y + 7.5), _quest_text, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 24.0, 6, UiTheme.PARCH)
	draw_string(UiTheme.body_font(), Vector2(r.position.x + 16, r.position.y + 14.5), "· " + _quest_progress, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 24.0, 5, UiTheme.GEM if ready else UiTheme.MUTED)
	# Chevron.
	var e := Vector2(r.end.x - 6.0, r.position.y + r.size.y * 0.5)
	draw_polyline(PackedVector2Array([e + Vector2(-2, -3), e, e + Vector2(-2, 3)]), UiTheme.GOLD, 1.0, true)


func _draw_nav() -> void:
	var ci := get_canvas_item()
	var nav := Rect2(1, size.y - NAV_H + 1.0, size.x - 2.0, NAV_H - 2.0)
	_nav_box.draw(ci, nav)
	var w := size.x / float(TABS.size())
	for i in TABS.size():
		var id: StringName = TABS[i][0]
		var c := Vector2(w * (float(i) + 0.5), size.y - NAV_H * 0.5 - 4.0)
		var active := id == _active_tab
		if active:
			var cell := Rect2(w * float(i) + 3.0, size.y - NAV_H + 4.0, w - 6.0, NAV_H - 8.0)
			draw_rect(cell, Color(UiTheme.VIOLET, 0.28))
			draw_rect(cell, Color(UiTheme.VIOLET_LIGHT, 0.8), false, 1.0)
			OrnateBox._diamond(ci, Vector2(c.x, size.y - NAV_H + 3.0), 3.0, UiTheme.CYAN)
		elif i > 0:
			draw_line(Vector2(w * float(i), size.y - NAV_H + 8.0), Vector2(w * float(i), size.y - 8.0), Color(UiTheme.GOLD, 0.2), 1.0)
		var col := Color("efe4ff") if active else Color("b9b0d0")
		Icons.draw(self, id, c, 13.0, col)
		draw_string(UiTheme.display_font(), Vector2(w * float(i), size.y - 6.0), TABS[i][1], HORIZONTAL_ALIGNMENT_CENTER, w, 6, col)
		if _badges.get(id, false):
			Icons.badge(self, c + Vector2(9, -7))
