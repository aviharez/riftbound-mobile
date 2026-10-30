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
const SHARD := Color("a98bff")      # Mana Shards
const MATERIAL := Color("b0a493")   # Ruins Materials
const RELIC := Color("E6BD73")      # Ancient Relics
const DANGER := Color("ff6b6b")
const RESOURCE_NAMES: Array[String] = ["Mana Shards", "Ruins Materials", "Ancient Relics"]


static func resource_colors() -> Array[Color]:
	return [SHARD, MATERIAL, RELIC]

static var _pixel_font: FontFile
static var _body_font: FontFile
static var _display_font: FontVariation
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


## Cinzel Bold: gothic serif capitals for titles, headings and buttons (short text only).
static func display_font() -> FontVariation:
	if _display_font == null:
		var base := load("res://assets/fonts/Cinzel.ttf") as FontFile
		_display_font = FontVariation.new()
		_display_font.base_font = base
		_display_font.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 700}
	return _display_font


static func theme() -> Theme:
	if _theme:
		return _theme
	var t := Theme.new()
	t.default_font = body_font()
	t.default_font_size = 9

	t.set_color("font_color", "Label", PARCH)

	t.add_type("Title")
	t.set_type_variation("Title", "Label")
	t.set_font("font", "Title", display_font())
	t.set_font_size("font_size", "Title", 13)
	t.set_color("font_color", "Title", GOLD)
	t.set_color("font_shadow_color", "Title", Color(0, 0, 0, 0.6))
	t.set_constant("shadow_offset_y", "Title", 1)

	t.add_type("Eyebrow")
	t.set_type_variation("Eyebrow", "Label")
	t.set_font("font", "Eyebrow", display_font())
	t.set_font_size("font_size", "Eyebrow", 7)
	t.set_color("font_color", "Eyebrow", CYAN)

	t.add_type("Heading")
	t.set_type_variation("Heading", "Label")
	t.set_font("font", "Heading", display_font())
	t.set_font_size("font_size", "Heading", 8)
	t.set_color("font_color", "Heading", Color("e8dcc4"))

	t.add_type("Small")
	t.set_type_variation("Small", "Label")
	t.set_font_size("font_size", "Small", 7)
	t.set_color("font_color", "Small", MUTED)

	t.add_type("CardTitle")
	t.set_type_variation("CardTitle", "Label")
	t.set_font("font", "CardTitle", display_font())
	t.set_font_size("font_size", "CardTitle", 8)
	t.set_color("font_color", "CardTitle", GOLD)

	t.add_type("Tiny")
	t.set_type_variation("Tiny", "Label")
	t.set_font_size("font_size", "Tiny", 6)

	t.set_stylebox("panel", "PanelContainer", OrnateBox.make(OrnateBox.Kind.PANEL, 12.0))

	var btn := OrnateBox.make(OrnateBox.Kind.BUTTON, 4.0)
	t.set_stylebox("normal", "Button", btn)
	t.set_stylebox("hover", "Button", btn.tinted(CYAN))
	var btn_down := btn.tinted(GOLD)
	btn_down.top = Color("151429")
	btn_down.bottom = Color("201e3d")
	t.set_stylebox("pressed", "Button", btn_down)
	var btn_off := btn.tinted(Color(GOLD, 0.25))
	btn_off.top = Color("1a1930")
	btn_off.bottom = Color("131225")
	t.set_stylebox("disabled", "Button", btn_off)
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_font("font", "Button", display_font())
	t.set_color("font_color", "Button", PARCH)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", GOLD)
	t.set_color("font_disabled_color", "Button", Color(MUTED, 0.7))
	t.set_font_size("font_size", "Button", 8)

	t.add_type("Primary")
	t.set_type_variation("Primary", "Button")
	var prim := OrnateBox.make(OrnateBox.Kind.BUTTON_PRIMARY, 5.0)
	t.set_stylebox("normal", "Primary", prim)
	t.set_stylebox("hover", "Primary", prim.tinted(Color("ffe3a3"), Color(VIOLET_LIGHT, 0.9)))
	var prim_down := prim.tinted(GOLD)
	prim_down.top = Color("4b2db8")
	prim_down.bottom = Color("7a52ea")
	t.set_stylebox("pressed", "Primary", prim_down)
	var prim_off := prim.tinted(Color(GOLD, 0.3))
	prim_off.top = Color("3a3060")
	prim_off.bottom = Color("2a2448")
	t.set_stylebox("disabled", "Primary", prim_off)
	t.set_font("font", "Primary", display_font())
	t.set_font_size("font_size", "Primary", 9)
	t.set_color("font_shadow_color", "Primary", Color(0.1, 0.0, 0.25, 0.8))
	t.set_constant("shadow_offset_y", "Primary", 1)

	# Sliders and toggles in Arcane Cyan.
	var track := StyleBoxFlat.new()
	track.bg_color = Color("0d0c1a")
	track.border_color = Color(GOLD, 0.45)
	track.set_border_width_all(1)
	track.content_margin_top = 2.0
	track.content_margin_bottom = 2.0
	t.set_stylebox("slider", "HSlider", track)
	var fill := StyleBoxFlat.new()
	fill.bg_color = CYAN
	fill.content_margin_top = 2.0
	fill.content_margin_bottom = 2.0
	t.set_stylebox("grabber_area", "HSlider", fill)
	t.set_stylebox("grabber_area_highlight", "HSlider", fill)

	t.set_font_size("font_size", "CheckBox", 8)
	t.set_color("font_color", "CheckBox", PARCH)
	t.set_color("font_hover_color", "CheckBox", Color.WHITE)
	t.set_color("font_pressed_color", "CheckBox", PARCH)
	t.set_stylebox("normal", "CheckBox", StyleBoxEmpty.new())
	t.set_stylebox("hover", "CheckBox", StyleBoxEmpty.new())
	t.set_stylebox("pressed", "CheckBox", StyleBoxEmpty.new())
	t.set_stylebox("hover_pressed", "CheckBox", StyleBoxEmpty.new())
	t.set_stylebox("focus", "CheckBox", StyleBoxEmpty.new())
	t.set_icon("checked", "CheckBox", toggle_icon(true))
	t.set_icon("unchecked", "CheckBox", toggle_icon(false))
	t.set_font_size("font_size", "OptionButton", 8)
	t.set_font("font", "OptionButton", body_font())
	_theme = t
	return t


## A framed box for cards, chips and rows (an OrnateBox without studs). `border_w` 0 = no outline.
## A cyan border (hover/active) also gets a soft cyan glow.
static func box(bg: Color, border: Color, border_w: int, margin: float) -> StyleBox:
	var s := OrnateBox.make(OrnateBox.Kind.CARD if margin >= 5.0 else OrnateBox.Kind.CHIP, margin)
	s.studs = false
	s.top = bg.lightened(0.07)
	s.bottom = bg.darkened(0.25)
	s.top.a = bg.a
	s.bottom.a = bg.a
	s.border = border if border_w > 0 else Color(0, 0, 0, 0)
	s.inner = Color(border, 0.18) if border_w > 0 and margin >= 5.0 else Color(0, 0, 0, 0)
	if border == CYAN:
		s.glow = Color(CYAN, 0.7)
	return s


## Big card with corner studs (level-up choices, rewards). `selected` adds the cyan glow from the reference.
static func card(selected: bool = false, accent: Color = GOLD) -> OrnateBox:
	var s := OrnateBox.make(OrnateBox.Kind.CARD, 7.0)
	s.border = CYAN if selected else Color(accent, 0.75)
	if selected:
		s.glow = Color(CYAN, 0.9)
	return s


static var _toggles: Dictionary = {}


## A pill toggle (cyan when on), drawn into a small image once. 24x12 base units.
static func toggle_icon(on: bool) -> Texture2D:
	if _toggles.has(on):
		return _toggles[on]
	var k := 4  # drawn at 4x so it stays crisp on 4x phones
	var w := 24 * k
	var h := 12 * k
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var track := Color("3cbfd0") if on else Color("2a2846")
	var edge := Color(GOLD, 0.7)
	var r := float(h) * 0.5
	for y in h:
		for x in w:
			var cx := clampf(float(x) + 0.5, r, float(w) - r)
			var d := Vector2(float(x) + 0.5, float(y) + 0.5).distance_to(Vector2(cx, r))
			if d <= r - float(k):
				img.set_pixel(x, y, track)
			elif d <= r:
				img.set_pixel(x, y, edge)
	var kx := float(w) - r if on else r
	for y in h:
		for x in w:
			var d := Vector2(float(x) + 0.5, float(y) + 0.5).distance_to(Vector2(kx, r))
			if d <= r - float(k) * 1.5:
				img.set_pixel(x, y, Color("f3ebdd") if on else Color("8f8aa8"))
	var tex := ImageTexture.create_from_image(img)
	tex.set_size_override(Vector2i(24, 12))
	_toggles[on] = tex
	return tex
