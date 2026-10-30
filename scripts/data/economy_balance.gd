class_name EconomyBalance
extends Resource
## Meta-economy tunables: run rewards and starting resources. See docs/economy-spec.md.

@export_group("Run rewards")
@export var shards_per_kill: float = 1.0
@export var shards_per_wave: int = 10
@export var shards_per_boss: int = 30
@export var materials_per_wave: int = 4
@export var materials_per_boss: int = 15
@export var kills_per_material: int = 5
@export var relics_per_boss: int = 1
## Rewards kept when retreating from a run (fraction of what the run would have paid).
@export var retreat_fraction: float = 1.0

@export_group("Start")
@export var start_shards: int = 0
@export var start_materials: int = 0
@export var start_relics: int = 0

@export_group("Students")
## Cost to raise a student from `level` to `level + 1`: base + per_level × level, as (shards, materials, relics).
@export var student_cost_base: Vector3i = Vector3i(30, 10, 0)
@export var student_cost_per_level: Vector3i = Vector3i(25, 6, 0)
## Levels at or above this also cost one Ancient Relic.
@export var student_relic_from_level: int = 7

@export_group("Expeditions")
## Team power per student = base + per_level × level; students of the place's preferred element count × match.
@export var expedition_power_base: float = 8.0
@export var expedition_power_per_level: float = 4.0
@export var expedition_element_match: float = 1.5
## Success chance = clamp(power / recommended, min, 1).
@export var expedition_min_chance: float = 0.35
## Share of the rewards paid when an expedition fails.
@export var expedition_fail_fraction: float = 0.5

@export_group("Bonds")
## Total bond points needed for bond level 1, 2, 3... (index 0 = Lv1). The size is the max bond level.
## Capped at the duo level until more scenes exist (relationship-spec).
@export var bond_thresholds: Array[int] = [3, 7, 12]
## Points for finishing a Dormitory scene (the choice adds its own 0-2 on top).
@export var bond_scene_points: int = 2
## Points for every pair of students that came back from the same expedition.
@export var bond_expedition_points: int = 1
## Bond level that unlocks the pair's duo evolution.
@export var duo_bond_level: int = 3
## A new Dormitory scene becomes available after this many Rift runs since the last one.
@export var runs_per_scene: int = 1

@export_group("Academy hub")
@export var hub_size: Vector2 = Vector2(300.0, 640.0)
@export var hub_spawn: Vector2 = Vector2(150.0, 400.0)
@export var fountain_pos: Vector2 = Vector2(150.0, 330.0)
@export var walk_speed: float = 80.0
@export var interact_distance: float = 10.0


## Rewards for a finished run. Returns Vector3i(mana_shards, ruins_materials, ancient_relics).
func run_rewards(kills: int, wave: int, bosses: int, bonus_shards: int) -> Vector3i:
	var waves_cleared := maxi(0, wave - 1)
	var shards := roundi(float(kills) * shards_per_kill) + shards_per_wave * waves_cleared + shards_per_boss * bosses + bonus_shards
	var materials := materials_per_wave * waves_cleared + materials_per_boss * bosses + int(kills / maxf(1.0, float(kills_per_material)))
	var relics := relics_per_boss * bosses
	return Vector3i(shards, materials, relics)


func student_upgrade_cost(level: int) -> Vector3i:
	var c := student_cost_base + student_cost_per_level * level
	if level >= student_relic_from_level:
		c.z += 1
	return c
