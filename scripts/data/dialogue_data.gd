class_name DialogueData
extends Resource
## A short dialogue scene between two students (and you). See docs/relationship-spec.md.
##
## Line format: "speaker: text". Speaker is a student id (lyra, selene, noah) or "narrator".
## Choice format: {"text": String, "points": int, "reply": Array of lines}. Points add to the bond.

@export var id: StringName
@export var bond_id: StringName
## Bond level needed to see this scene. Scenes of a bond play in this order.
@export var bond_level_required: int = 0
@export var title: String = ""
## Shown above the scene ("Dormitory common room, late evening").
@export var location: String = ""
@export var lines: Array[String] = []
## Asked after the last line. Empty = no choice.
@export var choice_prompt: String = ""
@export var choices: Array[Dictionary] = []
## Lines after the choice reply, shared by every choice.
@export var ending: Array[String] = []


static func speaker_of(line: String) -> StringName:
	var i := line.find(":")
	return StringName(line.substr(0, i).strip_edges()) if i > 0 else &"narrator"


static func text_of(line: String) -> String:
	var i := line.find(":")
	return line.substr(i + 1).strip_edges() if i > 0 else line


## Every student id that speaks in the scene, in order of first appearance.
func cast() -> Array[StringName]:
	var out: Array[StringName] = []
	var all: Array[String] = lines.duplicate()
	for c: Dictionary in choices:
		for l: Variant in c.get("reply", []):
			all.append(str(l))
	all.append_array(ending)
	for l: String in all:
		var s := speaker_of(l)
		if s != &"narrator" and not out.has(s):
			out.append(s)
	return out


## Format problems, for a data check at load ("" = fine).
func validate() -> String:
	var problems: Array[String] = []
	for l: String in lines + ending:
		if l.find(":") <= 0:
			problems.append("line without speaker: " + l)
	for c: Dictionary in choices:
		if not c.has("text") or not c.has("points"):
			problems.append("choice needs text and points")
	return "; ".join(problems)
