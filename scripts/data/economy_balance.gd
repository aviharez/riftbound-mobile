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
