class_name Ball
extends RefCounted
## A single projectile. Baby balls have no slot. Owned and pooled by Battle (never a node).

enum State { HAND, FLY, RETURN }

const TRAIL_POINTS := 8

## Stable identity across loadout rebuilds ("<slot uid>:<copy>" or "baby:<n>").
var key: String = ""
var slot: BallSlot
var pos: Vector2 = Vector2.ZERO
var vel: Vector2 = Vector2.ZERO
var state: State = State.HAND
## Caught by a Perfect Catch: fired first, deals bonus damage until it returns.
var charged: bool = false
var bounces: int = 0
var gems: int = 0
var prism: bool = false
var trail: PackedVector2Array = PackedVector2Array()


func push_trail() -> void:
	trail.append(pos)
	if trail.size() > TRAIL_POINTS:
		trail.remove_at(0)
