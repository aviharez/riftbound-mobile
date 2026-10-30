class_name ExpeditionData
extends Resource
## A location students can be sent to for a real-time duration. Pays resources and reveals story clues.
## See docs/expedition-spec.md.

@export var id: StringName
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var duration_seconds: float = 300.0
## Danger shown as 1-3 marks.
@export var threat: int = 1
@export var recommended_power: float = 10.0
@export var max_team: int = 2
## Element that suits this place: students of this element count extra team power.
@export var preferred_element: StringName
## Paid on success (a failure pays EconomyBalance.expedition_fail_fraction of it). (shards, materials, relics)
@export var rewards: Vector3i = Vector3i(40, 20, 0)
## Chance of a rare find on success: +rare_reward on top.
@export var rare_chance: float = 0.1
@export var rare_reward: Vector3i = Vector3i(0, 0, 1)
## Requirement to unlock (empty building = none).
@export var unlock_building: StringName
@export var unlock_building_level: int = 0
@export var unlock_best_wave: int = 0
## Story clues revealed one per successful expedition, in order.
@export var clues: Array[String] = []
