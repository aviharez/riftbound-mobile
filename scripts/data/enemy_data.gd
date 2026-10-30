class_name EnemyData
extends Resource
## An enemy type. Regular enemies use `hp_multiplier` × the wave's base HP.
## Bosses (is_boss) use the flat formula hp_flat_base + hp_flat_per_wave × wave instead.

@export var id: StringName
@export var display_name: String = ""
@export var is_boss: bool = false
@export var hp_multiplier: float = 1.0
@export var hp_flat_base: float = 0.0
@export var hp_flat_per_wave: float = 0.0
## Spawn chance per grid cell = spawn_chance_base + spawn_chance_per_wave × wave.
## Regular enemy types are rolled in order; the one with spawn_chance_base < 0 is the fallback ("remainder").
@export var spawn_chance_base: float = 0.0
@export var spawn_chance_per_wave: float = 0.0
@export var size_cells: int = 1
## Sprite drawn centred on the enemy's cell (a 32x32 sprite on a 24x24 hitbox). Null = placeholder drawing.
@export var sprite: Texture2D
@export var gem_drop: int = 1
@export var prism_chance: float = 0.0
@export var energy_on_kill: float = 3.0
@export var contact_damage: int = 1
@export var death_blast_radius: float = 0.0
@export var death_blast_damage: int = 0


func hp_for_wave(wave: int, balance: CombatBalance) -> int:
	if is_boss:
		return roundi(hp_flat_base + hp_flat_per_wave * float(wave))
	return maxi(1, roundi(balance.base_hp(wave) * hp_multiplier))
