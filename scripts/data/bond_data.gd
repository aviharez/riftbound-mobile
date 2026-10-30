class_name BondData
extends Resource
## Friendship between two students. Grows from Dormitory scenes and shared expeditions;
## at EconomyBalance.duo_bond_level it unlocks a duo evolution. See docs/relationship-spec.md.

@export var id: StringName
@export var student_a: StringName
@export var student_b: StringName
## EvolutionRecipe.result_id unlocked at the duo bond level (its recipe has duo_bond = id).
@export var duo_recipe: StringName
@export_multiline var description: String = ""


func has_student(student: StringName) -> bool:
	return student == student_a or student == student_b


func involves(a: StringName, b: StringName) -> bool:
	return (a == student_a and b == student_b) or (a == student_b and b == student_a)


func display_name() -> String:
	return "%s & %s" % [_first(student_a), _first(student_b)]


static func _first(student: StringName) -> String:
	var c := Registry.character(student)
	return c.display_name.get_slice(" ", 0) if c else String(student)
