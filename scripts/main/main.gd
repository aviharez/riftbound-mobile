class_name Main
extends Node
## Root scene. Hosts the pixel-perfect world SubViewport and the native-resolution UI layer.
##
## Display pipeline (see docs/art-spec.md §2):
## - Project stretch: canvas_items + expand + integer, base 270x560.
## - The SubViewport matches the visible area in base units, so the world renders at 1 world px = 1 base unit
##   and is scaled by the same integer factor as everything else. UI in $UI stays crisp.
## - The fixed 270x560 playfield is centered horizontally and anchored to the bottom of the visible area.
##
## Input arrives here in root coordinates. Convert with screen_to_world() before handing it to gameplay.

@onready var world_container: SubViewportContainer = $WorldContainer
@onready var world_viewport: SubViewport = $WorldContainer/WorldViewport
@onready var world: World = $WorldContainer/WorldViewport/World
@onready var debug_label: Label = $UI/Root/DebugLabel

## Top-left of the playfield inside the visible area, in base units.
var world_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	get_viewport().size_changed.connect(_layout)
	_layout()


## Converts a position from root/UI coordinates to playfield (world) coordinates.
func screen_to_world(screen_pos: Vector2) -> Vector2:
	return screen_pos - world_offset


func _layout() -> void:
	var visible := get_viewport().get_visible_rect().size
	var playfield := Vector2(Registry.balance.world_size)
	world_offset = Vector2(floorf((visible.x - playfield.x) * 0.5), floorf(visible.y - playfield.y))
	world.position = world_offset
	world.set_visible_rect(Rect2(-world_offset, visible))
	_update_debug(visible)


func _update_debug(visible: Vector2) -> void:
	var window_size := Vector2(get_window().size)
	var scale_factor := window_size.x / maxf(visible.x, 1.0)
	debug_label.text = "M0 bootstrap  |  view %dx%d  |  x%d  |  Godot %s" % [
		roundi(visible.x), roundi(visible.y), roundi(scale_factor), Engine.get_version_info().string]


func _unhandled_input(event: InputEvent) -> void:
	# M0 only: tap to drop a marker, which verifies the screen -> world conversion. Replace in M1.
	if event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		world.add_marker(screen_to_world((event as InputEventScreenTouch).position))
