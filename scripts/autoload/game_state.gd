extends Node
## Persistent meta state: resources, academy buildings, lifetime stats, and the hand-off between screens.
## Saved as JSON in user://save.json. See docs/economy-spec.md.

signal resources_changed
signal building_changed(id: StringName)
signal student_changed(id: StringName)
signal expeditions_changed

const SAVE_PATH := "user://save.json"
const TEST_SAVE_PATH := "user://save_test.json"
const SAVE_VERSION := 1

const SCENE_TITLE := "res://scenes/title/title_screen.tscn"
const SCENE_ACADEMY := "res://scenes/academy/academy_screen.tscn"
const SCENE_BATTLE := "res://scenes/battle/battle_screen.tscn"

## Where the game is saved. Test tools switch to TEST_SAVE_PATH so they never touch the player's save.
var save_path: String = SAVE_PATH
var mana_shards: int = 0
var ruins_materials: int = 0
var ancient_relics: int = 0
var building_levels: Dictionary[StringName, int] = {}
var runs: int = 0
var best_wave: int = 0
var total_kills: int = 0
var bosses_defeated: int = 0
## Student levels (1..max). Locked students keep level 1 until they join.
var student_levels: Dictionary[StringName, int] = {}
var selected_student: StringName = &"lyra"
## Running expeditions: id -> {team: Array[StringName], start: float, end: float, success: bool, rare: bool}.
## Outcomes are rolled when the expedition starts, so reopening the game can't change them.
var expeditions_active: Dictionary = {}
## How many story clues each expedition has revealed.
var clues_found: Dictionary[StringName, int] = {}

## Screen hand-off (not saved): rewards of the run that just ended, shown on the result screen.
var last_rewards: Vector3i = Vector3i.ZERO
## Where the avatar stands when the academy opens (not saved).
var academy_spawn: Vector2 = Vector2.INF


func _ready() -> void:
	if not load_game():
		reset()


func has_save() -> bool:
	return FileAccess.file_exists(save_path)


## Used by test tools: switch to a throwaway save file and start fresh.
func use_test_save() -> void:
	save_path = TEST_SAVE_PATH
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	if Registry.economy:  # otherwise _ready() will start fresh from the (now missing) test save
		reset()


func reset() -> void:
	var eco := Registry.economy
	mana_shards = eco.start_shards
	ruins_materials = eco.start_materials
	ancient_relics = eco.start_relics
	building_levels.clear()
	for id: StringName in Registry.buildings:
		building_levels[id] = 1 if Registry.buildings[id].starts_repaired else 0
	runs = 0
	best_wave = 0
	total_kills = 0
	bosses_defeated = 0
	student_levels.clear()
	for c: CharacterData in Registry.characters:
		student_levels[c.id] = 1
	selected_student = Registry.characters[0].id if not Registry.characters.is_empty() else &"lyra"
	expeditions_active.clear()
	clues_found.clear()
	resources_changed.emit()


func new_game() -> void:
	reset()
	save_game()


# ---------------------------------------------------------------- resources

func resources() -> Vector3i:
	return Vector3i(mana_shards, ruins_materials, ancient_relics)


func can_afford(cost: Vector3i) -> bool:
	return mana_shards >= cost.x and ruins_materials >= cost.y and ancient_relics >= cost.z


func add_resources(r: Vector3i) -> void:
	mana_shards += r.x
	ruins_materials += r.y
	ancient_relics += r.z
	resources_changed.emit()


# ---------------------------------------------------------------- buildings

func building_level(id: StringName) -> int:
	return building_levels.get(id, 0)


## Cost of the next level, or Vector3i(-1, -1, -1) when already at max level.
func next_cost(id: StringName) -> Vector3i:
	var b: BuildingData = Registry.buildings[id]
	var lv := building_level(id)
	if lv >= b.max_level:
		return Vector3i(-1, -1, -1)
	return b.cost_for_level(lv + 1)


func can_upgrade(id: StringName) -> bool:
	var c := next_cost(id)
	return c.x >= 0 and can_afford(c)


func upgrade_building(id: StringName) -> bool:
	if not can_upgrade(id):
		return false
	var c := next_cost(id)
	add_resources(-c)
	building_levels[id] = building_level(id) + 1
	building_changed.emit(id)
	save_game()
	return true


## Total run bonus from all buildings for a stat (baby_balls, max_hp, xp_mult, energy_gain, rerolls).
func meta_bonus(stat: StringName) -> float:
	var total := 0.0
	for id: StringName in Registry.buildings:
		var b: BuildingData = Registry.buildings[id]
		if b.bonus_stat == stat:
			total += b.bonus_per_level * float(building_level(id))
	return total


## All meta bonuses as a dictionary, passed to Battle.start_run(): buildings plus the selected student's level.
func run_bonuses() -> Dictionary:
	var out := {}
	for stat: StringName in [&"baby_balls", &"max_hp", &"xp_mult", &"energy_gain", &"rerolls"]:
		out[stat] = meta_bonus(stat)
	var c := current_student()
	var lv := student_level(c.id)
	out[&"max_hp"] = float(out[&"max_hp"]) + float(c.hp_bonus(lv))
	out[&"start_damage"] = float(c.start_damage_bonus(lv))
	return out


# ---------------------------------------------------------------- students

func current_student() -> CharacterData:
	return Registry.character(selected_student)


func student_level(id: StringName) -> int:
	return student_levels.get(id, 1)


func is_student_unlocked(id: StringName) -> bool:
	return building_level(&"dormitory") >= Registry.character(id).unlock_dormitory_level


## Students that become available at exactly this dormitory level (for the "joined" notice).
func students_joining_at(dorm_level: int) -> Array[CharacterData]:
	var out: Array[CharacterData] = []
	for c: CharacterData in Registry.characters:
		if c.unlock_dormitory_level == dorm_level and dorm_level > 0:
			out.append(c)
	return out


func select_student(id: StringName) -> void:
	if not is_student_unlocked(id) or student_busy(id):
		return
	selected_student = id
	student_changed.emit(id)
	save_game()


## Cost of the next student level, or Vector3i(-1, -1, -1) at max level.
func student_next_cost(id: StringName) -> Vector3i:
	var lv := student_level(id)
	if lv >= Registry.character(id).max_level:
		return Vector3i(-1, -1, -1)
	return Registry.economy.student_upgrade_cost(lv)


func can_upgrade_student(id: StringName) -> bool:
	var c := student_next_cost(id)
	return is_student_unlocked(id) and c.x >= 0 and can_afford(c)


func upgrade_student(id: StringName) -> bool:
	if not can_upgrade_student(id):
		return false
	add_resources(-student_next_cost(id))
	student_levels[id] = student_level(id) + 1
	student_changed.emit(id)
	save_game()
	return true


# ---------------------------------------------------------------- expeditions

func now() -> float:
	return Time.get_unix_time_from_system()


func expedition_unlocked(e: ExpeditionData) -> bool:
	if e.unlock_building != &"" and building_level(e.unlock_building) < e.unlock_building_level:
		return false
	return best_wave >= e.unlock_best_wave


func expedition_lock_reason(e: ExpeditionData) -> String:
	if e.unlock_building != &"" and building_level(e.unlock_building) < e.unlock_building_level:
		return "Restore the %s to Lv%d" % [Registry.buildings[e.unlock_building].display_name, e.unlock_building_level]
	if best_wave < e.unlock_best_wave:
		return "Reach wave %d in the Rift" % e.unlock_best_wave
	return ""


func student_busy(id: StringName) -> bool:
	for exp_id: StringName in expeditions_active:
		if (expeditions_active[exp_id].team as Array).has(id):
			return true
	return false


func free_students() -> Array[CharacterData]:
	var out: Array[CharacterData] = []
	for c: CharacterData in Registry.characters:
		if is_student_unlocked(c.id) and not student_busy(c.id):
			out.append(c)
	return out


func team_power(e: ExpeditionData, team: Array[StringName]) -> float:
	var eco := Registry.economy
	var p := 0.0
	for id: StringName in team:
		var c := Registry.character(id)
		var v := eco.expedition_power_base + eco.expedition_power_per_level * float(student_level(id))
		if c.element_id == e.preferred_element:
			v *= eco.expedition_element_match
		p += v
	return p


func success_chance(e: ExpeditionData, team: Array[StringName]) -> float:
	if team.is_empty():
		return 0.0
	return clampf(team_power(e, team) / e.recommended_power, Registry.economy.expedition_min_chance, 1.0)


## Why this team can't go, or "" if it can.
func expedition_team_problem(e: ExpeditionData, team: Array[StringName]) -> String:
	if not expedition_unlocked(e):
		return expedition_lock_reason(e)
	if expeditions_active.has(e.id):
		return "Already in progress"
	if team.is_empty():
		return "Pick at least one student"
	if team.size() > e.max_team:
		return "At most %d students" % e.max_team
	if free_students().size() - team.size() < 1:
		return "Someone has to stay to defend the academy"
	return ""


func start_expedition(id: StringName, team: Array[StringName]) -> bool:
	var e := Registry.expedition(id)
	if e == null or expedition_team_problem(e, team) != "":
		return false
	var success := randf() < success_chance(e, team)
	var rare := success and randf() < e.rare_chance
	var t := now()
	var names: Array[StringName] = team.duplicate()
	expeditions_active[id] = {"team": names, "start": t, "end": t + e.duration_seconds, "success": success, "rare": rare}
	if names.has(selected_student):
		var free := free_students()
		if not free.is_empty():
			selected_student = free[0].id
			student_changed.emit(selected_student)
	expeditions_changed.emit()
	save_game()
	return true


func expedition_time_left(id: StringName) -> float:
	if not expeditions_active.has(id):
		return 0.0
	return maxf(0.0, float(expeditions_active[id].end) - now())


func is_expedition_ready(id: StringName) -> bool:
	return expeditions_active.has(id) and expedition_time_left(id) <= 0.0


func ready_expedition_count() -> int:
	var n := 0
	for id: StringName in expeditions_active:
		if is_expedition_ready(id):
			n += 1
	return n


## Pays out a finished expedition. Returns {success, rare, rewards: Vector3i, clue: String, team}.
func claim_expedition(id: StringName) -> Dictionary:
	if not is_expedition_ready(id):
		return {}
	var e := Registry.expedition(id)
	var rec: Dictionary = expeditions_active[id]
	var success: bool = rec.success
	var r := e.rewards
	if not success:
		var f := Registry.economy.expedition_fail_fraction
		r = Vector3i(roundi(r.x * f), roundi(r.y * f), roundi(r.z * f))
	if rec.rare:
		r += e.rare_reward
	add_resources(r)
	var clue := ""
	if success:
		var n: int = clues_found.get(id, 0)
		if n < e.clues.size():
			clue = e.clues[n]
			clues_found[id] = n + 1
	expeditions_active.erase(id)
	expeditions_changed.emit()
	save_game()
	return {"success": success, "rare": rec.rare, "rewards": r, "clue": clue, "team": rec.team}


## Debug: make a running expedition finish now.
func debug_finish_expedition(id: StringName) -> void:
	if expeditions_active.has(id):
		expeditions_active[id].end = now() - 1.0
		expeditions_changed.emit()


# ---------------------------------------------------------------- runs

## Banks the rewards of a finished run and updates lifetime stats. Returns the rewards.
func finish_run(kills: int, wave: int, bosses: int, bonus_shards: int, retreated: bool) -> Vector3i:
	var eco := Registry.economy
	var r := eco.run_rewards(kills, wave, bosses, bonus_shards)
	if retreated:
		r = Vector3i(roundi(r.x * eco.retreat_fraction), roundi(r.y * eco.retreat_fraction), roundi(r.z * eco.retreat_fraction))
	add_resources(r)
	runs += 1
	best_wave = maxi(best_wave, wave)
	total_kills += kills
	bosses_defeated += bosses
	last_rewards = r
	save_game()
	return r


func go_to(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)


# ---------------------------------------------------------------- save / load

func save_game() -> void:
	var levels := {}
	for id: StringName in building_levels:
		levels[String(id)] = building_levels[id]
	var data := {
		"version": SAVE_VERSION,
		"resources": {"mana_shards": mana_shards, "ruins_materials": ruins_materials, "ancient_relics": ancient_relics},
		"buildings": levels,
		"stats": {"runs": runs, "best_wave": best_wave, "total_kills": total_kills, "bosses_defeated": bosses_defeated},
		"students": _student_dict(),
		"selected_student": String(selected_student),
		"expeditions": _expedition_dict(),
		"clues": _clue_dict(),
	}
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f == null:
		push_warning("GameState: cannot write save (%s)" % error_string(FileAccess.get_open_error()))
		return
	f.store_string(JSON.stringify(data, "\t"))


func load_game() -> bool:
	if not has_save():
		return false
	var text := FileAccess.get_file_as_string(save_path)
	var data: Variant = JSON.parse_string(text)
	if not data is Dictionary:
		push_warning("GameState: save file is corrupt, starting fresh")
		return false
	reset()
	var d: Dictionary = data
	var res: Dictionary = d.get("resources", {})
	mana_shards = int(res.get("mana_shards", mana_shards))
	ruins_materials = int(res.get("ruins_materials", ruins_materials))
	ancient_relics = int(res.get("ancient_relics", ancient_relics))
	var levels: Dictionary = d.get("buildings", {})
	for key: String in levels:
		var id := StringName(key)
		if Registry.buildings.has(id):
			building_levels[id] = clampi(int(levels[key]), 0, Registry.buildings[id].max_level)
	var st: Dictionary = d.get("stats", {})
	runs = int(st.get("runs", 0))
	best_wave = int(st.get("best_wave", 0))
	total_kills = int(st.get("total_kills", 0))
	bosses_defeated = int(st.get("bosses_defeated", 0))
	var studs: Dictionary = d.get("students", {})
	for key: String in studs:
		var sid := StringName(key)
		if student_levels.has(sid):
			student_levels[sid] = clampi(int(studs[key]), 1, Registry.character(sid).max_level)
	var exps: Dictionary = d.get("expeditions", {})
	for key: String in exps:
		var eid := StringName(key)
		if Registry.expedition(eid) == null:
			continue
		var rec: Dictionary = exps[key]
		var team: Array[StringName] = []
		for m: Variant in rec.get("team", []):
			team.append(StringName(str(m)))
		expeditions_active[eid] = {"team": team, "start": float(rec.get("start", 0.0)), "end": float(rec.get("end", 0.0)),
			"success": bool(rec.get("success", false)), "rare": bool(rec.get("rare", false))}
	var cl: Dictionary = d.get("clues", {})
	for key: String in cl:
		clues_found[StringName(key)] = int(cl[key])
	var sel := StringName(str(d.get("selected_student", selected_student)))
	if student_levels.has(sel) and is_student_unlocked(sel) and not student_busy(sel):
		selected_student = sel
	resources_changed.emit()
	return true


func _student_dict() -> Dictionary:
	var out := {}
	for id: StringName in student_levels:
		out[String(id)] = student_levels[id]
	return out


func _expedition_dict() -> Dictionary:
	var out := {}
	for id: StringName in expeditions_active:
		var rec: Dictionary = expeditions_active[id]
		var team: Array[String] = []
		for m: StringName in rec.team:
			team.append(String(m))
		out[String(id)] = {"team": team, "start": rec.start, "end": rec.end, "success": rec.success, "rare": rec.rare}
	return out


func _clue_dict() -> Dictionary:
	var out := {}
	for id: StringName in clues_found:
		out[String(id)] = clues_found[id]
	return out
