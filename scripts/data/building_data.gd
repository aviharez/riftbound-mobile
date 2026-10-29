class_name BuildingData
extends Resource
## An academy building: where it stands on the hub map, what each level costs and what bonus it gives runs.
## See docs/economy-spec.md. Costs are per level: index 0 = repair to Lv1, index 1 = upgrade to Lv2, ...
## Each cost is Vector3i(mana_shards, ruins_materials, ancient_relics).

@export var id: StringName
@export var display_name: String = ""
@export_multiline var description: String = ""
## Footprint on the hub map, in hub world units (top-left + size).
@export var map_rect: Rect2 = Rect2(0, 0, 80, 60)
@export var roof_color: Color = Color("6F4AE6")
@export var max_level: int = 3
## True for buildings that are usable from the start (Lv1 without repair).
@export var starts_repaired: bool = false
@export var costs: Array[Vector3i] = []
## Run modifier this building adds per level. Known stats: baby_balls, max_hp, xp_mult, energy_gain, rerolls.
@export var bonus_stat: StringName
@export var bonus_per_level: float = 0.0
## Short text for the bonus, with %s for the formatted total value (e.g. "+%s baby balls").
@export var bonus_format: String = ""
## Opens the Rift (starts a battle) when interacted with.
@export var is_rift_gate: bool = false


func cost_for_level(target_level: int) -> Vector3i:
	var i := target_level - 1
	if i < 0 or i >= costs.size():
		return Vector3i.ZERO
	return costs[i]


func bonus_text(level: int) -> String:
	if bonus_format == "" or level <= 0:
		return ""
	var v := bonus_per_level * float(level)
	var shown := str(roundi(v * 100.0)) if bonus_stat == &"xp_mult" or bonus_stat == &"energy_gain" else str(roundi(v))
	return bonus_format % shown


## Point in front of the door, where the avatar stands to use the building.
func door_point() -> Vector2:
	return Vector2(map_rect.get_center().x, map_rect.end.y + 8.0)
