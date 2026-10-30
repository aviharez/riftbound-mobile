class_name FlourishLabel
extends Label
## A centred heading with thin gold lines and small diamonds on both sides ("— VICTORY REWARDS —").
## Still a Label, so code that builds panels can treat it like any other.

var line_color: Color = Color(UiTheme.GOLD, 0.55)


func _ready() -> void:
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	size_flags_horizontal = Control.SIZE_EXPAND_FILL


func _draw() -> void:
	var font := get_theme_font("font")
	var fs := get_theme_font_size("font_size")
	var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var y := floorf(size.y * 0.5) + 0.5
	var gap := 6.0
	var l_end := (size.x - tw) * 0.5 - gap
	var r_start := (size.x + tw) * 0.5 + gap
	var reach := minf(l_end - 2.0, 46.0)
	if reach < 6.0:
		return
	draw_line(Vector2(l_end - reach, y), Vector2(l_end, y), line_color, 1.0, true)
	draw_line(Vector2(r_start, y), Vector2(r_start + reach, y), line_color, 1.0, true)
	for x: float in [l_end - reach, r_start + reach]:
		draw_colored_polygon(PackedVector2Array([Vector2(x, y - 2.0), Vector2(x + 2.0, y), Vector2(x, y + 2.0), Vector2(x - 2.0, y)]), line_color)
