class_name CombatBalance
extends Resource
## Every combat tunable. Values are in 270-wide world units and seconds.
## Keep in sync with docs/combat-spec.md. Gameplay code must read from here instead of hardcoding numbers.

@export_group("World")
@export var world_size: Vector2i = Vector2i(270, 560)
@export var wall_width: int = 15
@export var hud_band_height: int = 36
@export var ceiling_y: float = 38.0
@export var grid_columns: int = 8
@export var cell_size: float = 30.0
@export var enemy_size: float = 24.0
@export var first_row_y: float = 40.0
@export var rune_line_y: float = 455.0
@export var player_min: Vector2 = Vector2(22.0, 466.0)
@export var player_max: Vector2 = Vector2(248.0, 548.0)
@export var lost_below_y: float = 563.0

@export_group("Controls")
@export var move_sensitivity: float = 1.3
@export var aim_sensitivity: float = 0.6
@export var zone_tolerance: float = 8.0
@export var aim_min_deg: float = 15.0
@export var aim_max_deg: float = 165.0
@export var crosshair_distance: float = 35.0
## Initial aim, slightly off vertical so the first shots don't loop straight up an empty column.
@export var start_aim_deg: float = 78.0

@export_group("Balls")
@export var ball_radius: float = 2.0
@export var ball_speed: float = 420.0
@export var return_speed: float = 710.0
@export var max_substep: float = 2.0
@export var min_vertical_ratio: float = 0.2
@export var fire_interval: float = 0.11
@export var launch_offset: float = 4.5
@export var baby_ball_count: int = 3
@export var baby_ball_damage: int = 1
@export var catch_radius: float = 11.0
@export var catch_multiplier: int = 2
@export var catch_xp_bonus: float = 1.5
@export var catch_xp_bonus_max: float = 2.0
@export var catch_energy: float = 2.0

@export_group("Enemies and waves")
@export var descent_base: float = 3.75
@export var descent_per_wave: float = 0.45
@export var slow_factor: float = 0.45
@export var rows_per_wave: int = 6
@export var gaps_min: int = 1
@export var gaps_max: int = 3
@export var hp_base: float = 2.0
@export var hp_per_wave: float = 1.6
@export var boss_every_waves: int = 5
@export var player_hp: int = 10

@export_group("Gems and XP")
@export var gem_reach: float = 4.0
@export var gem_capacity: int = 3
@export var gem_lost_margin: float = 4.0
@export var xp_base: int = 5
@export var xp_per_level: int = 3

@export_group("Loadout and level up")
@export var ball_slots: int = 4
@export var item_slots: int = 4
@export var max_level: int = 3
@export var max_copies: int = 4
@export var new_ball_damage: int = 2
@export var cards_per_level: int = 3
## Base rerolls; the Rift Gate adds one per level (Lv1 at start), so a new save has 2.
@export var rerolls_per_run: int = 1
## Unfused ball upgrade odds. The remainder is "power +1".
@export var upgrade_copy_chance: float = 0.4
@export var upgrade_damage_chance: float = 0.3
## Fused ball upgrade odds. The remainder is "power +1".
@export var fused_upgrade_damage_chance: float = 0.5
@export var fallback_shards: int = 25
@export var fallback_heal: int = 3
@export var fallback_energy: float = 50.0

@export_group("Element effects")
@export var burn_base_duration: float = 2.0
@export var burn_tick: float = 0.6
@export var slow_base_duration: float = 1.5
@export var slow_duration_per_power: float = 0.5
@export var chain_range: float = 68.0
@export var chain_slow_duration: float = 2.0
@export var blast_base_radius: float = 15.0
@export var blast_radius_per_power: float = 3.0
@export var spread_radius: float = 36.0
@export var siphon_reach_bonus: float = 4.0
@export var siphon_capacity_multiplier: int = 2

@export_group("Ultimate")
@export var energy_max: float = 100.0
@export var flame_orb_speed: float = 270.0
@export var flame_orb_radius: float = 46.0
@export var flame_orb_damage_base: float = 4.0
@export var flame_orb_damage_per_wave: float = 1.5
@export var frost_nova_slow_duration: float = 4.0
@export var frost_nova_damage_base: float = 2.0
@export var frost_nova_damage_per_wave: float = 0.5
@export var verdant_bloom_heal: int = 2
@export var verdant_bloom_damage_base: float = 3.0
@export var verdant_bloom_damage_per_wave: float = 1.0
## Enemies whose bottom is within this distance above the rune line are hit by Verdant Bloom.
@export var verdant_bloom_reach: float = 110.0

@export_group("Feedback")
@export var hitstop_kill: float = 0.03
@export var hitstop_cap: float = 0.08
@export var hitstop_ultimate: float = 0.09
@export var hitstop_fusion: float = 0.12
@export var hitstop_boss: float = 0.16
@export var shake_max_offset: float = 5.0
@export var trauma_decay: float = 1.8
@export var flash_time: float = 0.07

@export_group("Caps")
@export var max_particles: int = 900
@export var max_rings: int = 120
@export var max_damage_numbers: int = 120
## Star flares on hits and kills (additive glow layer).
@export var max_flares: int = 48


## XP required to go from `level` to `level + 1`.
func xp_needed(level: int) -> int:
	return xp_base + xp_per_level * level


## Base HP for a regular enemy in `wave` (before the enemy's multiplier).
func base_hp(wave: int) -> float:
	return hp_base + hp_per_wave * float(wave)


## Shared descent speed of the formation in `wave`.
func descent_speed(wave: int) -> float:
	return descent_base + descent_per_wave * float(wave)
