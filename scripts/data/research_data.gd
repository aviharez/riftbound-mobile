class_name ResearchData
extends Resource
## A Library research topic: a permanent passive bought once with resources. See docs/library-spec.md.
##
## `stat` uses the run-bonus keys (baby_balls, max_hp, xp_mult, energy_gain, rerolls, start_damage)
## or `reward_mult` (extra share of Mana Shards and Ruins Materials from runs).

@export var id: StringName
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var stat: StringName
@export var value: float = 0.0
@export var cost: Vector3i = Vector3i(50, 20, 0)
@export var library_level: int = 1
## Shown on the card, e.g. "+10% XP in runs".
@export var effect_text: String = ""
