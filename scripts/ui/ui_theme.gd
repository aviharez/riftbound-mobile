class_name UiTheme
extends RefCounted
## Fonts, colors and the Theme used by every UI-layer screen. Sizes are in base units (270-wide);
## the UI layer renders at native resolution, so text stays sharp at any integer scale.

const INK := Color("17172A")
const INK_2 := Color("21213a")
const INK_3 := Color("11111f")
const VIOLET := Color("6F4AE6")
const VIOLET_LIGHT := Color("8b6cf0")
const CYAN := Color("69D8E8")
const GOLD := Color("E6BD73")
const PARCH := Color("F3EBDD")
const MUTED := Color("a29db8")
const LINE := Color("3b3654")
const GEM := Color("7fe0a8")

static var _pixel_font: FontFile
static var _body_font: FontFile
static var _theme: Theme


## Silkscreen, rendered without antialiasing: HUD numbers, labels, titles, world text.
static func pixel_font() -> FontFile:
	if _pixel_font == null:
		_pixel_font = load("res://assets/fonts/silkscreen_regular.ttf") as FontFile
		_pixel_font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		_pixel_font.hinting = TextServer.HINTING_NONE
		_pixel_font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	return _pixel_font


## Pixelify Sans: readable body text in panels.
static func body_font() -> FontFile:
	if _body_font == null:
		_body_font = load("res://assets/fonts/pixelify_sans.ttf") as FontFile
	return _body_font


static func theme() -> Theme:
	if _theme:
		return _theme
	var t := Theme.new()
	t.default_font = body_font()
	t.default_font_size = 9

	t.set_color("font_color", "Label", PARCH)

	t.add_type("Title")
	t.set_type_variation("Title", "Label")
	t.set_font("font", "Title", pixel_font())
	t.set_font_size("font_size", "Title", 12)
	t.set_color("font_color", "Title", GOLD)

	t.add_type("Eyebrow")
	t.set_type_variation("Eyebrow", "Label")
	t.set_font("font", "Eyebrow", pixel_font())
	t.set_font_size("font_size", "Eyebrow", 8)
	t.set_color("font_color", "Eyebrow", CYAN)

	t.add_type("Heading")
	t.set_type_variation("Heading", "Label")
	t.set_font("font", "Heading", pixel_font())
	t.set_font_size("font_size", "Heading", 8)
	t.set_color("font_color", "Heading", MUTED)

	t.add_type("Small")
	t.set_type_variation("Small", "Label")
	t.set_font_size("font_size", "Small", 7)
	t.set_color("font_color", "Small", MUTED)

	t.add_type("CardTitle")
	t.set_type_variation("CardTitle", "Label")
	t.set_font("font", "CardTitle", pixel_font())
	t.set_font_size("font_size", "CardTitle", 8)
	t.set_color("font_color", "CardTitle", GOLD)

	t.add_type("Tiny")
	t.set_type_variation("Tiny", "Label")
	t.set_font_size("font_size", "Tiny", 6)

	t.set_stylebox("panel", "PanelContainer", box(INK, GOLD, 1, 8))

	for state: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		var bg := INK_2
		var border := LINE
		match state:
			"hover": border = CYAN
			"pressed": bg = Color("2b2b4a")
			"disabled": bg = Color(INK_2, 0.5)
			"focus":
				t.set_stylebox("focus", "Button", box(Color(0, 0, 0, 0), CYAN, 1, 4))
				continue
		t.set_stylebox(state, "Button", box(bg, border, 1, 4))
	t.set_color("font_color", "Button", PARCH)
	t.set_color("font_hover_color", "Button", PARCH)
	t.set_color("font_pressed_color", "Button", PARCH)
	t.set_color("font_disabled_color", "Button", MUTED)
	t.set_font_size("font_size", "Button", 9)

	t.add_type("Primary")
	t.set_type_variation("Primary", "Button")
	t.set_stylebox("normal", "Primary", box(VIOLET, VIOLET_LIGHT, 1, 6))
	t.set_stylebox("hover", "Primary", box(VIOLET_LIGHT, PARCH, 1, 6))
	t.set_stylebox("pressed", "Primary", box(Color("5a3bc4"), VIOLET_LIGHT, 1, 6))
	t.set_font("font", "Primary", pixel_font())
	t.set_font_size("font_size", "Primary", 8)

	t.set_font_size("font_size", "CheckBox", 8)
	t.set_color("font_color", "CheckBox", PARCH)
	t.set_font_size("font_size", "OptionButton", 8)
	_theme = t
	return t


static func box(bg: Color, border: Color, border_w: int, margin: float) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(border_w)
	s.set_content_margin_all(margin)
	s.anti_aliasing = false
	return s
