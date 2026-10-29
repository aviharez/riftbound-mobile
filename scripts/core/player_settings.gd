class_name PlayerSettings
extends RefCounted
## Per-player preferences (controls, feedback). Persisted to user://settings.cfg.
## Defaults come from CombatBalance so the spec stays the single source of numbers.

const PATH := "user://settings.cfg"
const AIM_ABSOLUTE := &"absolute"
const AIM_RELATIVE := &"relative"

var move_sensitivity: float = 1.3
var aim_mode: StringName = AIM_ABSOLUTE
var aim_sensitivity: float = 0.6
var zone_tolerance: float = 8.0
## Extra bounces shown by the aim line after the first contact (0, 1 or 3).
var aim_preview_bounces: int = 0
var show_touches: bool = false
var screen_shake: bool = true
var damage_numbers: bool = true


static func create(balance: CombatBalance) -> PlayerSettings:
	var s := PlayerSettings.new()
	s.move_sensitivity = balance.move_sensitivity
	s.aim_sensitivity = balance.aim_sensitivity
	s.zone_tolerance = balance.zone_tolerance
	s.load_from_disk()
	return s


func load_from_disk() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	move_sensitivity = float(cfg.get_value("controls", "move_sensitivity", move_sensitivity))
	aim_mode = StringName(str(cfg.get_value("controls", "aim_mode", aim_mode)))
	aim_sensitivity = float(cfg.get_value("controls", "aim_sensitivity", aim_sensitivity))
	zone_tolerance = float(cfg.get_value("controls", "zone_tolerance", zone_tolerance))
	aim_preview_bounces = int(cfg.get_value("controls", "aim_preview_bounces", aim_preview_bounces))
	show_touches = bool(cfg.get_value("debug", "show_touches", show_touches))
	screen_shake = bool(cfg.get_value("feedback", "screen_shake", screen_shake))
	damage_numbers = bool(cfg.get_value("feedback", "damage_numbers", damage_numbers))


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("controls", "move_sensitivity", move_sensitivity)
	cfg.set_value("controls", "aim_mode", String(aim_mode))
	cfg.set_value("controls", "aim_sensitivity", aim_sensitivity)
	cfg.set_value("controls", "zone_tolerance", zone_tolerance)
	cfg.set_value("controls", "aim_preview_bounces", aim_preview_bounces)
	cfg.set_value("debug", "show_touches", show_touches)
	cfg.set_value("feedback", "screen_shake", screen_shake)
	cfg.set_value("feedback", "damage_numbers", damage_numbers)
	var err := cfg.save(PATH)
	if err != OK:
		push_warning("PlayerSettings: could not save (%s)" % error_string(err))
