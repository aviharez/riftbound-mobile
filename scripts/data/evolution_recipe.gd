class_name EvolutionRecipe
extends Resource
## Fixed fusion result for two unfused base elements (order does not matter).
## Pairs without a recipe become a generic fusion (union of effects).

@export var element_a: StringName
@export var element_b: StringName
@export var result_id: StringName
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var core_color: Color = Color.WHITE
@export var glow_color: Color = Color.WHITE
@export var effects: Array[StringName] = []


func matches(a: StringName, b: StringName) -> bool:
	return (a == element_a and b == element_b) or (a == element_b and b == element_a)
