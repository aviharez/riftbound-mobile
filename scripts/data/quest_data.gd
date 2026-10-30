class_name QuestData
extends Resource
## A quest journal entry: reach a target on one of GameState's counters, then claim the reward.
## Progress is read from existing state, so nothing has to report quest events. See docs/library-spec.md.
##
## `kind` (see GameState.quest_value): runs, best_wave, kills, bosses, building_level (param = building id),
## expeditions, clues, bond_level (best pair), scenes, recipes, research, student_level (best student).

@export var id: StringName
@export var title: String = ""
@export_multiline var description: String = ""
@export var kind: StringName
@export var param: StringName = &""
@export var target: int = 1
@export var rewards: Vector3i = Vector3i(30, 10, 0)
## Journal order.
@export var order: int = 0
