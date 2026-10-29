extends Node
## Loads game data resources from res://data at startup.
## Usage: Registry.balance.ball_speed, Registry.elements[&"ember"], Registry.find_recipe(&"ember", &"frost").

const BALANCE_PATH := "res://data/balance/combat_balance.tres"
const ELEMENTS_DIR := "res://data/elements"
const EVOLUTIONS_DIR := "res://data/evolutions"
const ITEMS_DIR := "res://data/items"
const ENEMIES_DIR := "res://data/enemies"

var balance: CombatBalance
var elements: Dictionary[StringName, ElementData] = {}
var evolutions: Array[EvolutionRecipe] = []
var items: Dictionary[StringName, ItemData] = {}
var enemies: Dictionary[StringName, EnemyData] = {}


func _ready() -> void:
	balance = load(BALANCE_PATH) as CombatBalance
	if balance == null:
		push_error("Registry: missing balance at %s" % BALANCE_PATH)
		balance = CombatBalance.new()
	for res: Resource in _load_dir(ELEMENTS_DIR):
		var e := res as ElementData
		if e:
			elements[e.id] = e
	for res: Resource in _load_dir(EVOLUTIONS_DIR):
		var r := res as EvolutionRecipe
		if r:
			evolutions.append(r)
	for res: Resource in _load_dir(ITEMS_DIR):
		var it := res as ItemData
		if it:
			items[it.id] = it
	for res: Resource in _load_dir(ENEMIES_DIR):
		var en := res as EnemyData
		if en:
			enemies[en.id] = en
	print_verbose("Registry: %d elements, %d recipes, %d items, %d enemies" % [elements.size(), evolutions.size(), items.size(), enemies.size()])


## Recipe for two unfused base elements, or null for a generic fusion.
func find_recipe(a: StringName, b: StringName) -> EvolutionRecipe:
	for r: EvolutionRecipe in evolutions:
		if r.matches(a, b):
			return r
	return null


## Loads every .tres/.res in a folder. Exported builds list files with a ".remap" suffix, so strip it.
func _load_dir(path: String) -> Array[Resource]:
	var out: Array[Resource] = []
	var files := DirAccess.get_files_at(path)
	files.sort()
	for f: String in files:
		var file_name := f.trim_suffix(".remap")
		if not (file_name.ends_with(".tres") or file_name.ends_with(".res")):
			continue
		var res := load(path.path_join(file_name))
		if res:
			out.append(res)
		else:
			push_error("Registry: failed to load %s" % path.path_join(file_name))
	return out
