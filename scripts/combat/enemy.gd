class_name Enemy
extends RefCounted
## One enemy in the formation. `pos` is the top-left of its square body. Owned by Battle (never a node).

var data: EnemyData
var pos: Vector2 = Vector2.ZERO
var size: float = 24.0
var hp: int = 1
var max_hp: int = 1
var alive: bool = true
## Visual state.
var flash: float = 0.0
var squash: float = 0.0
var spawn: float = 0.0
var phase: float = 0.0
## Status effects.
var burn: float = 0.0
var burn_timer: float = 0.0
var burn_damage: int = 1
var slow: float = 0.0


func center() -> Vector2:
	return pos + Vector2(size, size) * 0.5


func rect() -> Rect2:
	return Rect2(pos, Vector2(size, size))
