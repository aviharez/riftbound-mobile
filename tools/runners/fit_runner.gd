extends Node
## Screen-fit check (art-spec §2): the root viewport must be scaled by a whole number with no letterbox offset,
## cover the window (up to a sub-base-pixel remainder) and still fit the 270x560 playfield. Movie Maker screenshots can't show letterbox
## bars (they capture the viewport, not the window), so this reads the final transform. Run through
## tools/fit.sh, which launches the game once per phone/tablet size.

var _wait := 10


func _process(_delta: float) -> void:
	_wait -= 1
	if _wait > 0:
		return
	var win := get_tree().root
	var actual := win.size
	var t := win.get_final_transform()
	var k := t.get_scale().x
	var visible := win.get_visible_rect().size
	# A remainder smaller than one base pixel (e.g. 2778 / 4 = 694.5 rows) leaves at most k - 1 physical pixels.
	var ok := is_equal_approx(k, roundf(k)) and t.origin.x < k and t.origin.y < k \
		and visible.x >= 270.0 and visible.y >= 560.0 \
		and visible.x * k > float(actual.x) - k and visible.y * k > float(actual.y) - k
	print("%s window %s scale %.3f offset %s visible %s" % ["FIT OK  " if ok else "FIT FAIL", actual, k, t.origin, visible])
	get_tree().quit(0 if ok else 1)
