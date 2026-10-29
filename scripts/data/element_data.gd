class_name ElementData
extends Resource
## A base element a ball slot can hold (Ember, Frost, ...). Effects are resolved by the combat code by id.
## Known effect ids: burn, slow, siphon, chain, chainSlow, blast, spread (see docs/combat-spec.md §5).

@export var id: StringName
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var core_color: Color = Color.WHITE
@export var glow_color: Color = Color.WHITE
@export var effects: Array[StringName] = []
