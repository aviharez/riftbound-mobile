extends Node
## Loads game data resources from res://data at startup.
## Usage: Registry.balance.ball_speed, Registry.elements[&"ember"], Registry.find_recipe(&"ember", &"frost"),
## Registry.economy.run_rewards(...), Registry.buildings[&"library"].

const BALANCE_PATH := "res://data/balance/combat_balance.tres"
const ELEMENTS_DIR := "res://data/elements"
const EVOLUTIONS_DIR := "res://data/evolutions"
const ITEMS_DIR := "res://data/items"
const ENEMIES_DIR := "res://data/enemies"
const BUILDINGS_DIR := "res://data/buildings"
const CHARACTERS_DIR := "res://data/characters"
const EXPEDITIONS_DIR := "res://data/expeditions"
const ECONOMY_PATH := "res://data/balance/economy_balance.tres"

var balance: CombatBalance
var elements: Dictionary[StringName, ElementData] = {}
var evolutions: Array[EvolutionRecipe] = []
var items: Dictionary[StringName, ItemData] = {}
var enemies: Dictionary[StringName, EnemyData] = {}
var economy: EconomyBalance
var buildings: Dictionary[StringName, BuildingData] = {}
## Playable students, in roster order (by unlock level).
var characters: Array[CharacterData] = []
## Expedition locations, in board order (by duration).
var expeditions: Array[ExpeditionData] = []


func _ready() -> void:
	balance = load(BALANCE_PATH) as CombatBalance
	if balance == null:
		push_error("Registry: missing balance at %s" % BALANCE_PATH)
		balance = CombatBalance.new()
	economy = load(ECONOMY_PATH) as EconomyBalance
	if economy == null:
		push_error("Registry: missing economy at %s" % ECONOMY_PATH)
		economy = EconomyBalance.new()
	for res: Resource in _load_dir(BUILDINGS_DIR):
		var bd := res as BuildingData
		if bd:
			buildings[bd.id] = bd
	for res: Resource in _load_dir(CHARACTERS_DIR):
		var cd := res as CharacterData
		if cd:
			characters.append(cd)
	characters.sort_custom(func(a: CharacterData, b: CharacterData) -> bool: return a.unlock_dormitory_level < b.unlock_dormitory_level)
	for res: Resource in _load_dir(EXPEDITIONS_DIR):
		var ex := res as ExpeditionData
		if ex:
			expeditions.append(ex)
	expeditions.sort_custom(func(a: ExpeditionData, b: ExpeditionData) -> bool: return a.duration_seconds < b.duration_seconds)
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


func character(id: StringName) -> CharacterData:
	for c: CharacterData in characters:
		if c.id == id:
			return c
	return characters[0] if not characters.is_empty() else null


func expedition(id: StringName) -> ExpeditionData:
	for e: ExpeditionData in expeditions:
		if e.id == id:
			return e
	return null
