class_name Portrait
extends Control
## Placeholder student portrait drawn in code: uniform, face and hair in the student's colors.
## The anime illustrations replace this later (art-spec). Used by the roster, profile, stories and dialogue.

var character: CharacterData
var locked: bool = false
## Dims the portrait (a student who isn't speaking in a dialogue).
var dimmed: bool = false:
	set(v):
		dimmed = v
		queue_redraw()
## Draws a frame and background tile (off for big dialogue portraits).
var framed: bool = true


static func make(c: CharacterData, px: float, is_locked: bool = false, with_frame: bool = true) -> Portrait:
	var p := Portrait.new()
	p.character = c
	p.locked = is_locked
	p.framed = with_frame
	p.custom_minimum_size = Vector2(px, px)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


func _draw() -> void:
	if character == null:
		return
	var s := custom_minimum_size
	var k := s.x / 36.0
	var element: ElementData = Registry.elements.get(character.element_id)
	var glow := element.glow_color if element else UiTheme.VIOLET
	if framed:
		draw_rect(Rect2(Vector2.ZERO, s), Color("0b0b16"))
		draw_rect(Rect2(Vector2(0, s.y * 0.55), Vector2(s.x, s.y * 0.45)), Color(glow, 0.18))
	if character.sprite_sheet:
		_draw_sprite(s, glow)
		return
	var hair := character.hair_color
	var skin := Color("f1d3bd")
	var uni := Color("24306a")
	var accent := character.accent_color
	if locked:
		hair = Color("2a2838")
		skin = hair
		uni = Color("1d1b28")
		accent = uni
	var shade := Color(0.35, 0.35, 0.45) if dimmed else Color.WHITE
	draw_rect(Rect2(Vector2(8, 26) * k, Vector2(20, 10) * k), uni * shade)
	draw_rect(Rect2(Vector2(16, 26) * k, Vector2(4, 4) * k), accent * shade)
	draw_rect(Rect2(Vector2(11, 10) * k, Vector2(14, 15) * k), skin * shade)
	draw_rect(Rect2(Vector2(9, 6) * k, Vector2(18, 6) * k), hair * shade)
	draw_rect(Rect2(Vector2(9, 10) * k, Vector2(4, 14) * k), hair * shade)
	draw_rect(Rect2(Vector2(23, 10) * k, Vector2(4, 9) * k), hair * shade)
	if locked:
		draw_string(UiTheme.pixel_font(), Vector2(0, s.y * 0.6), "?", HORIZONTAL_ALIGNMENT_CENTER, s.x, int(14 * k), UiTheme.MUTED)
	else:
		draw_rect(Rect2(Vector2(14, 16) * k, Vector2(2, 2) * k), Color("3a2a1e"))
		draw_rect(Rect2(Vector2(20, 16) * k, Vector2(2, 2) * k), Color("3a2a1e"))
	if framed:
		draw_rect(Rect2(Vector2.ZERO, s), Color(glow, 0.7) if not locked else UiTheme.LINE, false, 1.0)


## Generated sprite at a whole-number scale: framed portraits show the head, big ones the full body.
func _draw_sprite(s: Vector2, glow: Color) -> void:
	var tex := character.sprite_sheet
	var src: Rect2
	if framed:
		src = SpriteKit.head_rect(tex)
	else:
		src = SpriteKit.frame_rect(SpriteKit.Dir.SOUTH)
	var k := maxf(1.0, floorf(minf(s.x / src.size.x, s.y / src.size.y)))
	var dst_size := src.size * k
	var at := Vector2(floorf((s.x - dst_size.x) * 0.5), s.y - dst_size.y if not framed else floorf((s.y - dst_size.y) * 0.5))
	var tint := Color.WHITE
	if locked:
		tint = Color(0.12, 0.11, 0.17)
	elif dimmed:
		tint = Color(0.4, 0.4, 0.5)
	draw_texture_rect_region(tex, Rect2(at, dst_size), src, tint)
	if locked:
		draw_string(UiTheme.pixel_font(), Vector2(0, s.y * 0.62), "?", HORIZONTAL_ALIGNMENT_CENTER, s.x, int(maxf(8.0, s.x * 0.4)), UiTheme.MUTED)
	if framed:
		draw_rect(Rect2(Vector2.ZERO, s), Color(glow, 0.7) if not locked else UiTheme.LINE, false, 1.0)
