class_name CharacterData
extends Resource
## A playable student. Their element is the run's starting ball (slot 1) and their ultimate replaces Flame Orb.
## Levels are bought in the roster with resources (docs/character-spec.md).

@export var id: StringName
@export var display_name: String = ""
## Short role line, e.g. "Fire · Damage".
@export var role: String = ""
@export_multiline var bio: String = ""
@export var personality: String = ""
@export var element_id: StringName
## Known ultimates: flame_orb, frost_nova, verdant_bloom (resolved in Battle).
@export var ultimate_id: StringName
@export var ultimate_name: String = ""
@export_multiline var ultimate_description: String = ""
@export var hair_color: Color = Color("c7432c")
@export var accent_color: Color = Color("E6BD73")
## Dormitory level needed before this student joins (0 = available from the start).
@export var unlock_dormitory_level: int = 0
@export var max_level: int = 10
@export var hp_per_level: int = 1
## Levels at which the starting element ball gains +1 damage.
@export var damage_levels: Array[int] = [4, 7, 10]


func start_damage_bonus(level: int) -> int:
	var n := 0
	for l: int in damage_levels:
		if level >= l:
			n += 1
	return n


func hp_bonus(level: int) -> int:
	return hp_per_level * maxi(0, level - 1)
